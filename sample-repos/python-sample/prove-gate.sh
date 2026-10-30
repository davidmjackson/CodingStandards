#!/usr/bin/env bash
#
# Acceptance test for the Python profile.
#
# Proves the gate FAILS on deliberately-bad code and PASSES once corrected.
# Self-contained: it builds a venv and pins its own tools.
#
#     ./prove-gate.sh
set -uo pipefail

SAMPLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUFF_VERSION="0.6.9"
JSCPD="jscpd@4.0.5"

pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAILED=1; }
FAILED=0

cd "$SAMPLE_DIR"
echo "==> Preparing an isolated venv with pinned tools"
python3 -m venv .venv
# shellcheck disable=SC1091
. .venv/bin/activate
pip install -q --upgrade pip
pip install -q "ruff==$RUFF_VERSION" pytest coverage

echo
echo "== Proving the gate FAILS on bad code =="

# Analyzer gate: the violations must trip the mapped rules.
viol_log="$(mktemp)"
if ruff check violations/ >"$viol_log" 2>&1; then
  fail "ruff unexpectedly accepted the violations"
else
  fired="$(grep -oE '(PLR0915|C901|PLR0913)' "$viol_log" | sort -u | tr '\n' ' ')"
  pass "ruff rejects violations (rules: ${fired:-none})"
  for r in PLR0915 C901 PLR0913; do
    grep -q "$r" "$viol_log" || fail "expected rule $r did not fire"
  done
fi

# Duplication gate: the duplicated block must breach 3%.
dup="$(mktemp -d)"; cp violations/*.py "$dup/"
if ( cd "$dup" && npx --yes "$JSCPD" . --threshold 3 --min-lines 5 --min-tokens 50 --reporters console ) >/dev/null 2>&1; then
  fail "jscpd did not flag the duplicated block"
else
  pass "jscpd rejects the duplicated block (>3%)"
fi

# Coverage gate (T7): a new consumer on the shipped fragment must count modules
# that no test imports.
adopter="$(mktemp -d)"
cp ../../profiles/python/pyproject-fragment.toml "$adopter/pyproject.toml"
mkdir "$adopter/tests"
printf 'VALUE = 1\n' > "$adopter/app.py"
printf 'import app\n\n\ndef test_value():\n    assert app.VALUE == 1\n' > "$adopter/tests/test_app.py"
for i in $(seq 1 50); do echo "x$i = $i"; done > "$adopter/untested.py"
cd "$adopter"
if ! coverage run -m pytest -q >/dev/null 2>&1; then
  fail "the coverage fixture's tests did not pass"
elif coverage report --fail-under=80 >/dev/null 2>&1; then
  fail "coverage ignored a module no test imports"
else
  pass "coverage counts a module no test imports"
fi
mv untested.py untested.txt
if coverage run -m pytest -q >/dev/null 2>&1 && coverage report --fail-under=80 >/dev/null 2>&1; then
  pass "the same project passes once that module is gone"
else
  fail "the coverage fixture failed for a reason other than the module"
fi
cd "$SAMPLE_DIR"

echo
echo "== Proving the gate PASSES once corrected =="

# Analyzer + format gates on clean code.
if ruff check src tests >/dev/null 2>&1; then
  pass "ruff finds no lint issues in clean code"
else
  fail "ruff reported issues in clean code"; ruff check src tests
fi
if ruff format --check src tests >/dev/null 2>&1; then
  pass "ruff format reports no changes needed"
else
  fail "clean code is not formatted"; ruff format --check src tests
fi

# Coverage gate (T7).
cov_log="$(mktemp)"
if coverage run -m pytest -q >"$cov_log" 2>&1 && coverage report --fail-under=80 >>"$cov_log" 2>&1; then
  pct="$(grep -oE 'TOTAL.* [0-9]+%' "$cov_log" | grep -oE '[0-9]+%' | tail -1)"
  pass "tests pass and coverage gate holds (${pct:-?})"
else
  fail "tests or coverage threshold failed"; tail -5 "$cov_log"
fi

# Duplication gate on the clean tree.
if npx --yes "$JSCPD" src tests >/dev/null 2>&1; then
  pass "jscpd finds no duplication in the clean tree (<3%)"
else
  fail "jscpd reported duplication in the clean tree"
fi

deactivate 2>/dev/null || true
echo
if [ "$FAILED" -eq 0 ]; then
  echo "==> Python gate proven: fails on bad code, passes when corrected."
  exit 0
fi
echo "==> Python gate proof FAILED."
exit 1
