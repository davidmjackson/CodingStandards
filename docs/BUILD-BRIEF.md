# Build Brief: code-quality-standards

Instructions for Claude Code CLI. Read this fully before writing anything.

## What you are building

A standalone, reusable repository that defines and enforces one code-quality
standard across three stacks: C#, JS/TS, and Python.

The repo is the source of truth. Consuming projects inherit from it. They do not
define their own rules.

## Non-negotiable design principles

1. **One core standard, three enforcement profiles.** The principles and
   thresholds are language-neutral and defined once in `/core`. Each profile in
   `/profiles` implements those same thresholds using that language's tooling.
   Never define a different threshold per language.

2. **Enforcement is deterministic, not advisory.** A rule that only exists as
   prose in a markdown file does not count as enforced. Every measurable
   threshold must map to an analyzer rule that fails a build or a check.

3. **Prose is for judgement calls only.** Design guidance (SOLID, cohesion, God
   classes) lives in CLAUDE.md because no analyzer can measure it. Everything
   measurable lives in config.

4. **Per-repo overrides are forbidden by default.** A consuming repo references
   its profile and adds nothing. Any override requires a written ADR.

## Repository structure

Create exactly this:

```
code-quality-standards/
  /core/
    STANDARD.md            # language-neutral principles, thresholds, DoD
    THRESHOLDS.md          # the threshold table, single source of truth
  /profiles/
    /csharp/
      Directory.Build.props
      quality.globalconfig
      /nuget/              # meta-package: .props/.targets + analyzer deps
    /typescript/
      eslint.config.js     # shared flat config
      .prettierrc
      package.json         # publishable shared config package
    /python/
      ruff.toml
      pyproject-fragment.toml
  /skill/
    /scaffold-standards/
      SKILL.md
    /audit-standards/
      SKILL.md
  /hooks/
    dispatch.sh            # single file-extension dispatcher
    settings.json          # .claude/settings.json template
  /sample-repos/
    /csharp-sample/
    /typescript-sample/
    /python-sample/
  CLAUDE.md
  README.md
```

## Thresholds to encode

These are the same in all three profiles. Encode them in `/core/THRESHOLDS.md`
first, then implement each one in every profile.

| Rule | Threshold |
|---|---|
| Method length | 30 lines |
| Cyclomatic complexity | 10 per method |
| Cognitive complexity | 15 per method |
| Parameters | 4 max |
| Class / module length | 300 to 400 lines |
| Duplication | under 3 percent |
| Test coverage | 80 percent |

### Rule mapping per profile

Implement each threshold with these specific analyzer rules.

| Threshold | C# | JS/TS | Python |
|---|---|---|---|
| Method length | Sonar S138 | `max-lines-per-function` | Ruff / pylint |
| Cognitive complexity | Sonar S3776 | `sonarjs/cognitive-complexity` | Ruff `C901` |
| Parameters | Sonar S107 | `max-params` | Ruff `PLR0913` |
| Duplication | Sonar CPD | jscpd | jscpd |

## Profile requirements

### C#
- Meta-package that pulls in SonarAnalyzer.CSharp, StyleCop.Analyzers,
  Roslynator, and sets the .NET SDK analyzers.
- Ship severities as a `.globalconfig`, not `.editorconfig`. Only
  `.globalconfig` travels inside a NuGet package.
- Include a `build/*.props` in the package so consumers inherit settings on
  reference alone.
- Set `AnalysisLevel` to `latest-Recommended`.
- `TreatWarningsAsErrors` must be **true for greenfield** and **false for the
  legacy retrofit path**. Make this a switchable property, not a hardcoded value.

### JS/TS
- Publishable shared ESLint flat config plus Prettier config.
- Include `eslint-plugin-sonarjs` so complexity rules match the C# concepts.

### Python
- Ruff config covering lint, import sorting, complexity, and formatting.
- Provide it as a `ruff.toml` plus a `pyproject.toml` fragment consumers can
  merge.

## Hooks

Write **one** hook entry, not three.

- `.claude/settings.json` uses a `PostToolUse` hook matching `Write|Edit|MultiEdit`
  and a `Stop` hook.
- Both call `hooks/dispatch.sh`.
- `dispatch.sh` branches on file extension: `.cs` runs dotnet format plus
  analyzers, `.ts`/`.js`/`.tsx`/`.jsx` runs Prettier plus ESLint, `.py` runs Ruff.
- The `Stop` hook runs the **full gate**: build, analyzers, tests, duplication
  check. It must fail loudly if anything is red.
- The dispatcher must exit non-zero on violations so feedback reaches the agent.

## Skills

Build two, kept deliberately separate.

**`scaffold-standards`** (greenfield)
- Adds the profile dependency for the detected stack.
- Copies in CLAUDE.md and `.claude/settings.json`.
- Sets warnings-as-errors to true.

**`audit-standards`** (legacy retrofit)
- Adds the profile with severities as **warnings only**.
- Runs an **audit and reports**. It must not modify code in this phase.
- Output: violations grouped by category, with counts and file paths.
- Only after the report, and only on explicit instruction, proceeds to fixes in
  gated passes:
  - **Pass A**: formatting and safe auto-fixes only, one commit per project.
  - **Pass B**: duplication removal and method extraction, small reviewable diffs.
- Never combine Pass A and Pass B in one diff.

## Sample repos

One per language. Each must contain **deliberately bad code**: a duplicated
block, an oversized method, a high-complexity function, and a method with too
many parameters.

**These are the acceptance tests.** The build is not done until you have proven,
for each language:
- The gate **fails** on the sample repo's bad code.
- The gate **passes** once that code is corrected.

Do not report the work complete on the basis of config existing. Prove the gates
fire.

## Build order

Work in this sequence and stop for review between phases.

1. `/core/THRESHOLDS.md` and `/core/STANDARD.md`.
2. C# profile plus `csharp-sample`. Prove the gate fails then passes.
3. Python profile plus `python-sample`. Prove the gate fails then passes.
4. JS/TS profile plus `typescript-sample`. Prove the gate fails then passes.
5. Hook dispatcher, tested against all three samples.
6. The two skills.
7. README with consumption instructions.

## Definition of Done

- Every threshold in `/core/THRESHOLDS.md` has a named analyzer rule in all three
  profiles.
- Each sample repo demonstrably fails then passes its gate.
- The hook dispatcher handles all three extensions and exits non-zero on failure.
- A consuming project needs one dependency reference plus two copied files, and
  nothing else.
- No threshold is defined in more than one place.
