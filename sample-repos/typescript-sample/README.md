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

| Path                                       | Purpose                                                                                                |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| `src/calculator.ts`                        | Clean code. Passes every gate.                                                                         |
| `tests/`                                   | vitest tests + v8 coverage gate (80%).                                                                 |
| `eslint.config.js` / `prettier.config.mjs` | Re-export the shared profile — nothing defined locally.                                                |
| `vitest.config.ts`                         | Coverage thresholds.                                                                                   |
| `.jscpd.json`                              | Duplication config (3% threshold).                                                                     |
| `prove-gate.sh`                            | Packs the config as a tarball, installs it with `npm ci`, runs the whole acceptance test.              |
| `src/plain/`                               | CommonJS and browser JavaScript, tested and counted in coverage.                                       |
| `../fixtures/typescript/`                  | Deliberately bad code, kept outside the sample so its gate stays green. The proof plants it in `src/`. |

## Run it

```bash
./prove-gate.sh
```

It runs the sample's real gate, `npm run verify`, and proves:

1. **Green as shipped.**
2. **Red for the intended reason** — with the bad fixtures planted in `src/`,
   eslint reports `max-lines-per-function` (T1), `complexity` (T2),
   `sonarjs/cognitive-complexity` (T3), `max-params` (T4) and an undefined name in
   plain JavaScript. An untested JavaScript module fails the coverage threshold (T7), and a copied
   file fails jscpd (T6).
3. **Green again** once the fixtures are removed.

Every rule maps to a threshold in [`/core/THRESHOLDS.md`](../../core/THRESHOLDS.md).
