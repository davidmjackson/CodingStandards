# Memory Budget

Single source of truth for Claude Code memory limits and the working targets we
hold ourselves to. **Do not restate these numbers in a `CLAUDE.md`, a skill, or a
project memory file.** Reference this file. Numbers restated in two places drift,
and a drifted memory limit is how a file starts silently losing its tail.

## Platform limits (Anthropic's numbers, not ours)

| File | Loaded at session start | Hard limit |
|---|---|---|
| `MEMORY.md` (auto memory index) | Yes | **First 200 lines OR 25KB, whichever comes first** |
| Topic files in the memory directory | No, read on demand | None |
| `CLAUDE.md` / `CLAUDE.local.md` | Yes, **in full** | None. Performance warning at **40KB** |
| `.claude/rules/*.md` without `paths:` | Yes, in full | None |
| `.claude/rules/*.md` with `paths:` | Only when a matching file is read | None |
| Skills | Only when invoked or judged relevant | None |

Source: <https://code.claude.com/docs/en/memory>. Content past the `MEMORY.md`
limit is **dropped on the next load with no error in the session**. Frontmatter
and block-level HTML comments are stripped before measurement, so they do not
count.

## Working targets (ours)

| Measure | Target | Ceiling | Why the gap |
|---|---|---|---|
| `MEMORY.md` lines | 140 | **180** | Leaves room for a session to append before a prune is forced |
| `MEMORY.md` bytes | 16KB | **22KB** | Same, and keeps the nudge quiet |
| `CLAUDE.md` bytes | 10KB | **12KB** | Well under the 40KB warning; adherence falls long before the warning does |
| Combined startup load | 26KB | **34KB** | `CLAUDE.md` + `MEMORY.md` together, which is what a session actually pays |

**Targets are where you aim. Ceilings are where you stop and restructure.** Neither
is the platform limit, and neither should ever be written down as if it were.

## The nudge is not the cap

Claude Code warns *before* the hard limit, telling Claude to shorten the file.
**That warning is a nudge, not a ceiling.** Treating it as the cap is the single
most common failure here, and it has already cost us once.

**Recorded, 2026-08-04, sprintboard.** `MEMORY.md` carried a self-imposed header
rule reading "Keep under 140 lines AND 17KB, both real". Measured state was 131
lines and 17,261 bytes: **66% of the real line cap and 67% of the real byte cap**,
with 69 lines and roughly 8KB of unused headroom. Sessions had been pruning
against a ceiling that did not exist.

Two consequences worth naming, because they are not obvious:

- **Pruning pressure was applied to the wrong file.** `CLAUDE.md` sat at 34,257
  bytes with no cap protecting it, while effort went into a `MEMORY.md` that was
  two-thirds full.
- **The two false rules fought each other.** A 140-line cap forced line-packing:
  the index averaged **288 bytes per line**, with individual lines at 533, 530,
  454 and 441 characters bundling three or four memories each. Line count was
  bought with bytes, and entries became hard to scan, hard to keyword-match and
  impossible to delete without surgery.

**If a limit appears in a warning, verify it against this file before writing it
down as a rule.**

## How to measure

Both dimensions, always. Lines usually bite before bytes, but not always, and a
file that is fine on one can be over on the other.

```bash
MEM=~/.claude/projects/<project>/memory/MEMORY.md
wc -l -c "$MEM"                    # lines and bytes together
wc -c CLAUDE.md                    # the file with no cap protecting it
```

Composition matters more than the total. Split the index by section and check
where the bytes actually are before deciding what to cut:

```bash
awk '/^#{2,3} /{if(n!="")printf "%6d B %4d L  %s\n",b,l,n; n=$0;b=length($0)+1;l=1;next}
     {if(n!=""){b+=length($0)+1;l++}} END{printf "%6d B %4d L  %s\n",b,l,n}' MEMORY.md
```

In session, `/context` shows what actually loaded and what it cost. `/memory`
opens the files. `/doctor` proposes trims for a checked-in `CLAUDE.md`.

## Recorded observations

Timestamped measurements, not constants. Re-derive rather than trusting a line
here.

| Date | Project | `CLAUDE.md` | `MEMORY.md` | Topic files | Note |
|---|---|---|---|---|---|
| 2026-08-04 | sprintboard | 34,257 B / 524 L | 17,261 B / 131 L | 62 files, 372 KB | Session narrative + follow-ups were 45% of index bytes, 75% of its lines |
| 2026-08-25 | sprintboard | **75,118 B** | not measured | not measured | **6.3x the 12KB ceiling.** Doubled in three weeks. See below. |
| 2026-08-25 | `~/.claude` (global) | **21,296 B** | n/a | n/a | **1.8x the ceiling.** A sprintboard session pays 96KB of `CLAUDE.md` before `MEMORY.md` loads: **2.8x the 34KB combined ceiling.** |

## The 2026-08-04 lesson repeated itself, measured 2026-08-25

The 2026-08-04 entry records that pruning pressure went to `MEMORY.md` while
`CLAUDE.md` "sat at 34,257 bytes with no cap protecting it". **Twenty-one days
later that file is 75,118 bytes**, and nothing in the interval flagged it,
because nothing measures it. The `MEMORY.md` limit produces a warning in
session; the `CLAUDE.md` target in this document produces nothing at all unless
somebody runs `wc -c`.

**A budget with no trigger is a preference.** That is a stronger finding than the
original one: the problem was never only that the wrong file was pruned, it is
that just one of the two files can ever announce a problem.

Worth naming plainly: roughly 9KB of sprintboard's growth and 7KB of the global
file's landed on 2026-08-24, in a session whose subject was reducing volume.
Prose written to prevent over-documentation is still prose, and it is charged to
the same budget as everything else.

**Before adding to any `CLAUDE.md`, measure it first** (`wc -c CLAUDE.md`). If the
file is already over ceiling, the change is a prune plus an addition, never an
addition alone.
