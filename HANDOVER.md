# Handover

Current position only. Prune when an item closes.

## Consumers

AI-TagTeam, crm-reporting2 and leadgen-sprint-report run the fail-closed dispatcher from
`b08bd20`, merged 2026-11-11 with a stage review each. Each holds a copy, so a dispatcher
fix here needs copying out again.

## Open: observe outcomes before wider adoption

**David's ruling, 2026-11-11:** observe first. No new repo adopts the standard until the
next few real changes in the three consumers have been watched for review effort, rework
and gate-induced churn. This restores the 2026-10-30 agreement and holds the scrumpoker
Pass A. Record what is observed here.

**scrumpoker audit, 2026-10-30, read-only, no code changed.** 57 real lint findings,
87 files unformatted, 3.82% duplication, 90.03% line coverage excluding the browser code.
No `CLAUDE.md` or stop condition.

## Logged, not fixed (Minor)

From the 2026-11-11 review (`docs/debates/2026-11-11-code-review-and-security-audit-codingstandards-rep.md`):
no ShellCheck in CI; T7's value is written twice for Python (the CLI flag wins); `PL`
brings pylint limits not in `THRESHOLDS.md`; dispatcher copies carry no version marker;
this repo has no single verify command or Stop hook; `budget` mode does not `cd` to
`$ROOT`; jscpd is fetched by `npx` at gate time.

## Open: two sprintboard findings, recorded 2026-08-25, not acted on

1. **Sprintboard copies this standard instead of consuming it.** Its `eslint.config.js`
   restates the thresholds inline. Fix: vendor the packed profile, as
   `sample-repos/typescript-sample/vendor/` does.
2. **T7 coverage is not gated in sprintboard.** Tracked there as
   `docs/adr/0011-test-coverage-is-not-gated.md`, awaiting David's decision.
