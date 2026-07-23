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
| `violations/bad_code.py` | Deliberately bad — oversized function, high complexity, too many parameters, and a duplicated block. |
| `tests/` | pytest tests + coverage gate (80%). |
| `ruff.toml` | Extends the shared profile — nothing defined locally. |
| `pyproject.toml` | pytest + coverage config. |
| `.jscpd.json` | Duplication config (3% threshold). |
| `prove-gate.sh` | Runs the whole acceptance test in an isolated venv. |

## Run it

```bash
./prove-gate.sh
```

It proves:

1. **Gate fails on bad code** — ruff reports `PLR0915` (statements/T1),
   `C901` (complexity/T2, cognitive proxy T3), and `PLR0913` (arguments/T4);
   jscpd flags the duplicated block; the file-length check (T5) flags an
   oversized module.
2. **Gate passes once corrected** — ruff lint and format are clean, tests pass
   at 100% coverage (≥ 80%), jscpd finds no duplication, and every module is
   within 400 lines.

Every rule maps to a threshold in [`/core/THRESHOLDS.md`](../../core/THRESHOLDS.md).
Ruff has no module-length rule, so T5 is a deterministic gate check.
