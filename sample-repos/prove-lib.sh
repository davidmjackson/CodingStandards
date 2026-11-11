# Shared helpers for the gate proofs. Source this file, then define gate(): it
# runs the real gate and sets GATE_STATUS and GATE_OUTPUT.

FAILED=0

pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAILED=1; }

# Exits before anything is planted if a path already exists, dangling symlinks
# included, so cleanup can only ever remove what this run created.
refuse_existing() {
  local path
  for path in "$@"; do
    [ -e "$path" ] || [ -L "$path" ] || continue
    echo "Refusing to run: $path already exists and would be overwritten." >&2
    exit 2
  done
}

expect_green() {
  gate
  [ "$GATE_STATUS" -eq 0 ] && { pass "$1"; return; }
  fail "$1"
  printf '%s\n' "$GATE_OUTPUT" | tail -20
}

# expect_red <label> <expected>... [-- <unexpected>...]: the gate fails, and its
# output names every expected diagnostic and none of the unexpected ones.
expect_red() {
  local label="$1" text want=0
  shift
  gate
  [ "$GATE_STATUS" -ne 0 ] || { fail "$label: the gate stayed green"; return; }
  for text in "$@"; do
    [ "$text" = "--" ] && { want=1; continue; }
    grep -qF -- "$text" <<<"$GATE_OUTPUT"
    [ "$?" -eq "$want" ] || { fail "$label: '$text' $([ "$want" -eq 0 ] && echo missing || echo present)"; return; }
  done
  pass "$label"
}

# finish <name>: reports the result and exits with it.
finish() {
  echo
  if [ "$FAILED" -eq 0 ]; then
    echo "==> $1 proven: green, red for the intended reason, green again."
    exit 0
  fi
  echo "==> $1 proof FAILED."
  exit 1
}
