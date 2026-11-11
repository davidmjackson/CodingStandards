#!/usr/bin/env bash
#
# Acceptance test for the JS/TS profile.
#
# Runs the sample's real gate, `npm run verify`, through three states: green as
# shipped, red for the intended reason once a violation is planted in its
# inputs, and green again once it is removed. The shared config is packed from
# source and installed against the tracked lockfile, as a consumer would.
#
#     ./prove-gate.sh
set -uo pipefail

SAMPLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="$SAMPLE_DIR/../../profiles/typescript"
FIXTURES="$SAMPLE_DIR/../fixtures/typescript"

PLANTED=(src/badCode.ts src/undefinedName.js src/untested.js tests/copy.test.ts)

# shellcheck source=../prove-lib.sh
. "$SAMPLE_DIR/../prove-lib.sh"

gate() {
  GATE_OUTPUT="$(npm run --silent verify 2>&1)"
  GATE_STATUS=$?
}

# Four small functions no test calls: lint-clean, formatted, not duplicated.
write_untested_module() {
  local name separator=''
  for name in double:2 triple:3 quadruple:4 quintuple:5; do
    printf '%sexport function %s(value) {\n  return value * %s;\n}\n' \
      "$separator" "${name%%:*}" "${name##*:}"
    separator=$'\n'
  done > src/untested.js
}

cd "$SAMPLE_DIR"
refuse_existing "${PLANTED[@]}"
trap 'cd "$SAMPLE_DIR" && rm -f "${PLANTED[@]}"' EXIT

echo "==> Packing the shared config and installing from the lockfile"
mkdir -p vendor
( cd "$PROFILE" && npm pack --pack-destination "$SAMPLE_DIR/vendor" >/dev/null 2>&1 )
mv -f vendor/codequalitystandards-eslint-config-*.tgz vendor/eslint-config.tgz
# npm ci checks the tarball against the lockfile's integrity hash, so a changed
# profile fails here until the lockfile is refreshed with npm install.
npm ci --no-audit --no-fund >/dev/null 2>&1 || { echo "npm ci failed: is package-lock.json current?"; exit 2; }

echo
echo "== The real gate: green, red for the intended reason, green again =="
expect_green "the gate is green as shipped"

cp "$FIXTURES/badCode.ts" src/
expect_red "planted violations fail lint" \
  max-lines-per-function complexity sonarjs/cognitive-complexity max-params
rm -f src/badCode.ts

cp "$FIXTURES/undefinedName.js" src/
expect_red "a misspelled name in plain JavaScript fails lint" "'amout' is not defined"
rm -f src/undefinedName.js

write_untested_module
expect_red "an untested JavaScript module fails on coverage" "does not meet global threshold (80%)"
rm -f src/untested.js

# A copied test passes lint, format, tests and coverage, so only jscpd can fail.
cp tests/calculator.test.ts tests/copy.test.ts
expect_red "a duplicated file fails on duplication" "too many duplicates"
rm -f tests/copy.test.ts

expect_green "the gate is green again once the violations are removed"

finish "JS/TS gate"
