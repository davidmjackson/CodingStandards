---
name: scaffold-standards
description: Use when adopting the code quality standard in a NEW or greenfield repo (or a new project within one) - wires the language profile, copies the CLAUDE.md pointer template and the hook settings, and turns warnings into errors from day one. Not for existing code with violations; use audit-standards for that.
---

# Scaffold Standards (greenfield)

Adopt the standard in a repo that has **no existing violations to migrate**.
Everything blocks from the first build: warnings are errors.

If the repo already has code that will not pass, stop and use
[`audit-standards`](../audit-standards/SKILL.md) instead — it reports before it
touches anything.

## 0. Resolve the standard root (do this first)

Every path in this skill — `profiles/`, `hooks/`, `core/`, `CLAUDE.md` — is
relative to the **standard root**: the checkout of this repository. This skill
file lives at `<standard-root>/skill/scaffold-standards/SKILL.md`, so derive the
root from the skill's own location instead of assuming where the checkout is. A
symlinked skill directory resolves correctly, because `..` applies to the real
directory rather than the link:

```bash
STD=$(readlink -f ~/.claude/skills/scaffold-standards/../..) && echo "$STD"
test -f "$STD/core/THRESHOLDS.md" && echo ok || echo "not the standard root"
```

Use the skill's actual directory if it was loaded from somewhere else (a plugin
cache, a project-level `.claude/skills/`). If the check does not print `ok`, ask
for the checkout path. Never leave a placeholder such as `<path-to>` in a config
file you write, and never guess at the location.

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
mkdir -p vendor
cp "$STD/profiles/typescript/codequalitystandards-eslint-config-1.0.2.tgz" vendor/eslint-config.tgz
npm install -D file:vendor/eslint-config.tgz eslint@9.39.5 prettier@3.9.10
```

Create `eslint.config.js`:

```js
export { default } from '@codequalitystandards/eslint-config';
```

Create `prettier.config.mjs`:

```js
export { default } from '@codequalitystandards/eslint-config/prettier';
```

Add a `verify` script to `package.json`. The Stop gate runs it and is red without
it, so it must cover everything Done requires, including an 80% coverage threshold
in the test tool's config:

```json
"verify": "eslint . && prettier --check . && vitest run --coverage && npx --yes jscpd@4.0.5 . --threshold 3 --gitignore"
```

**Python** — create or extend `ruff.toml`:

```toml
extend = "$STD/profiles/python/ruff.toml"
```

TOML does not expand shell variables: write the **resolved absolute path** from
step 0, not the literal `$STD`. (Or merge
`$STD/profiles/python/pyproject-fragment.toml` into `pyproject.toml`.)

Either way, take its `[tool.coverage.run]` section: without a `source`, modules no
test imports do not count against coverage.

## 3. Copy the three files every consumer needs

1. `$STD/templates/CLAUDE.project.md` → the consuming repo's `CLAUDE.md`. Fill in every
   `{{…}}`: ask for the stop condition and the weight-earning place rather than guessing.
   Never copy `$STD/CLAUDE.md` itself: a copy drifts, and anything in it is inherited.
2. `$STD/hooks/settings.json` → `.claude/settings.json`.
3. `$STD/hooks/dispatch.sh` → `hooks/dispatch.sh` (make it executable).

Then run the same gate in CI: `npm run verify` for JS/TS, `hooks/dispatch.sh stop`
for Python. Hooks only constrain agent sessions.

That is the whole contract: **one dependency reference, three copied files and one
gate command.** Add nothing else. Any per-repo override needs an ADR (see the standard's
Overrides section).

## 4. Confirm warnings-are-errors is on

- C#: `CodeQualityWarningsAsErrors` is unset or `true`.
- JS/TS: profile rules ship as `error`; do not downgrade them.
- Python: the gate fails on any Ruff finding.

## 5. Prove the gate is green

Run the Stop gate once, from the consuming repo, and confirm it passes on the new
code (this is the copy made in step 3, not the one in the standard root):

```bash
./hooks/dispatch.sh stop
```

A missing tool is red, so install it rather than removing the check. If the gate
is red, fix the code — never weaken the standard. Then prove it rejects two
deliberate violations, removing each afterwards: a rule breach, and an untested module
that takes coverage below 80%. A `verify` script can exist without enforcing coverage. Report the result plainly: green, or
which gate is red and why.
