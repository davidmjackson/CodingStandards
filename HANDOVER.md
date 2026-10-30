# Handover

Current position only. Prune when an item closes.

## Open: roll the gate out to consumers

`hooks/dispatch.sh` now fails closed, but consumers run their own copies. Each needs
the new copy, and its gate proven against a deliberate violation:

- **AI-TagTeam:** copy is the old version. `verify` already exists.
- **crm-reporting2:** copy is older still. `verify` lacks coverage and duplication.
- **leadgen-sprint-report:** no hook. CI enforces Ruff and coverage but not T5 or T6.

Then extend it to every other project. Code quality is the goal, so adoption does not
wait on a measured saving in effort.

## Open: two sprintboard findings, recorded 2026-08-25, not acted on

1. **Sprintboard copies this standard instead of consuming it.** Its `eslint.config.js`
   restates the thresholds inline, which `STANDARD.md` principle 1 forbids. Fix: vendor
   the packed profile (`profiles/typescript/codequalitystandards-eslint-config-1.0.2.tgz`),
   as `sample-repos/typescript-sample/vendor/` does.
2. **T7 coverage is not gated in sprintboard.** Tracked there as
   `docs/adr/0011-test-coverage-is-not-gated.md`, awaiting David's decision.

Detail: `~/codingstandards-archive/docs/2026-08-25-session-record.md` (archived, outside the repo).
