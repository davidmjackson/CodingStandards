---
name: scaffold-standards
description: Use when adopting the code quality standard in a NEW or greenfield repo (or a new project within one) - wires the language profile, copies CLAUDE.md and the hook settings, and turns warnings into errors from day one. Not for existing code with violations; use audit-standards for that.
---

# Scaffold Standards (greenfield)

Adopt the standard in a repo that has **no existing violations to migrate**.
Everything blocks from the first build: warnings are errors.

If the repo already has code that will not pass, stop and use
[`audit-standards`](../audit-standards/SKILL.md) instead — it reports before it
touches anything.

## 1. Detect the stack

Look at the repo:

- `*.csproj` / `*.sln` → **C#**
- `package.json` (with `.ts`/`.js`) → **JS/TS**
- `pyproject.toml` / `*.py` → **Python**

A repo may have more than one. Wire each stack it contains.

## 2. Add the profile dependency (one reference)

**C#** — add to the project (or `Directory.Packages.props`):

```xml
<PackageReference Include="CodeQualityStandards.CSharp" Version="1.0.0" />
```

Greenfield keeps the default `CodeQualityWarningsAsErrors=true`; do **not** set
it to false.

**JS/TS**

```bash
npm install -D @codequalitystandards/eslint-config eslint prettier
```

Create `eslint.config.js`:

```js
export { default } from '@codequalitystandards/eslint-config';
```

Create `prettier.config.mjs`:

```js
export { default } from '@codequalitystandards/eslint-config/prettier';
```

**Python** — create or extend `ruff.toml`:

```toml
extend = "<path-to>/profiles/python/ruff.toml"
```

(or merge `profiles/python/pyproject-fragment.toml` into `pyproject.toml`).

## 3. Copy the two files every consumer needs

1. `CLAUDE.md` → repo root.
2. `hooks/settings.json` → `.claude/settings.json`, and `hooks/dispatch.sh` →
   `hooks/dispatch.sh` (make it executable).

That is the whole contract: **one dependency reference plus two copied files.**
Add nothing else. Any per-repo override needs an ADR (see the standard's
Overrides section).

## 4. Confirm warnings-are-errors is on

- C#: `CodeQualityWarningsAsErrors` is unset or `true`.
- JS/TS: profile rules ship as `error`; do not downgrade them.
- Python: the gate fails on any Ruff finding.

## 5. Prove the gate is green

Run the Stop gate once and confirm it passes on the new code:

```bash
./hooks/dispatch.sh stop
```

If it is red, fix the code — never weaken the standard. Report the result
plainly: green, or which gate is red and why.
