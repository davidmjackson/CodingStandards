# Scope discipline

Applies to every project in this WSL environment that consumes this standard.

`STANDARD.md` governs how code is written. **This file governs how much gets
written**, which is the failure mode that actually cost time. Sprintboard shipped
good code and roughly 30 percent of its artefacts were never asked for. Nothing in
the quality gates could have caught that, because none of them measure scope.

Evidence: `/var/www/sprintboard/docs/OVER-ENGINEERING-ANALYSIS.md`.

---

## The one rule

**Every project has a written stop condition before the first line is written.**

One sentence, in the first section of the project's `CLAUDE.md`:

> Done means X. Anything else is a new project.

Write it at scaffold time, next to the standard. A project without one **will not
stop**, because nothing in it ever says *enough*. That is the whole lesson.

---

## Before starting any story

Four questions. All four, every time, before design begins.

1. **Which stated outcome does this serve?** Name it. A story that cannot name one
   is out of scope by definition, and saying so is the useful answer.
2. **Does this add a table, a dependency, or a new screen?** If yes, it is an epic
   wearing a story's clothes. Say so before starting, not halfway through.
3. **Is this the smallest thing that satisfies the outcome?** Configurable is not
   the smallest thing. Five field types is not the smallest thing.
4. **If this is skipped, does a stated outcome fail?** If no, it is optional, and
   optional work on a finished product is a new project.

## When asked what is next

**The first candidate answer is "nothing, it ships."**

Offer scope only when it makes a stated outcome work better. If it does not, say so
and stop. Do not design it anyway to show willing. An agent that always has a next
suggestion will always produce a next epic.

## The signals that scope has already gone

Any one of these is a finding to raise, not a mood to push through.

- **A feature nobody asked for is being justified rather than described.** The
  justification is the tell.
- **Test-to-production ratio above 3x on a single feature.** Sprintboard's WIP
  limits carried 22.9 KB of tests over 5.5 KB of code, a 4.2x ratio. High ratios
  cluster on features that were never needed, because nobody knew when to stop.
- **A new table for something the brief did not name.** Sprintboard added 4 of its
  13 tables this way.
- **`CLAUDE.md` growing without a prune.** It is budgeted at 12,288 B by
  `MEMORY-BUDGET.md` and checked on Stop by `hooks/dispatch.sh`. A file over
  ceiling is a symptom, not just a file.
- **Comment ratio above 25 percent in a logic module.** Prose expands to fill the
  space where nobody agreed what was in scope.

## When the work is already done

**Do not delete working features to fix a scope number.** The cost is sunk.
Removing shipped functionality means new migrations, data-loss risk, and
re-testing, in service of a metric nobody sees.

Mark them **CLOSED, not paused**: kept because they exist and work, not because
they were needed. Then prune what is genuinely free to remove, which is prose, dead
guards, and unshipped apparatus.

**Deleting working software to make a metric look better is the same failure in
reverse.**

---

## Where this is enforced

**Nowhere, and that is deliberate.** `STANDARD.md` principle 2 says a rule existing
only as prose does not count as enforced, and that is correct for thresholds. Scope
is a judgement call, and principle 3 puts judgement calls in prose.

Two things are mechanically checked, and both are proxies rather than the thing
itself:

- `CLAUDE.md` byte ceiling, warned on Stop by `hooks/dispatch.sh`
- Complexity and file-size thresholds, in the language profiles

Everything else on this page depends on being read. Keep it short for that reason.
