# Debate: Should T2 (cyclomatic complexity) stay at 10 globally in core/THRESHOLDS.md, or move to 15 for every repo?

- Id: 2026-10-30-should-t2-cyclomatic-complexity-stay-at-10-globall
- Opened: 2026-10-30T18:15:31.598Z
- Model: gpt-6.1-sol
- Max rounds: 3

## Round 1/3 — Claude

Keep T2 at 10 globally for now, with repos deviating by ADR. This is a design-final checkpoint on an open question; David decides if we disagree.

Reasons:
1. The only evidence for 15 is one repo. Sprintboard ADR 0007 (not in this repo, so quoted here) found three cases where a limit of 10 dictated a split, in code sitting at exactly 10 of 10: BoardTab, BoardColumnEmpty and ProjectShell. Its own text says two of the three splits were good shapes anyway. Its reversal test is "a function between 11 and 15 shipped a defect that a limit of 10 would have prevented", and nobody has measured that either way.
2. The per-repo ADR route already handles the case at low cost: a repo that hits saturation raises the number and records why. A global change would remove that friction for repos that have shown no problem.
3. Python is the strongest reason. core/THRESHOLDS.md says Ruff has no cognitive complexity rule, so C901 acts as the practical proxy for T3. In TS and C#, T3 (cognitive 15) still catches nested code if T2 relaxes. In Python, raising T2 relaxes the only complexity control there is.
4. Raising the ceiling costs nothing to do later, while lowering it after code has grown to fit is a retrofit across every consumer.

The strongest case against me: a standing ceiling that is saturated is a design constraint nobody agreed to, the agent writes to the limit, and 15 matches T3 so that neither measure bites first by accident. Requiring an ADR per repo also means the same argument gets made repeatedly.

Read core/THRESHOLDS.md and the two profile configs, and say where this is wrong. If you think a split is better (for example, 15 for TS and C# but 10 for Python), argue it, including what that does to the "numbers defined once" principle.

## Round 1/3 — ChatGPT: AGREE

Keep 10 as the global default for now. I independently read the policy, all three profiles, the sample gate scripts, and Sprintboard’s actual ADR 0007.

The implementation supports your position: profiles/typescript/eslint.config.js:20–22 enforces cyclomatic 10 and cognitive 15 separately; profiles/python/ruff.toml:30 sets C901 to 10; profiles/csharp/SonarLint.xml configures S1541 at 10 and S3776 at 15. core/STANDARD.md:22–23 explicitly permits exceptions through a written ADR. Sprintboard’s evidence therefore has an existing route without changing every consumer.

Three qualifications matter:

1. Sprintboard demonstrates a real cost of 10: ADR 0007 records threshold-driven extraction. Two extractions also being sensible does not invalidate that cost. However, its evidence does not establish that 15 improves outcomes across languages. The sample prove-gate.sh scripts demonstrate enforcement, not whether 10 or 15 produces better designs. Neither number is empirically validated by those tests.

2. Matching T2 numerically to T3 is not a sound justification. core/THRESHOLDS.md:16–17 defines different measurements. Equal limits cannot ensure neither rule triggers first. Python’s documented C901 proxy also does not independently measure cognitive complexity; retaining 10 preserves its current protection without proving it satisfies T3.

3. The ADR’s reversal criterion—requiring a shipped defect that 10 would have prevented—is too restrictive. Repeated unnecessary extraction, reduced cohesion, review difficulty, and maintenance cost can justify revisiting the default without an attributable production defect. Conversely, saturation alone does not establish that a function should grow.

I would not introduce a language split on this evidence. A centrally documented split could preserve 'numbers defined once', but it would explicitly change the separate 'same number across languages' requirement in core/THRESHOLDS.md:3–6 and core/STANDARD.md:9–12. There is insufficient evidence here to warrant that policy change.

## Outcome: AGREED

**Agreed solution, in ChatGPT's words:**

Retain global T2 at 10 across C#, TypeScript/JavaScript, and Python. Allow justified repository exceptions through the existing ADR process, including 15 where concrete examples support it. Reconsider the global default when comparative evidence shows recurring design or maintenance costs; do not require a preventable shipped defect as the sole deciding evidence.

