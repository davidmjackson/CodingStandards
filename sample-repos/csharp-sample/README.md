# csharp-sample

Acceptance test for the C# profile. It is a real consumer of the
`CodeQualityStandards.CSharp` meta-package: one `PackageReference` brings in the
whole standard.

## Layout

| Path | Purpose |
|---|---|
| `src/Calculator.cs` | Clean code. Passes every gate. |
| `src/violations/BadCode.cs` | Deliberately bad code — oversized method, high cyclomatic **and** cognitive complexity, too many parameters, and a duplicated block. Excluded from compilation unless `-p:IncludeViolations=true`. |
| `tests/` | xUnit tests + coverlet coverage gate (80%). |
| `nuget.config` | Points at the local feed the proof script builds. |
| `.jscpd.json` | Duplication config (3% threshold). |
| `prove-gate.sh` | Runs the whole acceptance test. |

## Run it

```bash
./prove-gate.sh
```

It proves, in order:

1. **Gate fails on bad code** — compiling the violations trips `S138` (method
   length), `S1541` (cyclomatic), `S3776` (cognitive), and `S107` (parameters)
   as errors, and jscpd flags the duplicated block above 3%.
2. **Gate passes once corrected** — the clean code builds with zero
   analyzer errors, tests pass at 100% line coverage (≥ 80%), and jscpd finds
   no duplication.

Every rule maps to a threshold in [`/core/THRESHOLDS.md`](../../core/THRESHOLDS.md).
