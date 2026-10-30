#!/usr/bin/env bash
#
# Proves the dispatcher fails closed and that its feedback reaches the agent.
# Hermetic: every external tool is a stub on a controlled PATH, so this needs no
# network and no installed toolchain.
#
#     ./test-stop-gate.sh
set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISPATCH="$HOOKS_DIR/dispatch.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FAILED=0

pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAILED=1; }

# A bin directory holding only what the dispatcher needs from the base system.
BASE_BIN="$WORK/base"
mkdir -p "$BASE_BIN"
for tool in bash basename cat dirname env find grep head mktemp python3 realpath tail timeout tr wc; do
  ln -s "$(command -v "$tool")" "$BASE_BIN/$tool"
done

new_project() { mktemp -d "$WORK/project.XXXXXX"; }

# stub <project> <tool> <exit-code>: a fake tool that logs its call and exits.
stub() {
  local bin="$1/.stubs" tool="$2" code="$3"
  mkdir -p "$bin"
  printf '#!%s\necho "%s $*" >> "%s/calls.log"\necho "%s output"\nexit %s\n' \
    "$BASE_BIN/bash" "$tool" "$1" "$tool" "$code" > "$bin/$tool"
  chmod +x "$bin/$tool"
}

# stub_failing_on <project> <tool> <word>: the tool fails when called with that word.
stub_failing_on() {
  mkdir -p "$1/.stubs"
  printf '#!%s\ncase " $* " in *" %s "*) echo "%s output" >&2; exit 1 ;; esac\n' \
    "$BASE_BIN/bash" "$3" "$2" > "$1/.stubs/$2"
  chmod +x "$1/.stubs/$2"
}

# run <project> <mode> [stdin]: runs inside the project, sets STATUS, sets OUTPUT to
# stderr alone, the only stream Claude Code passes to the agent, and sets STDOUT.
# The timeout turns a hang into a failure.
run() {
  local project="$1" mode="$2" input="${3:-}"
  OUTPUT="$(cd "$project" 2>/dev/null; printf '%s' "$input" | CLAUDE_PROJECT_DIR="$project" \
    PATH="$project/.stubs:$BASE_BIN" timeout 10 "$BASE_BIN/bash" "$DISPATCH" "$mode" 2>&1 >"$WORK/stdout")"
  STATUS=$?
  STDOUT="$(cat "$WORK/stdout")"
}

# Claude Code treats exit 2 from Stop as non-blocking when stdout is empty and
# stderr mentions a missing file, reading it as a broken hook command.
expect_blocks_stop() {
  if [ "$STATUS" -eq 2 ] && [ -n "$STDOUT" ]; then pass "$1"; else fail "$1 (exit $STATUS, stdout '$STDOUT')"; fi
}

expect_status() {
  if [ "$STATUS" -eq "$1" ]; then pass "$2"; else fail "$2 (exit $STATUS): $OUTPUT"; fi
}

expect_output() {
  case "$OUTPUT" in
    *"$1"*) pass "$2" ;;
    *) fail "$2: $OUTPUT" ;;
  esac
}

expect_no_output() {
  case "$OUTPUT" in
    *"$1"*) fail "$2: $OUTPUT" ;;
    *) pass "$2" ;;
  esac
}

python_project() {
  local project; project="$(new_project)"
  : > "$project/ruff.toml"
  for tool in ruff coverage pytest npx; do stub "$project" "$tool" 0; done
  echo "$project"
}

echo "== Stop: a green gate is still green =="
p="$(python_project)"; run "$p" stop
expect_status 0 "python project with every tool passing exits 0"
expect_output "Full gate green" "reports green"

echo "== Stop: a missing tool is red, never skipped =="
for tool in ruff coverage npx; do
  p="$(python_project)"; rm "$p/.stubs/$tool"; run "$p" stop
  expect_status 2 "missing $tool blocks"
  expect_output "$tool" "names $tool"
  expect_no_output "Full gate green" "does not claim green without $tool"
done

echo "== Stop: Python tests, coverage and file length are enforced =="
p="$(python_project)"; stub_failing_on "$p" coverage run; run "$p" stop
expect_status 2 "failing tests block"

p="$(python_project)"; rm "$p/.stubs/pytest"; run "$p" stop
grep -q 'unittest discover' "$p/calls.log" && pass "falls back to unittest without pytest" || fail "unittest not run"

p="$(python_project)"; stub_failing_on "$p" coverage report; run "$p" stop
expect_status 2 "coverage under threshold blocks"
expect_output "coverage output" "tool output reaches the agent"

p="$(python_project)"; seq 1 401 > "$p/long.py"; run "$p" stop
expect_status 2 "module over 400 lines blocks"
expect_output "long.py" "names the long module"

p="$(python_project)"; seq 1 400 > "$p/fine.py"; run "$p" stop
expect_status 0 "module of exactly 400 lines passes"

p="$(python_project)"; mkdir -p "$p/.venv/lib"; seq 1 500 > "$p/.venv/lib/dep.py"; run "$p" stop
expect_status 0 "a virtualenv is not measured"

p="$(python_project)"; mkdir -p "$p/.venv/bin"; mv "$p/.stubs/ruff" "$p/.venv/bin/ruff"; run "$p" stop
expect_status 0 "tools in the project .venv are found"

echo "== Stop: JS/TS delegates to the repo's verify command =="
p="$(new_project)"; echo '{"scripts":{"verify":"x"}}' > "$p/package.json"
stub "$p" npm 0; stub "$p" npx 0; run "$p" stop
expect_status 0 "passing verify is green"
grep -q 'npm run' "$p/calls.log" && pass "verify was invoked" || fail "verify was not invoked"
grep -q 'jscpd' "$p/calls.log" && fail "duplication ran twice" || pass "verify owns duplication"

p="$(new_project)"; echo '{"scripts":{"verify":"x"}}' > "$p/package.json"
stub "$p" npm 1; run "$p" stop
expect_status 2 "failing verify blocks"

p="$(new_project)"; echo '{"scripts":{"test":"x"}}' > "$p/package.json"
stub "$p" npm 0; stub "$p" npx 0; run "$p" stop
expect_status 2 "package.json without a verify script blocks"
expect_output "verify" "explains the missing script"

echo "== Stop: C# detection =="
p="$(new_project)"; mkdir -p "$p/src/App/Core"; : > "$p/src/App/Core/App.csproj"
stub "$p" npx 0; run "$p" stop
expect_status 2 "deeply nested csproj without dotnet blocks"
expect_output "dotnet" "names dotnet"

echo "== Stop: a second red gate does not loop =="
p="$(python_project)"; stub "$p" ruff 1
run "$p" stop '{"stop_hook_active":true}'
expect_status 1 "re-entry reports without blocking"
expect_output "ruff output" "still shows the failure"

echo "== Stop: a bad project directory is red =="
run "$WORK/does-not-exist" stop
expect_status 2 "unreachable project blocks"
expect_output "cannot enter" "says why"
expect_blocks_stop "a missing directory still blocks Stop"

echo "== Stop: a tool reporting a missing file still blocks =="
p="$(python_project)"
printf '#!%s\necho "open: No such file or directory" >&2\nexit 1\n' "$BASE_BIN/bash" > "$p/.stubs/ruff"
run "$p" stop
expect_blocks_stop "stderr mentioning a missing file does not unblock Stop"

echo "== Post: feedback reaches the agent =="
p="$(python_project)"; : > "$p/a.py"; stub_failing_on "$p" ruff check
run "$p" post "{\"tool_input\":{\"file_path\":\"$p/a.py\"}}"
expect_status 2 "lint failure exits 2"
expect_output "ruff output" "lint output is on stderr"

p="$(python_project)"; : > "$p/a.py"; stub_failing_on "$p" ruff format
run "$p" post "{\"tool_input\":{\"file_path\":\"$p/a.py\"}}"
expect_status 2 "formatter failure exits 2 when lint would pass"
expect_output "ruff output" "formatter output is on stderr"

p="$(new_project)"; : > "$p/a.ts"; stub_failing_on "$p" npx prettier
run "$p" post "{\"tool_input\":{\"file_path\":\"$p/a.ts\"}}"
expect_status 2 "prettier failure exits 2 when eslint would pass"
expect_output "npx output" "prettier output is on stderr"

p="$(new_project)"; mkdir -p "$p/my app/src"; : > "$p/my app/App.csproj"; : > "$p/my app/src/a.cs"
stub "$p" dotnet 0
run "$p" post '{"tool_input":{"file_path":"my app/src/a.cs"}}'
expect_status 0 "relative path with a space finds its csproj"
grep -q 'dotnet build App.csproj' "$p/calls.log" && pass "builds that project" || fail "csproj not built"

p="$(new_project)"; mkdir "$p/src"; : > "$p/src/a.cs"; stub "$p" dotnet 0
run "$p" post '{"tool_input":{"file_path":"src/a.cs"}}'
expect_status 0 "relative path with no csproj above it terminates"

p="$(python_project)"; : > "$p/a.py"; stub "$p" realpath 1
run "$p" post "{\"tool_input\":{\"file_path\":\"$p/a.py\"}}"
expect_status 2 "a path that cannot be normalised blocks"
expect_output "resolve" "says why"

echo "== Post: unreadable hook input is red =="
p="$(new_project)"; run "$p" post 'not json'
expect_status 2 "malformed JSON blocks"
expect_output "hook input" "says why"

p="$(new_project)"; run "$p" post '{"tool_input":null}'
expect_status 2 "null tool_input blocks"

p="$(new_project)"; rm "$BASE_BIN/python3"; run "$p" post '{}'
expect_status 2 "missing python3 blocks"
ln -s "$(command -v python3)" "$BASE_BIN/python3"

p="$(new_project)"; run "$p" post '{"tool_input":{"command":"ls"}}'
expect_status 0 "an event with no file is ignored"

p="$(python_project)"; : > "$p/a.py"; rm "$p/.stubs/ruff"
run "$p" post "{\"tool_input\":{\"file_path\":\"$p/a.py\"}}"
expect_status 2 "missing ruff blocks"

p="$(python_project)"; : > "$p/a.py"
run "$p" post "{\"tool_input\":{\"file_path\":\"$p/a.py\"}}"
expect_status 0 "clean file exits 0"

p="$(new_project)"; : > "$p/notes.md"
run "$p" post "{\"tool_input\":{\"file_path\":\"$p/notes.md\"}}"
expect_status 0 "unhandled extension is ignored"

echo "== A mistyped mode is red =="
run "$(new_project)" stpo
expect_status 2 "unknown mode blocks"

echo
if [ "$FAILED" -eq 0 ]; then
  echo "==> Stop gate proven: fails closed, feedback reaches the agent."
  exit 0
fi
echo "==> Stop gate test FAILED."
exit 1
