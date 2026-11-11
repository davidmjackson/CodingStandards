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

PY_PLANT="$SAMPLES/python-sample/src/bad_code.py"
TS_PLANT="$SAMPLES/typescript-sample/src/badCode.ts"
TS_FORMAT="$SAMPLES/typescript-sample/src/tempFormat.ts"
CS_PLANT="$SAMPLES/csharp-sample/src/TempBad.cs"
PLANTED=("$PY_PLANT" "$TS_PLANT" "$TS_FORMAT" "$CS_PLANT")

# shellcheck source=../sample-repos/prove-lib.sh
. "$SAMPLES/prove-lib.sh"
refuse_existing "${PLANTED[@]}"
trap 'rm -f "${PLANTED[@]}"' EXIT

# post mode on a single file; returns dispatch.sh's exit code.
post() { "$DISPATCH" post "$1" >/dev/null 2>&1; }

echo "== Python (.py) =="
if command -v ruff >/dev/null 2>&1; then
  if post "$SAMPLES/python-sample/src/calculator.py"; then pass "clean .py passes"; else fail "clean .py rejected"; fi
  if cp "$SAMPLES/fixtures/python/bad_code.py" "$PY_PLANT"; post "$PY_PLANT"; then fail "bad .py passed"; else pass "bad .py rejected (non-zero)"; fi
else
  fail "ruff not on PATH (activate the profile's venv first)"
fi

echo "== TypeScript (.ts) =="
if [ -d "$SAMPLES/typescript-sample/node_modules" ]; then
  if post "$SAMPLES/typescript-sample/src/calculator.ts"; then pass "clean .ts passes"; else fail "clean .ts rejected"; fi
  if cp "$SAMPLES/fixtures/typescript/badCode.ts" "$TS_PLANT"; post "$TS_PLANT"; then fail "bad .ts passed"; else pass "bad .ts rejected (non-zero)"; fi
  printf 'export const value   =   1\n' > "$TS_FORMAT"
  post "$TS_FORMAT"
  if grep -q 'value = 1' "$TS_FORMAT"; then pass "post mode formats the edited file"; else fail "post mode left the file unformatted"; fi
else
  fail "typescript-sample not installed (run its prove-gate.sh first)"
fi

echo "== C# (.cs) =="
CS_SRC="$SAMPLES/csharp-sample/src"
if command -v dotnet >/dev/null 2>&1 && [ -d "$CS_SRC/obj" ]; then
  if post "$CS_SRC/Calculator.cs"; then pass "clean .cs passes"; else fail "clean .cs rejected"; fi
  # Inject a temporary too-many-parameters method so the analyzer trips.
  printf 'namespace Sample;\npublic static class TempBad{public static int M(int a,int b,int c,int d,int e){return a+b+c+d+e;}}\n' > "$CS_PLANT"
  if post "$CS_PLANT"; then fail "bad .cs passed"; else pass "bad .cs rejected (non-zero)"; fi
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
