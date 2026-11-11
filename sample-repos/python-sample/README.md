# python-sample

Acceptance test for the Python profile. It consumes the shared profile with one
line in `ruff.toml`:

```toml
extend = "../../profiles/python/ruff.toml"
```

## Layout

| Path | Purpose |
|---|---|
| `src/calculator.py` | Clean code. Passes every gate. |
| `tests/` | pytest tests + coverage gate (80%). |
| `ruff.toml` | Extends the shared profile — nothing defined locally. |
| `pyproject.toml` | pytest + coverage config. |
| `.jscpd.json` | Duplication config (3% threshold). |
| `prove-gate.sh` | Runs the whole acceptance test in an isolated venv. |
| `../fixtures/python/bad_code.py` | Deliberately bad code, kept outside the sample so its gate stays green. The proof plants it in `src/`. |

## Run it

```bash
./prove-gate.sh
```

It runs the sample's real gate, `hooks/dispatch.sh stop`, and proves:

1. **Green as shipped.**
2. **Red for the intended reason** — with the bad fixture planted in `src/`, ruff
   reports `PLR0915` (statements/T1), `C901` (complexity/T2, cognitive proxy T3)
   and `PLR0913` (arguments/T4), and jscpd flags the duplicated block. An untested
   module fails coverage (T7) and nothing else.
3. **Green again** once the fixtures are removed, with a virtualenv's files ignored.

The 400-line module check (T5) is proven by `hooks/test-stop-gate.sh`.

Every rule maps to a threshold in [`/core/THRESHOLDS.md`](../../core/THRESHOLDS.md).
Ruff has no module-length rule, so T5 is a deterministic gate check.
