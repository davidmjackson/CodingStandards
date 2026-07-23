# Hooks

One dispatcher wires the standard into Claude Code. There is deliberately **one**
hook script and **one** settings entry per event — never one hook per language.

## Files

| File | Purpose |
|---|---|
| `dispatch.sh` | The single dispatcher. `post` mode formats + lints the edited file; `stop` mode runs the full gate. |
| `settings.json` | Template for a consuming repo's `.claude/settings.json`. |
| `test-dispatch.sh` | Acceptance test: proves the dispatcher handles `.py`, `.ts`, and `.cs` and exits non-zero on a violation. |

## How it dispatches

`dispatch.sh post` reads the PostToolUse hook JSON on stdin, takes
`tool_input.file_path`, and branches on extension:

| Extension | Action |
|---|---|
| `.cs` | `dotnet format` + analyzers (build) |
| `.ts` `.tsx` `.js` `.jsx` | Prettier + ESLint |
| `.py` | `ruff format` + `ruff check` |

`dispatch.sh stop` runs the **full gate** across whatever stacks are present —
build + analyzers + tests for C#, ESLint/Prettier/tests for JS/TS, Ruff for
Python, and jscpd duplication for all — and exits non-zero (loudly) if anything
is red.

## Install in a consuming repo

1. Copy `hooks/dispatch.sh` into the repo (or vendor this whole folder).
2. Copy `settings.json` to `.claude/settings.json`.

The dispatcher expects the stack's tools on `PATH` (`dotnet`, `npx`, `ruff`) —
the same tools the profile already requires.

## Prove it

```bash
# from the profile's Python venv (so ruff is on PATH), with the samples built:
./test-dispatch.sh
```
