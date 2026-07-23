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
| T5  | Class / module length    | 400 lines (hard)     | Analyzer fails at 400. 300 is a review target (judgement, not gated). |
| T6  | Duplication              | under 3 percent      | Copy-paste is a missing abstraction. |
| T7  | Test coverage            | 80 percent minimum   | Below this, behaviour is unverified. |

### Notes on T5

The brief states the limit as a `300–400` band. Only one number can be a
deterministic analyzer gate, so the **enforced ceiling is 400** (Principle 2:
enforcement must be measurable). **300** remains the soft target flagged at
review under the judgement rules — it is deliberately *not* a second config
value, so no threshold is defined twice.

## Rule mapping per profile

Each threshold maps to a **named, enforced** analyzer rule in every profile. A
rule that only exists as prose does not count.

| ID  | C# (Sonar / analyzers)        | JS/TS (ESLint)                   | Python (Ruff / tools)        |
|-----|-------------------------------|----------------------------------|------------------------------|
| T1  | `S138` (`max`=30)             | `max-lines-per-function`         | `PLR0915` (`max-statements`=30) |
| T2  | `S1541` (=10)                 | `complexity`                     | `C901` (`max-complexity`=10) |
| T3  | `S3776` (`threshold`=15)      | `sonarjs/cognitive-complexity`   | `C901` (proxy, mccabe)       |
| T4  | `S107` (`max`=4)              | `max-params`                     | `PLR0913` (`max-args`=4)     |
| T5  | `S104` (`maximumFileLocThreshold`=400) | `max-lines`             | gate check (see caveat)      |
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
- **File length (T5) in Python.** Ruff has no module-length rule (no C0302
  equivalent). Principle 2 permits "a build **or a check**", so the Python
  profile enforces T5 with a deterministic line-count check in the gate rather
  than a lint rule. C# (`S104`) and JS/TS (`max-lines`) use native rules.

A threshold is enforced when it "fails a build or a check". Most rows above are
named analyzer rules; T5 for Python is the one deterministic check. No
threshold is enforced in more than one place.

## Definition of Done (measurable half)

A change is complete only when, for the affected stack:

1. Formatter reports no changes needed.
2. All analyzers pass with zero warnings (greenfield: warnings are errors).
3. All tests pass.
4. Coverage ≥ **80 percent** (T7).
5. Duplication < **3 percent** (T6).

The judgement half of Done lives in [`STANDARD.md`](./STANDARD.md) and in the
root `CLAUDE.md`.
