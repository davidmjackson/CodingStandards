---
name: audit-standards
description: Use when adopting the code quality standard in an EXISTING/legacy repo that has violations - adds the profile as warnings only, then audits and reports without touching code. Fixes happen later, only on explicit instruction, in gated passes. Use scaffold-standards instead for greenfield code.
---

# Audit Standards (legacy retrofit)

Bring an existing codebase onto the standard **without breaking the build** and
**without changing code first**. This skill audits and reports. It fixes only
later, only when told, and only in small gated passes.

> Hard rule: in the audit phase you do **not** modify code. No formatting, no
> refactors, no "quick fixes". Report only.

## 1. Detect the stack

- `*.csproj` / `*.sln` → **C#**
- `package.json` → **JS/TS**
- `pyproject.toml` / `*.py` → **Python**

## 2. Add the profile as warnings only

The severities are the standard's; the difference from greenfield is that they
do **not** fail the build yet.

**C#** — reference the package but switch errors off:

```xml
<PackageReference Include="CodeQualityStandards.CSharp" Version="1.0.0" />
<!-- legacy retrofit: warnings stay warnings -->
<PropertyGroup><CodeQualityWarningsAsErrors>false</CodeQualityWarningsAsErrors></PropertyGroup>
```

**JS/TS** — wire the config, but run ESLint in report mode (do not fail CI on it
yet): collect results, don't gate.

**Python** — wire `ruff.toml`, but treat `ruff check` output as a report, not a
gate.

## 3. Audit and report (no code changes)

Run each stack's linters in reporting mode and produce **one grouped report**:

- **C#:** `dotnet build` (warnings visible, build still succeeds).
- **JS/TS:** `npx eslint . -f json` (or default format), collect.
- **Python:** `ruff check . --output-format=grouped`.
- **Duplication (all):** `npx jscpd . --threshold 100 --reporters json` so it
  reports without failing.

Group the findings **by rule/category**, and for each show the **count** and the
**file paths**:

```
Method length (S138 / max-lines-per-function / PLR0915):  12   src/A.cs, src/B.ts, ...
Cyclomatic complexity (S1541 / complexity / C901):         7   ...
Parameters (S107 / max-params / PLR0913):                  4   ...
Duplication (jscpd):                                    6.2%   src/pay.ts <-> src/refund.ts
Coverage (below 80%):                                     54%
```

Then **stop**. Present the report and wait. Do not proceed to fixes unless the
user explicitly asks.

## 4. Fix in gated passes (only on explicit instruction)

Never combine these passes in one diff.

### Pass A — formatting and safe auto-fixes only

- C#: `dotnet format`
- JS/TS: `npx prettier --write .` and `npx eslint . --fix` (safe fixes only)
- Python: `ruff format .` and `ruff check . --fix` (do **not** use
  `--unsafe-fixes`)

One commit **per project**. Nothing but formatting and mechanically-safe fixes.
Do not hand-edit logic in this pass.

### Pass B — duplication removal and method extraction

Structural work: extract duplicated blocks into shared functions, split
oversized methods, reduce complexity and parameter counts. Keep each diff
**small and reviewable** — one concern per commit. This is judgement work; go
class by class, not repo-wide.

When Pass B for a stack is done, flip that stack to warnings-as-errors (the
greenfield setting) so it stays clean.

## Guardrails

- Do not weaken or delete tests to make a gate pass.
- Do not add analyzer suppressions to hide a violation; if a rule genuinely does
  not apply, justify it in the comment and flag it.
- Do not change thresholds — they come from the standards repo. A genuine misfit
  is an ADR, not a local edit.
