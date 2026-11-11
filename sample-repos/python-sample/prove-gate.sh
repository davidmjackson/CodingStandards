#!/usr/bin/env bash
#
# Acceptance test for the Python profile.
#
# Runs the sample's real gate, hooks/dispatch.sh stop, through three states:
# green as shipped, red for the intended reason once a violation is planted in
# its inputs, and green again once it is removed.
# Self-contained: it builds a venv and pins its own tools.
#
#     ./prove-gate.sh
set -uo pipefail

SAMPLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SAMPLE_DIR/../../hooks/dispatch.sh"
FIXTURES="$SAMPLE_DIR/../fixtures/python"
FRAGMENT="$SAMPLE_DIR/../../profiles/python/pyproject-fragment.toml"
RUFF_VERSION="0.6.9"
PYTEST_VERSION="9.1.1"
COVERAGE_VERSION="7.15.2"
DUPLICATE_DIR=.venv/qa-duplicate
PLANTED=(src/bad_code.py src/untested.py "$DUPLICATE_DIR/a.py" "$DUPLICATE_DIR/b.py")

# shellcheck source=../prove-lib.sh
. "$SAMPLE_DIR/../prove-lib.sh"

gate() {
  GATE_OUTPUT="$(CLAUDE_PROJECT_DIR="$SAMPLE_DIR" "$GATE" stop </dev/null 2>&1)"
  GATE_STATUS=$?
}

write_untested_module() {
  for i in $(seq 1 50); do echo "x$i = $i"; done > "$1"
}

# The shipped fragment's coverage source must count modules no test imports:
# the report fails on the threshold, then passes once that module is gone.
prove_fragment_counts_untested_modules() {
  local adopter report; adopter="$(mktemp -d)"
  cp "$FRAGMENT" "$adopter/pyproject.toml"
  mkdir "$adopter/tests"
  printf 'VALUE = 1\n' > "$adopter/app.py"
  printf 'import app\n\n\ndef test_value():\n    assert app.VALUE == 1\n' > "$adopter/tests/test_app.py"
  write_untested_module "$adopter/untested.py"
  cd "$adopter" || return
  coverage run -m pytest -q >/dev/null 2>&1 || { fail "the fragment fixture's tests did not pass"; return; }
  report="$(coverage report --fail-under=80 2>&1)"
  grep -q 'less than fail-under=80' <<<"$report" &&
    pass "the shipped fragment counts a module no test imports" ||
    fail "the shipped fragment ignored a module no test imports: $report"
  mv untested.py untested.txt
  coverage run -m pytest -q >/dev/null 2>&1 && coverage report --fail-under=80 >/dev/null 2>&1 &&
    pass "the same project passes once that module is gone" ||
    fail "the fragment fixture failed for a reason other than the module"
  cd "$SAMPLE_DIR" || return
}

cd "$SAMPLE_DIR"
refuse_existing "${PLANTED[@]}" "$DUPLICATE_DIR"
trap 'cd "$SAMPLE_DIR" && rm -f "${PLANTED[@]}" && rmdir "$DUPLICATE_DIR" 2>/dev/null' EXIT

echo "==> Preparing an isolated venv with pinned tools"
python3 -m venv .venv
# shellcheck disable=SC1091
. .venv/bin/activate
pip install -q --upgrade pip
pip install -q "ruff==$RUFF_VERSION" "pytest==$PYTEST_VERSION" "coverage==$COVERAGE_VERSION"

echo
echo "== The real gate: green, red for the intended reason, green again =="
expect_green "the gate is green as shipped"

cp "$FIXTURES/bad_code.py" src/
expect_red "planted violations fail lint and duplication" \
  PLR0915 C901 PLR0913 "Duplication failed"
rm -f src/bad_code.py

write_untested_module src/untested.py
expect_red "an untested module fails on coverage alone" \
  "Python coverage failed" -- "Ruff check failed" "Ruff format failed" "Duplication failed"
rm -f src/untested.py

expect_green "the gate is green again once the violations are removed"

mkdir "$DUPLICATE_DIR"
for i in $(seq 1 60); do echo "value_$i = compute($i, 'same line of text', $i * 2)"; done > "$DUPLICATE_DIR/a.py"
cp "$DUPLICATE_DIR/a.py" "$DUPLICATE_DIR/b.py"
expect_green "the gate ignores a virtualenv's files"

echo
echo "== The shipped profile =="
prove_fragment_counts_untested_modules

deactivate 2>/dev/null || true
finish "Python gate"
