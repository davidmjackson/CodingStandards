# Handover

Current position only. Prune when an item closes.

## Open: extend the gate to every other project

The three existing consumers run the fail-closed gate in CI and the Stop hook:
AI-TagTeam, crm-reporting2 and leadgen-sprint-report. Next is `audit-standards` on each
remaining repo, one at a time, turning on blocking only once a repo is clean. Code
quality is the goal, so adoption does not wait on a measured saving in effort.

Each consumer holds a copy of `hooks/dispatch.sh`, so a fix here needs copying out.

**Blocking the next rollout:** the shared ESLint profile assumes TypeScript. On
CommonJS and browser JavaScript it reports false `no-undef` and `no-require-imports`
errors: 661 of 718 messages on scrumpoker. It needs a JavaScript-aware layer before
any plain JS repo can gate on it.

**scrumpoker audit, 2026-10-30, read-only, no code changed.** 57 real lint findings,
87 files unformatted, 3.82% duplication (over 3%, mostly the two HTML pages), 90.03%
line coverage excluding the browser code, `npm audit` clean. `public/js/app.js` is
767 lines with a complexity of 36 in `handleServerMessage`. `lib/validate.js` is
unused. No `CLAUDE.md` or stop condition. Awaiting a decision on Pass A.

## Open: prove AI-TagTeam on zod 4

The upgrades are installed and built on `feat/referee`. Schemas and input rejection
match the reviewed build over stdio, but no live Codex debate has run on zod 4. If one
fails, revert that merge, then rerun `npm ci` and `npm run build`.

## Open: two sprintboard findings, recorded 2026-08-25, not acted on

1. **Sprintboard copies this standard instead of consuming it.** Its `eslint.config.js`
   restates the thresholds inline, which `STANDARD.md` principle 1 forbids. Fix: vendor
   the packed profile (`profiles/typescript/codequalitystandards-eslint-config-1.0.2.tgz`),
   as `sample-repos/typescript-sample/vendor/` does.
2. **T7 coverage is not gated in sprintboard.** Tracked there as
   `docs/adr/0011-test-coverage-is-not-gated.md`, awaiting David's decision.

Detail: `~/codingstandards-archive/docs/2026-08-25-session-record.md` (archived, outside the repo).
