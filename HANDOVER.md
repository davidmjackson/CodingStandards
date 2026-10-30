# Handover

Current position only. Prune when an item closes.

## Open: extend the gate to every other project

The three existing consumers run the fail-closed gate in CI and the Stop hook:
AI-TagTeam, crm-reporting2 and leadgen-sprint-report. Next is `audit-standards` on each
remaining repo, one at a time, turning on blocking only once a repo is clean. Code
quality is the goal, so adoption does not wait on a measured saving in effort.

Each consumer holds a copy of `hooks/dispatch.sh`, so a fix here needs copying out.

**scrumpoker audit, 2026-10-30, read-only, no code changed.** 57 real lint findings,
87 files unformatted, 3.82% duplication (over 3%, mostly the two HTML pages), 90.03%
line coverage excluding the browser code, `npm audit` clean. `public/js/app.js` is
767 lines with a complexity of 36 in `handleServerMessage`. `lib/validate.js` is
unused. No `CLAUDE.md` or stop condition. Awaiting a decision on Pass A.

## Open: AI-TagTeam needs redeploying

The upgrades are merged to `feat/referee`, but the live checkout still has zod 3
installed. It needs `npm ci`, `npm run build`, a Claude Code restart, and one real
debate. No live debate has run on zod 4.

## Open: two sprintboard findings, recorded 2026-08-25, not acted on

1. **Sprintboard copies this standard instead of consuming it.** Its `eslint.config.js`
   restates the thresholds inline, which `STANDARD.md` principle 1 forbids. Fix: vendor
   the packed profile (`profiles/typescript/codequalitystandards-eslint-config-1.0.3.tgz`),
   as `sample-repos/typescript-sample/vendor/` does.
2. **T7 coverage is not gated in sprintboard.** Tracked there as
   `docs/adr/0011-test-coverage-is-not-gated.md`, awaiting David's decision.

Detail: `~/codingstandards-archive/docs/2026-08-25-session-record.md` (archived, outside the repo).
