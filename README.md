# Code Quality Standards

One code-quality standard with the same numbers across **C#**, **JS/TS**, and
**Python**, for projects built by directing AI agents. This repository is the source of truth. Consuming projects inherit
from it; they do not define their own rules.

- **Principles and thresholds** are language-neutral and defined once in
  [`core/`](core/).
- **Enforcement** is deterministic — every measurable threshold maps to an
  analyzer rule or check that fails a build. Prose is only for judgement calls
  (SOLID, cohesion, God classes), which live in [`CLAUDE.md`](CLAUDE.md).
- **Adoption** is one dependency reference plus three copied files. Per-repo
  overrides need an ADR.
- **Limits:** the rules approximate each other rather than match exactly; see the
  caveats in `core/THRESHOLDS.md`.

## The thresholds

Defined once in [`core/THRESHOLDS.md`](core/THRESHOLDS.md); every profile
implements the same numbers.

| Rule | Limit |
|---|---|
| Method / function length | 30 lines |
| Cyclomatic complexity | 10 per method |
| Cognitive complexity | 15 per method |
| Parameters | 4 max |
| Class / module length | 400 lines (300 is a review target) |
| Duplication | under 3 percent |
| Test coverage | 80 percent |

## Layout

```
core/                     Language-neutral standard + threshold table (source of truth)
profiles/
  csharp/                 SonarAnalyzer + StyleCop + Roslynator, shipped as a NuGet meta-package
  typescript/             Shared ESLint flat config + Prettier (publishable npm package)
  python/                 ruff.toml + pyproject fragment
hooks/                    One dispatcher (dispatch.sh) + settings.json template + tests
skill/
  scaffold-standards/     Greenfield adoption skill
  audit-standards/        Legacy-retrofit skill (audit first, fix in gated passes)
sample-repos/             One per language; each proves the gate fails then passes
docs/                     Build brief
```

## Consume it in another project

Every project needs **one dependency reference plus three copied files**
(`CLAUDE.md`, `.claude/settings.json`, `hooks/dispatch.sh`) and one gate command
that CI also runs.

### C#

Reference the meta-package (publish it to your feed first — see below):

```xml
<PackageReference Include="CodeQualityStandards.CSharp" Version="1.0.0" />
```

It auto-imports the analyzers, severities, and Sonar parameters on reference
alone. Greenfield keeps `CodeQualityWarningsAsErrors=true`; the legacy path
sets it `false`.

### JS/TS

```bash
mkdir -p vendor
cp <standard-root>/profiles/typescript/codequalitystandards-eslint-config-1.0.1.tgz vendor/eslint-config.tgz
npm install -D file:vendor/eslint-config.tgz eslint@9.39.5 prettier@3.9.10
```

```js
// eslint.config.js
export { default } from '@codequalitystandards/eslint-config';
// prettier.config.mjs
export { default } from '@codequalitystandards/eslint-config/prettier';
```

Add a `verify` script to `package.json` covering lint, format, tests with an 80%
coverage threshold, and jscpd. The Stop hook runs it and rejects a repo without one.

### Python

```toml
# ruff.toml
extend = "<path-to>/profiles/python/ruff.toml"
```

or merge [`profiles/python/pyproject-fragment.toml`](profiles/python/pyproject-fragment.toml).
Take its `[tool.coverage.run]` section either way: without a `source`, modules no test
imports do not count against coverage.

### The three files (all stacks)

1. Copy [`templates/CLAUDE.project.md`](templates/CLAUDE.project.md) to the repo root as
   `CLAUDE.md` and fill it in. It points here; never copy this repo's `CLAUDE.md`.
2. Copy [`hooks/settings.json`](hooks/settings.json) to `.claude/settings.json`.
3. Copy [`hooks/dispatch.sh`](hooks/dispatch.sh) into `hooks/`.

### Run the same gate in CI

Hooks only constrain agent sessions, so CI must run the same command:
`npm run verify` for JS/TS, `hooks/dispatch.sh stop` for Python.

Then use the [`scaffold-standards`](skill/scaffold-standards/SKILL.md) skill for
new code, or [`audit-standards`](skill/audit-standards/SKILL.md) to retrofit an
existing codebase.

## Make it available across all your projects

This repo is designed to be a shared, global dependency:

- **C#** — publish the meta-package to a feed every project can reach
  (nuget.org, GitHub Packages, or Azure Artifacts):
  ```bash
  cd profiles/csharp/nuget
  dotnet pack -c Release -o ./out
  dotnet nuget push out/*.nupkg --source <your-feed> --api-key <key>
  ```
- **JS/TS** — publish the shared config to npm or GitHub Packages:
  ```bash
  cd profiles/typescript && npm publish
  ```
- **Python** — vendor `profiles/python/ruff.toml` (git submodule or a small
  fetch step) and `extend` it, since Ruff configs are referenced by path.
- **Skills** — install them for every project by symlinking into your user
  skills directory:
  ```bash
  ln -s "$PWD/skill/scaffold-standards" ~/.claude/skills/scaffold-standards
  ln -s "$PWD/skill/audit-standards"    ~/.claude/skills/audit-standards
  ```
- **Hooks** — vendor `hooks/dispatch.sh` and the settings template into each
  repo (or a shared location referenced by `$CLAUDE_PROJECT_DIR`).

## Prove the gates fire

Each sample is a real consumer and its own acceptance test — the gate **fails**
on deliberately-bad code and **passes** once corrected:

```bash
sample-repos/csharp-sample/prove-gate.sh      # dotnet 8
sample-repos/python-sample/prove-gate.sh      # python 3.12
sample-repos/typescript-sample/prove-gate.sh  # node 20

hooks/test-dispatch.sh                         # post mode with real tools, across all three
hooks/test-stop-gate.sh                        # fails closed, hermetic, runs in CI
```

See each sample's README for what it proves.

## Definition of Done

A change is complete only when the formatter is clean, analyzers pass with zero
warnings, tests pass, coverage is ≥ 80%, and duplication is < 3%. Do not report
work complete while any gate is red. Details in [`CLAUDE.md`](CLAUDE.md).
