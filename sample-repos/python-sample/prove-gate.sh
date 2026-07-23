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
MAX_FILE_LINES=400   # T5

pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAILED=1; }
FAILED=0

# T5 file-length check: any .py over the ceiling fails.
too_long() {
  local root="$1" bad=1
  while IFS= read -r f; do
    [ "$(wc -l < "$f")" -gt "$MAX_FILE_LINES" ] && bad=0
  done < <(find "$root" -name '*.py' -not -path '*/.venv/*' -not -path '*/__pycache__/*')
  return $bad   # 0 = something too long
}

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

# File-length gate (T5): a synthetic oversized module must be flagged.
big="$(mktemp -d)"; { echo '"""oversized"""'; for i in $(seq 1 "$((MAX_FILE_LINES + 1))"); do echo "x$i = $i"; done; } > "$big/oversized.py"
if too_long "$big"; then
  pass "file-length check flags a module over $MAX_FILE_LINES lines"
else
  fail "file-length check missed an oversized module"
fi

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

# File-length gate on the real tree.
if too_long src tests; then
  fail "a real module exceeds $MAX_FILE_LINES lines"
else
  pass "all modules are within $MAX_FILE_LINES lines"
fi

deactivate 2>/dev/null || true
echo
if [ "$FAILED" -eq 0 ]; then
  echo "==> Python gate proven: fails on bad code, passes when corrected."
  exit 0
fi
echo "==> Python gate proof FAILED."
exit 1
