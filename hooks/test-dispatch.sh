#!/usr/bin/env bash
#
# Proves the hook dispatcher handles all three extensions and exits non-zero on
# a violation, zero on clean code - the Phase 5 acceptance test.
#
#     ./test-dispatch.sh
set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HOOKS_DIR/.." && pwd)"
DISPATCH="$HOOKS_DIR/dispatch.sh"
SAMPLES="$REPO_ROOT/sample-repos"

pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAILED=1; }
FAILED=0

# post mode on a single file; returns dispatch.sh's exit code.
post() { "$DISPATCH" post "$1" >/dev/null 2>&1; }

echo "== Python (.py) =="
if command -v ruff >/dev/null 2>&1; then
  if post "$SAMPLES/python-sample/src/calculator.py"; then pass "clean .py passes"; else fail "clean .py rejected"; fi
  if post "$SAMPLES/python-sample/violations/bad_code.py"; then fail "bad .py passed"; else pass "bad .py rejected (non-zero)"; fi
else
  fail "ruff not on PATH (activate the profile's venv first)"
fi

echo "== TypeScript (.ts) =="
if [ -d "$SAMPLES/typescript-sample/node_modules" ]; then
  if post "$SAMPLES/typescript-sample/src/calculator.ts"; then pass "clean .ts passes"; else fail "clean .ts rejected"; fi
  if post "$SAMPLES/typescript-sample/src/violations/badCode.ts"; then fail "bad .ts passed"; else pass "bad .ts rejected (non-zero)"; fi
  tmp="$SAMPLES/typescript-sample/src/tempFormat.ts"
  printf 'export const value   =   1\n' > "$tmp"
  post "$tmp"
  if grep -q 'value = 1' "$tmp"; then pass "post mode formats the edited file"; else fail "post mode left the file unformatted"; fi
  rm -f "$tmp"
else
  fail "typescript-sample not installed (run its prove-gate.sh first)"
fi

echo "== C# (.cs) =="
CS_SRC="$SAMPLES/csharp-sample/src"
if command -v dotnet >/dev/null 2>&1 && [ -d "$CS_SRC/obj" ]; then
  if post "$CS_SRC/Calculator.cs"; then pass "clean .cs passes"; else fail "clean .cs rejected"; fi
  # Inject a temporary too-many-parameters method so the analyzer trips.
  tmp="$CS_SRC/TempBad.cs"
  printf 'namespace Sample;\npublic static class TempBad{public static int M(int a,int b,int c,int d,int e){return a+b+c+d+e;}}\n' > "$tmp"
  if post "$tmp"; then fail "bad .cs passed"; else pass "bad .cs rejected (non-zero)"; fi
  rm -f "$tmp"
else
  fail "csharp-sample not restored (run its prove-gate.sh first)"
fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "==> Dispatcher proven across .py, .ts, and .cs."
  exit 0
fi
echo "==> Dispatcher test FAILED."
exit 1
