# Thresholds — Single Source of Truth

These numbers are **the** definition of the standard. They are language-neutral.
Every profile (C#, JS/TS, Python) must implement each row using that language's
tooling and the **same** number. No profile may define a different value, and no
threshold may be defined anywhere else in this repository.

If a number changes, it changes **here first**, and every profile is updated to
match in the same change.

## The table

| ID  | Rule                     | Threshold            | Rationale |
|-----|--------------------------|----------------------|-----------|
| T1  | Method / function length | 30 lines             | A method longer than this is doing more than one thing. |
| T2  | Cyclomatic complexity    | 10 per method        | Independent paths a single method may contain. |
| T3  | Cognitive complexity     | 15 per method        | How hard the method is for a human to follow. |
| T4  | Parameters               | 4 max                | More than four parameters want to be an object. |
| T5  | Class / module length    | 300–400 lines        | Warn at 300, fail at 400. A file past this holds more than one job. |
| T6  | Duplication              | under 3 percent      | Copy-paste is a missing abstraction. |
| T7  | Test coverage            | 80 percent minimum   | Below this, behaviour is unverified. |

### Notes on T5

`300–400` is a band, not two numbers. Profiles configure a **warning at 300**
and a **hard failure at 400** so growth is visible before it becomes a breach.

## Rule mapping per profile

Each threshold maps to a **named, enforced** analyzer rule in every profile. A
rule that only exists as prose does not count.

| ID  | C# (Sonar / analyzers)        | JS/TS (ESLint)                   | Python (Ruff / tools)        |
|-----|-------------------------------|----------------------------------|------------------------------|
| T1  | `S138`                        | `max-lines-per-function`         | `PLR0915` + `pylint`-style   |
| T2  | `S1541` / `CA1502`            | `complexity`                     | `C901` (mccabe)              |
| T3  | `S3776`                       | `sonarjs/cognitive-complexity`   | `C901` (proxy, mccabe)       |
| T4  | `S107`                        | `max-params`                     | `PLR0913`                    |
| T5  | `S1200` (file) / `CA1506`     | `max-lines`                      | file line-count via lint     |
| T6  | Sonar CPD / **jscpd**         | **jscpd**                        | **jscpd**                    |
| T7  | coverlet + threshold gate     | coverage tool threshold          | `coverage`/`pytest --cov`    |

### Cross-language caveats

- **Cognitive vs cyclomatic in Python.** Ruff/mccabe expose *cyclomatic*
  complexity (`C901`). There is no native cognitive-complexity rule in Ruff, so
  `C901` is configured to enforce T2 and acts as the practical proxy for T3.
  This is the one place where a single rule covers two thresholds, and it is
  documented here rather than hidden in the profile.
- **Duplication (T6)** is enforced uniformly with **jscpd** across all three
  languages so one tool and one percentage govern every stack. C# may
  additionally surface duplication through Sonar CPD, but jscpd is the gate.

## Definition of Done (measurable half)

A change is complete only when, for the affected stack:

1. Formatter reports no changes needed.
2. All analyzers pass with zero warnings (greenfield: warnings are errors).
3. All tests pass.
4. Coverage ≥ **80 percent** (T7).
5. Duplication < **3 percent** (T6).

The judgement half of Done lives in [`STANDARD.md`](./STANDARD.md) and in the
root `CLAUDE.md`.
