# Hooks

One dispatcher wires the standard into Claude Code. There is deliberately **one**
hook script and **one** settings entry per event — never one hook per language.

## Files

| File | Purpose |
|---|---|
| `dispatch.sh` | The single dispatcher. `post` mode formats + lints the edited file; `stop` mode runs the full gate, on Stop or in CI. |
| `settings.json` | Template for a consuming repo's `.claude/settings.json`. |
| `test-dispatch.sh` | Acceptance test: `post` mode with real tools across `.py`, `.ts`, and `.cs`. |
| `test-stop-gate.sh` | Hermetic test with stubbed tools: the gate fails closed and its output reaches the agent. Runs in CI. |

## How it dispatches

`dispatch.sh post` reads the PostToolUse hook JSON on stdin, takes
`tool_input.file_path`, and branches on extension:

| Extension | Action |
|---|---|
| `.cs` | `dotnet format` + analyzers (build) |
| `.ts` `.tsx` `.js` `.jsx` | Prettier + ESLint |
| `.py` | `ruff format` + `ruff check` |

`dispatch.sh stop` runs the **full gate** across whatever stacks are present:

| Stack | Gate |
|---|---|
| C# | build + analyzers + tests; coverage comes from the project's coverlet threshold |
| JS/TS | `npm run verify`, which owns tests, coverage and duplication; red if the script is missing |
| Python | Ruff check + format, tests under `coverage` (pytest if installed, else unittest), 80% coverage, 400-line modules |
| Without `package.json` | jscpd duplication |

## How it fails

- **Exit 2 on every failure**, with the reason on stderr, which is never empty. It is
  the code whose stderr Claude Code passes to the agent. A formatter failure counts.
  A red Stop also writes to stdout, because exit 2 with empty stdout and a missing-file
  message on stderr does not block.
- **Unreadable hook input is a failure.** An event with no edited file is ignored.
- **A missing required tool is a failure**, never a skip. A project `.venv/bin` is
  added to `PATH` first. A `.cs` file with no `.csproj` above it is left alone.
- **A second red Stop exits 1.** This is an escape hatch: it prevents an endless loop,
  and it lets the agent stop on a red gate, with the failure shown. CI treats both
  codes as failure, so CI is the backstop.
- **`verify` is trusted.** The hook checks that the script exists, not what it
  enforces. Proving a coverage violation goes red is part of adoption.

## Install in a consuming repo

1. Copy `hooks/dispatch.sh` into the repo (or vendor this whole folder).
2. Copy `settings.json` to `.claude/settings.json`.
3. Run the same gate in CI: `npm run verify` for JS/TS, `hooks/dispatch.sh stop` for
   Python.

The dispatcher needs the stack's tools: `dotnet`; `npm` and `npx`; or `ruff`,
`coverage` and `npx`.

## Prove it

```bash
# from the profile's Python venv (so ruff is on PATH), with the samples built:
./test-dispatch.sh

# anywhere, no tools needed:
./test-stop-gate.sh
```
