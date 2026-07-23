#!/usr/bin/env bash
#
# Acceptance test for the JS/TS profile.
#
# Proves the gate FAILS on deliberately-bad code and PASSES once corrected.
# The shared ESLint/Prettier config is consumed as a packed tarball, exactly as
# a published package would be installed.
#
#     ./prove-gate.sh
set -uo pipefail

SAMPLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SAMPLE_DIR/../.." && pwd)"
PROFILE="$REPO_ROOT/profiles/typescript"
JSCPD="jscpd@4.0.5"

pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAILED=1; }
FAILED=0

cd "$SAMPLE_DIR"
echo "==> Packing the shared config and installing dependencies"
mkdir -p vendor
( cd "$PROFILE" && npm pack --pack-destination "$SAMPLE_DIR/vendor" >/dev/null 2>&1 )
mv -f vendor/codequalitystandards-eslint-config-*.tgz vendor/eslint-config.tgz
npm install --no-audit --no-fund >/dev/null 2>&1 || { echo "npm install failed"; exit 2; }

echo
echo "== Proving the gate FAILS on bad code =="

# Lint gate: the violations must trip the mapped rules.
viol_log="$(mktemp)"
if npx eslint src/violations >"$viol_log" 2>&1; then
  fail "eslint unexpectedly accepted the violations"
else
  fired="$(grep -oE '(max-lines-per-function|complexity|sonarjs/cognitive-complexity|max-params)' "$viol_log" | sort -u | tr '\n' ' ')"
  pass "eslint rejects violations (rules: ${fired:-none})"
  for r in max-lines-per-function complexity sonarjs/cognitive-complexity max-params; do
    grep -q "$r" "$viol_log" || fail "expected rule $r did not fire"
  done
fi

# Duplication gate.
dup="$(mktemp -d)"; cp src/violations/*.ts "$dup/"
if ( cd "$dup" && npx --yes "$JSCPD" . --threshold 3 --min-lines 5 --min-tokens 50 --reporters console ) >/dev/null 2>&1; then
  fail "jscpd did not flag the duplicated block"
else
  pass "jscpd rejects the duplicated block (>3%)"
fi

echo
echo "== Proving the gate PASSES once corrected =="

if npx eslint src/calculator.ts tests >/dev/null 2>&1; then
  pass "eslint finds no issues in clean code"
else
  fail "eslint reported issues in clean code"; npx eslint src/calculator.ts tests
fi

if npx prettier --check src/calculator.ts tests >/dev/null 2>&1; then
  pass "prettier reports no changes needed"
else
  fail "clean code is not formatted"
fi

test_log="$(mktemp)"
if npx vitest run --coverage >"$test_log" 2>&1; then
  pct="$(grep -oE 'All files[^|]*\| *[0-9.]+' "$test_log" | grep -oE '[0-9.]+$' | head -1)"
  pass "tests pass and coverage gate holds (statements ${pct:-?}%)"
else
  fail "tests or coverage threshold failed"; grep -iE "threshold|ERROR" "$test_log" | head
fi

if npx --yes "$JSCPD" src tests >/dev/null 2>&1; then
  pass "jscpd finds no duplication in the clean tree (<3%)"
else
  fail "jscpd reported duplication in the clean tree"
fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "==> JS/TS gate proven: fails on bad code, passes when corrected."
  exit 0
fi
echo "==> JS/TS gate proof FAILED."
exit 1
