# The Standard

One code-quality standard, enforced identically across C#, JS/TS, and Python.
This document holds the language-neutral principles. The numbers live in
[`THRESHOLDS.md`](./THRESHOLDS.md) and are not repeated here.

## Design principles

1. **One core standard, three enforcement profiles.** Principles and thresholds
   are defined once, here and in `THRESHOLDS.md`. Each profile under
   `/profiles` implements those same thresholds using its language's tooling.
   A threshold is never redefined per language.

2. **Enforcement is deterministic, not advisory.** A rule that exists only as
   prose does not count as enforced. Every measurable threshold maps to an
   analyzer rule that fails a build or a check.

3. **Prose is for judgement calls only.** Design guidance that no analyzer can
   measure (SOLID, cohesion, God classes) lives in `CLAUDE.md`. Everything
   measurable lives in config.

4. **Per-repo overrides are forbidden by default.** A consuming repo references
   its profile and adds nothing. Any override requires a written ADR.

## What is enforced by tooling

The measurable thresholds — method length, cyclomatic and cognitive complexity,
parameter count, class/module length, duplication, and coverage — are enforced
by the analyzers configured in each profile. See `THRESHOLDS.md` for the numbers
and the per-language rule mapping. These are not checked by review; they are
checked by the build.

## What is enforced by judgement

Analyzers cannot measure design. These are applied by the author and expected at
review:

- **Single responsibility.** One reason to change per class.
- **Dependency direction.** Depend on abstractions, not concretions, at module
  boundaries.
- **Cohesion.** A class's methods should use its own state. A method that
  ignores it belongs elsewhere.
- **No God classes.** A class everything depends on is a design failure.
- **Naming carries intent.** Reveal purpose. Avoid `Manager`, `Helper`,
  `Processor`, `Data`.
- **Error handling.** No empty catch blocks. Catch specific types. Validate at
  the boundary and fail fast.
- **Tests.** New behaviour needs new tests; fixed bugs need a regression test.
  One assertion concept per test. Never weaken a test to make a build pass.

## Two paths onto the standard

The same standard is adopted two ways. The thresholds are identical; only the
severity and the migration approach differ.

- **Greenfield (`scaffold-standards`).** New code adopts the standard with
  `TreatWarningsAsErrors = true`. Violations block from day one.
- **Legacy retrofit (`audit-standards`).** Existing code adopts the standard
  with severities as **warnings**, is **audited and reported** first, and is
  fixed only in gated passes (formatting/safe fixes, then duplication and
  extraction) — never both in one diff.

Warnings-as-errors is therefore a **switchable property**, not a hardcoded
value.

## Consuming this standard

A consuming project needs exactly:

1. One dependency reference to its profile (NuGet meta-package, npm shared
   config, or `ruff.toml`/`pyproject` fragment).
2. Two copied files: `CLAUDE.md` and `.claude/settings.json`.

Nothing else. If a project needs more than that, the standard has a gap — fix it
here, not in the consumer.
