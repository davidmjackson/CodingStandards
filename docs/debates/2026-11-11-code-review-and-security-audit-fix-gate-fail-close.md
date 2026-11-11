# Debate: Code review and security audit: fix/gate-fail-closed (implements the 2026-11-11 agreed repair)

- Id: 2026-11-11-code-review-and-security-audit-fix-gate-fail-close
- Opened: 2026-11-11T08:29:21.514Z
- Model: gpt-6.1-sol
- Max rounds: 3

## Round 1/3 — Claude

Please review the STAGED diff on branch fix/gate-fail-closed against base b5b37f2 (`git diff --cached`). Purpose: implement the solution we agreed in docs/debates/2026-11-11-code-review-and-security-audit-codingstandards-rep.md. Consumer repos are not touched yet; propagation is the next stage.

WHAT CHANGED
1. hooks/dispatch.sh. New ruff_config() recognises .ruff.toml, ruff.toml, and pyproject.toml when its parsed (tomllib) tool table has "ruff". It returns 0/1, or 2 for an unreadable pyproject, which is red. New python_stack(): .py files (python_modules exclusions) with no Ruff config is red. New run_stack_gates(): red when no supported stack is found. run_full_gate now calls run_stack_gates.
2. Two defects I found while implementing, and fixed:
   (a) Ruff's default output prints a code snippet per finding, so the 40-line tail cut the rule codes off and the agent saw snippets with no diagnostic. Both modes now pass --output-format=concise.
   (b) The old Python proof's PLR0915 check was a false pass. Rule names were matched in the full output, and the fixture has a comment containing 'PLR0915', which the snippet printed. PLR0915 never fired: classify has fewer than 30 statements. The fixture now has a genuine 32-statement function, and concise output prints no source.
3. Fixtures moved to sample-repos/fixtures/{python,typescript}, outside each sample's gate discovery. Nothing in the dispatcher excludes 'violations'.
4. Both prove-gate.sh scripts now run the exact adopted command (`hooks/dispatch.sh stop`, `npm run verify`). Each goes green, then red for the intended reason, then green again. Planted files are removed by an EXIT trap.
   - Python cases: lint (PLR0915, C901, PLR0913) plus duplication; coverage alone, asserting no Ruff or duplication failure; venv exclusion, now planted inside the sample's real .venv instead of an otherwise-empty project; and the fragment coverage-source test, kept.
   - TS cases: lint rules; undefined name; an untested .js module failing the coverage threshold (verify chains with &&, so reaching coverage means lint and format passed); a copied test file failing only on jscpd.
5. TS sample:
   - pins eslint 9.39.5, prettier 3.9.10 and typescript 5.9.3;
   - tracks package-lock.json (the .gitignore line is dropped);
   - uses npm ci, which I verified works because npm pack is byte-identical across runs;
   - coverage now includes src/**/*.{ts,js};
   - src/plain/package.json marks that folder as CommonJS, so commonjs.js can actually run;
   - tests/plain.test.ts loads both files via createRequire. I confirmed that both show measured coverage.
   - New .prettierignore (coverage/, vendor/). Without it, `prettier --check .` failed verify on any second local run because of the previous run's coverage output.
6. Python proof pins pytest 9.1.1 and coverage 7.15.2.
7. hooks/test-dispatch.sh plants fixtures inside the samples so post mode uses the sample config.
8. Docs: hooks/README.md documents the detection rules. The sample READMEs are rewritten; the Python one dropped a false claim that its proof checks T5. HANDOVER.md records David's ruling (observe first) and the logged minors.

EVIDENCE: test-stop-gate.sh shows 65 PASS (54 before). There are 8 new detection cases, written first and seen failing. test-dispatch.sh, python prove-gate.sh (6 PASS) and TS prove-gate.sh (6 PASS) all pass. The three consumers will not be newly red: the two JS repos have no .py files, and leadgen has ruff.toml.

PLEASE CHECK: correctness, fail-open paths I missed, error paths, and injection or secret handling. In particular:
- python_stack's case on $? straight after ruff_config;
- the inline python's exception list (TOMLDecodeError subclasses ValueError);
- whether `python_modules | head -1` under pipefail can misbehave;
- the EXIT-trap cleanup;
- whether either proof can pass for the wrong reason.

## Round 1/3 — ChatGPT: OBJECT

The staged repair addresses the agreed baseline defects, but three issues remain.

1. hooks/dispatch.sh:201–220 can still report green after a detection error. With pyproject.toml containing `tool = 1`, membership testing raises an uncaught TypeError and Python exits 1. python_stack treats that as ordinary absence of configuration. I reproduced a JS project reporting ‘Full gate green’ after this traceback using an in-memory harness with passing JS verification. Validate TOML table types, reserve exit 1 for confirmed absence, and make every unexpected status red. Add mixed-stack regressions so the no-supported-stack fallback cannot conceal this error.

2. Both prove-gate.sh scripts register unconditional deletion of fixed filenames before setup completes: Python lines 21–22 and TypeScript lines 17–18. Existing src/untested.py, src/untested.js or tests/copy.test.ts files can be overwritten or deleted. Even an early npm ci failure triggers deletion of paths the proof never created. hooks/test-dispatch.sh:23–28 has the same overwrite/delete problem for planted fixtures. Reject existing paths, including dangling symlinks, before installing cleanup; clean up only files created by that invocation. Verify that setup failure preserves pre-existing files.

3. sample-repos/python-sample/prove-gate.sh:57–67 weakens the fragment coverage regression. Negating coverage report accepts every report failure, including ‘No data to report’, as proof that untested production code was counted. I confirmed that a nonexistent coverage source produces this failure after a successful test body. Assert the threshold diagnostic and restore the previous green check after removing the untested module; otherwise this proof can pass for the wrong reason.

The immediate `$?` case is sound, and ValueError covers TOMLDecodeError. The head pipeline does not itself cause a false negative here: the enclosing nonempty-string test determines the condition, regardless of SIGPIPE status.

Independent checks passed: Bash syntax, clean TypeScript ESLint/Prettier, and Python Ruff lint/format. Staged diff checking fails on the new debate document’s trailing blank line at line 149. I did not rerun the installation or filesystem-writing acceptance suites in this read-only session. No files changed; branch remains fix/gate-fail-closed at b5b37f2, with no commit or push performed. Consumer propagation appropriately remains a separate stage.
## Round 2/3 — Claude

All three conceded and fixed. The staged diff is updated.

1. DETECTION ERROR GREEN: fixed.
- The probe now exits NO_RUFF_TABLE=10 only for a confirmed absence.
- A non-table `tool` exits with an error message, via sys.exit(str), which gives exit 1.
- Read errors exit the same way.
- ruff_config maps 0 to configured, 10 to absent, and every other status to 2. python_stack treats 2, and anything else unexpected, as red with 'cannot tell whether Ruff is configured.'
- New mixed-stack regressions, each beside a passing JS verify stub:
  - `tool = 1` blocks, and does not print 'Full gate green';
  - an unreadable pyproject.toml blocks;
  - a valid pyproject.toml without tool.ruff and with no .py files stays green, so absence still works.
- test-stop-gate.sh: 69 PASS.

2. CLEANUP SAFETY: fixed in one place.
- New sample-repos/prove-lib.sh holds pass, fail, expect_green, expect_red and finish. It also holds refuse_existing, which exits 2 if any planted path exists. That includes dangling symlinks, via -e || -L.
- Both proofs, and hooks/test-dispatch.sh, now call refuse_existing BEFORE installing the EXIT trap. Cleanup can therefore only remove what the run created, and an early npm ci failure deletes nothing that already existed.
- The Python proof also guards its .venv/qa-duplicate directory and removes it in cleanup.
- Verified: with a pre-existing src/untested.js containing 'keep-me', the TS proof refused with exit 2 and the file survived. A dangling-symlink tests/copy.test.ts was also refused and kept.
- The guard also caught a real leftover: an empty .venv/qa-duplicate from my first version.
- test-dispatch.sh now uses fixed plant paths under the same guard. Its old tmp files, TempBad.cs and tempFormat.ts, were unguarded before this change and are now covered too.

3. FRAGMENT PROOF: fixed. It now asserts 'less than fail-under=80' in the report output. After removing the untested module it asserts green again, which restores the earlier check. The Python proof shows 7 PASS.

Also: I trimmed the trailing blank lines in both debate transcripts, and `git diff --cached --check` is now clean.

All suites green: test-stop-gate (69), test-dispatch (real tools, .py/.ts/.cs), Python proof (7), TS proof (6). Do you agree this stage is complete?

## Round 2/3 — ChatGPT: AGREE

The updated staged implementation resolves all three objections. In hooks/dispatch.sh, ruff_config distinguishes confirmed absence from errors, and python_stack rejects unexpected statuses. My read-only harness verified scalar tool values, malformed TOML, and exits 1/137 block beside passing JS verification; confirmed absence remains green, and Ruff subsections invoke Python checks.

sample-repos/prove-lib.sh rejects existing paths and dangling symlinks before cleanup traps are installed. Both sample proofs and test-dispatch.sh use that guard. The Python fragment proof now requires the threshold diagnostic and verifies restored green after removing the untested module.

Bash syntax, staged diff checking, TypeScript ESLint/Prettier, and Python Ruff checks passed independently. I did not rerun the filesystem-writing acceptance suites in this read-only environment, so their reported counts remain Claude’s evidence. I found no remaining blocking correctness or security issue in this stage.

## Outcome: AGREED

**Agreed solution, in ChatGPT's words:**

Approve the staged repair: fail closed on missing Python configuration, detection errors, and unsupported projects; prove both samples’ actual gates through green, intended lint/coverage failures, and restored green; protect existing files during fixture cleanup; include production JavaScript in coverage and pin sample tooling. Propagate to the three existing consumers through separate reviewed stages, and observe outcomes before wider adoption.
