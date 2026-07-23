#!/usr/bin/env bash
#
# Acceptance test for the C# profile.
#
# Proves the gate FAILS on deliberately-bad code and PASSES once it is
# corrected, exactly as /docs/BUILD-BRIEF.md requires. Run from anywhere:
#
#     ./prove-gate.sh
#
# It packs the profile to a local feed, then drives a real consumer (this
# sample) through the analyzer, coverage, and duplication gates.
set -uo pipefail

SAMPLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SAMPLE_DIR/../.." && pwd)"
PROFILE_NUGET="$REPO_ROOT/profiles/csharp/nuget"
FEED="$REPO_ROOT/sample-repos/.localfeed"
JSCPD="jscpd@4.0.5"

pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAILED=1; }
FAILED=0

echo "==> Packing the C# meta-package to the local feed"
mkdir -p "$FEED"
# Use a relative path: a leading-slash absolute path is read as a switch by the
# Windows-hosted MSBuild under WSL. Relative paths work on every host.
( cd "$PROFILE_NUGET" && dotnet pack CodeQualityStandards.CSharp.csproj -c Release -o "$FEED" >/dev/null 2>&1 ) \
  || { echo "pack failed"; exit 2; }

# Force the freshly-packed package to be re-extracted on restore.
gp="$(dotnet nuget locals global-packages --list 2>/dev/null | sed 's/.*: //' | tr -d '\r')"
case "$gp" in
  [A-Za-z]:*)
    drive="$(echo "${gp:0:1}" | tr 'A-Z' 'a-z')"; rest="${gp:2}"
    gp="/mnt/$drive${rest//\\//}"
    ;;
esac
[ -n "$gp" ] && rm -rf "${gp%/}/codequalitystandards.csharp" 2>/dev/null || true

cd "$SAMPLE_DIR"
echo "==> Restoring the consumer against the local feed"
dotnet restore src/Sample.csproj   --configfile nuget.config --force >/dev/null 2>&1
dotnet restore tests/Sample.Tests.csproj --configfile nuget.config --force >/dev/null 2>&1

echo
echo "== Proving the gate FAILS on bad code =="

# Analyzer gate: compiling the violations must fail on the mapped rules.
viol_log="$(mktemp)"
dotnet build src/Sample.csproj -c Release -p:IncludeViolations=true --no-restore >"$viol_log" 2>&1
if grep -q "Build FAILED" "$viol_log"; then
  fired="$(grep -oE 'error S(138|1541|3776|107)' "$viol_log" | sort -u | tr '\n' ' ')"
  pass "analyzers reject violations (rules: ${fired:-none})"
  for r in S138 S1541 S3776 S107; do
    grep -q "error $r" "$viol_log" || fail "expected rule $r did not fire"
  done
else
  fail "violations build unexpectedly succeeded"
fi

# Duplication gate: the duplicated block must breach 3%.
dup="$(mktemp -d)"; cp src/violations/*.cs "$dup/"
if ( cd "$dup" && npx --yes "$JSCPD" . --threshold 3 --min-lines 5 --min-tokens 50 --reporters console ) >/dev/null 2>&1; then
  fail "jscpd did not flag the duplicated block"
else
  pass "jscpd rejects the duplicated block (>3%)"
fi

echo
echo "== Proving the gate PASSES once corrected =="

# Analyzer gate: the clean code builds with zero warnings-as-errors.
clean_log="$(mktemp)"
if dotnet build src/Sample.csproj -c Release --no-restore >"$clean_log" 2>&1; then
  pass "clean code builds with no analyzer errors"
else
  fail "clean build failed"; grep -E "error" "$clean_log" | head
fi

# Coverage gate: tests pass and coverage stays at/above 80%.
test_log="$(mktemp)"
if dotnet test tests/Sample.Tests.csproj -c Release --no-restore >"$test_log" 2>&1; then
  cov="$(grep -oE '\| Total *\| *[0-9]+%' "$test_log" | grep -oE '[0-9]+%' | head -1)"
  pass "tests pass and coverage gate holds (line coverage ${cov:-?})"
else
  fail "tests or coverage threshold failed"; grep -iE "threshold|failed" "$test_log" | head
fi

# Duplication gate: the corrected tree is under 3%.
if npx --yes "$JSCPD" src >/dev/null 2>&1; then
  pass "jscpd finds no duplication in the clean tree (<3%)"
else
  fail "jscpd reported duplication in the clean tree"
fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "==> C# gate proven: fails on bad code, passes when corrected."
  exit 0
fi
echo "==> C# gate proof FAILED."
exit 1
