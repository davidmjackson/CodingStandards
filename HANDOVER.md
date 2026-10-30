# Handover

Current position only. Prune when an item closes.

## Open: extend the gate to every other project

The three existing consumers run the fail-closed gate in CI and the Stop hook:
AI-TagTeam, crm-reporting2 and leadgen-sprint-report. Next is `audit-standards` on each
remaining repo, one at a time, turning on blocking only once a repo is clean. Code
quality is the goal, so adoption does not wait on a measured saving in effort.

Each consumer holds a copy of `hooks/dispatch.sh`, so a fix here needs copying out.

## Open: two sprintboard findings, recorded 2026-08-25, not acted on

1. **Sprintboard copies this standard instead of consuming it.** Its `eslint.config.js`
   restates the thresholds inline, which `STANDARD.md` principle 1 forbids. Fix: vendor
   the packed profile (`profiles/typescript/codequalitystandards-eslint-config-1.0.1.tgz`),
   as `sample-repos/typescript-sample/vendor/` does.
2. **T7 coverage is not gated in sprintboard.** Tracked there as
   `docs/adr/0011-test-coverage-is-not-gated.md`, awaiting David's decision.

Detail: `~/codingstandards-archive/docs/2026-08-25-session-record.md` (archived, outside the repo).
