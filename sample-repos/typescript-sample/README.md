# typescript-sample

Acceptance test for the JS/TS profile. It consumes the shared config package in
one line each:

```js
// eslint.config.js
export { default } from '@codequalitystandards/eslint-config';
```
```js
// prettier.config.mjs
export { default } from '@codequalitystandards/eslint-config/prettier';
```

## Layout

| Path | Purpose |
|---|---|
| `src/calculator.ts` | Clean code. Passes every gate. |
| `src/violations/badCode.ts` | Deliberately bad — oversized function, high complexity, too many parameters, and a duplicated block. |
| `tests/` | vitest tests + v8 coverage gate (80%). |
| `eslint.config.js` / `prettier.config.mjs` | Re-export the shared profile — nothing defined locally. |
| `vitest.config.ts` | Coverage thresholds. |
| `.jscpd.json` | Duplication config (3% threshold). |
| `prove-gate.sh` | Packs the config as a tarball, installs it, runs the whole acceptance test. |

## Run it

```bash
./prove-gate.sh
```

It proves:

1. **Gate fails on bad code** — eslint reports `max-lines-per-function` (T1),
   `complexity` (T2), `sonarjs/cognitive-complexity` (T3), and `max-params`
   (T4); jscpd flags the duplicated block.
2. **Gate passes once corrected** — eslint and prettier are clean, tests pass
   at 100% coverage (≥ 80%), and jscpd finds no duplication.

Every rule maps to a threshold in [`/core/THRESHOLDS.md`](../../core/THRESHOLDS.md).
