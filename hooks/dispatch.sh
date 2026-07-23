#!/usr/bin/env bash
#
# Single quality-gate dispatcher for Claude Code hooks.
#
#   dispatch.sh post   # PostToolUse: format + lint the one edited file
#   dispatch.sh stop   # Stop: run the full gate over the whole repo
#
# post mode reads the hook JSON on stdin (or takes a path as $2 for testing)
# and branches on the file extension:
#   .cs                    -> dotnet format + analyzers (build)
#   .ts .tsx .js .jsx      -> Prettier + ESLint
#   .py                    -> Ruff format + Ruff check
#
# It exits non-zero on any violation so the feedback reaches the agent.
# One dispatcher, one settings entry - never one hook per language.
set -uo pipefail

MODE="${1:-post}"
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

log()  { printf '[quality] %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# Walk up from $1 looking for the first directory that contains a match of $2.
find_up() {
  local dir="$1" pattern="$2"
  while [ "$dir" != "/" ] && [ -n "$dir" ]; do
    # shellcheck disable=SC2086
    if compgen -G "$dir/"$pattern >/dev/null 2>&1; then echo "$dir"; return 0; fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# ---- per-file linters (post mode) -----------------------------------------

lint_csharp() {
  local file="$1" projdir
  have dotnet || { log "dotnet not found; skipping $file"; return 0; }
  projdir="$(find_up "$(dirname "$file")" '*.csproj')" || { log "no .csproj above $file"; return 0; }
  local proj rel
  proj="$(basename "$(compgen -G "$projdir/"'*.csproj' | head -1)")"
  rel="$(realpath --relative-to="$projdir" "$file")"
  # Relative paths only: a leading-slash absolute path is read as an MSBuild switch.
  ( cd "$projdir" && dotnet format "$proj" --include "$rel" >/dev/null 2>&1 || true
    dotnet build "$proj" -clp:ErrorsOnly >/dev/null 2>&1 )
}

lint_js() {
  local file="$1" dir; dir="$(dirname "$file")"
  have npx || { log "npx not found; skipping $file"; return 0; }
  npx prettier --write "$file" >/dev/null 2>&1 || true
  ( cd "$dir" && npx eslint "$file" )
}

lint_python() {
  local file="$1"
  have ruff || { log "ruff not found; skipping $file"; return 0; }
  ruff format "$file" >/dev/null 2>&1 || true
  ruff check "$file"
}

run_post() {
  local file="${1:-}"
  if [ -z "$file" ]; then
    file="$(python3 -c 'import sys,json
try:
    d=json.load(sys.stdin)
except Exception:
    d={}
print(d.get("tool_input",{}).get("file_path",""))' 2>/dev/null)"
  fi
  [ -n "$file" ] && [ -f "$file" ] || exit 0
  case "$file" in
    *.cs)                 lint_csharp "$file" ;;
    *.ts|*.tsx|*.js|*.jsx) lint_js "$file" ;;
    *.py)                 lint_python "$file" ;;
    *) exit 0 ;;
  esac
}

# ---- full gate (stop mode) -------------------------------------------------

run_full_gate() {
  local failed=0
  cd "$ROOT" || exit 0

  if compgen -G "**/*.csproj" >/dev/null 2>&1 || compgen -G "*.sln" >/dev/null 2>&1; then
    log "C#: build (analyzers) + test"
    dotnet build -clp:ErrorsOnly >/dev/null 2>&1 || { log "C# build/analyzers failed"; failed=1; }
    dotnet test  --no-build >/dev/null 2>&1 || { log "C# tests/coverage failed"; failed=1; }
  fi

  if [ -f package.json ]; then
    log "JS/TS: eslint + prettier + tests"
    have npx && { npx eslint . >/dev/null 2>&1 || { log "ESLint failed"; failed=1; }; }
    have npx && { npx prettier --check . >/dev/null 2>&1 || { log "Prettier failed"; failed=1; }; }
    grep -q '"test"' package.json && { npm test --silent >/dev/null 2>&1 || { log "JS tests failed"; failed=1; }; }
  fi

  if [ -f ruff.toml ] || [ -f pyproject.toml ]; then
    log "Python: ruff + coverage"
    have ruff && { ruff check . >/dev/null 2>&1 || { log "Ruff check failed"; failed=1; }; }
    have ruff && { ruff format --check . >/dev/null 2>&1 || { log "Ruff format failed"; failed=1; }; }
  fi

  log "Duplication: jscpd"
  have npx && { npx --yes jscpd@4.0.5 . --threshold 3 --gitignore >/dev/null 2>&1 || { log "Duplication over 3%"; failed=1; }; }

  if [ "$failed" -ne 0 ]; then
    log "FULL GATE RED - fix the above before proceeding."
    exit 2
  fi
  log "Full gate green."
}

case "$MODE" in
  stop) run_full_gate ;;
  post) shift || true; run_post "${1:-}" ;;
  *) log "unknown mode: $MODE"; exit 0 ;;
esac
