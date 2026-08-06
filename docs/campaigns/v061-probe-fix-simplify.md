# campaign: v061-probe-fix-simplify
- goal: v0.6.1 — backlog #15: provenance_block fabricated `git=n/a-dirty` outside a git tree (real defect) + the five simplifier worth-doing items (P2-P6) from the v0.6.0 land pass
- status: LANDED (2026-08-06)
- validation gate: defect gets fixture RED first (non-git dir → block must read `git=n/a`, never `n/a-dirty`); pure simplifications prove OUTPUT-IDENTICAL behavior (suites green + before/after output diff where a consumer greps it); validator PASS + independent review (2b — script logic); r2c ends clean or fully disposed; campaign.sh untouched; marginal/rejected simplifier items NOT in scope (backlog #15 records them — do not re-litigate)
- result / verdict: LANDS — merged as PR #20 (82acc49), tagged v0.6.1 == pushed HEAD, deployed 0.6.0→0.6.1 (cache verified)
- follow-on: backlog #16 (field-incident relay lines — needs a design pass, next candidate); #17 (gate pattern / whitelist pairing / desc budgets / mutation_run 117-line headroom); dogfood cleanup campaign still pending from v0.6.0

## plan
- [x] P1 provenance_block.sh:78-79 — non-git fixture RED, then guard: `[ "$GIT" = n/a ] || git diff --quiet 2>/dev/null || GIT="$GIT-dirty"`; probes-smoke case pinned
- [x] P2 checkup.sh:217-221 — always-loaded row: single `report` with status variable (emitted lines byte-identical both directions)
- [x] P3 checkup.sh:337-344/457-467 — one `sol_candidates()` for the row count AND the structure list (explicit `return 0` — non-zero fn return inside `$( )` aborts under set -e; AND-list exemption does NOT carry); census/audit split stays
- [x] P4 checkup.sh:105/115 — hoist the template config-inner slice out of the per-line loop (one sed, reused)
- [x] P5 checkup.sh:85-90 — nest the --sync guard (outer sync gate, inner markerless fork); truth table unchanged
- [x] P6 ohd-checkup.md:27-31 — cut the restated exit-code-shaped paragraph to a pointer (canonical text lives in engage_grep.sh header + home-set conventions.md)
- [x] version 0.6.1 + CHANGELOG (one BEHAVIOR-CHANGE line: the probe no longer fabricates a dirty flag outside git)
- [x] campaign.sh body untouched (verified at land: `git diff origin/main -- assets/campaign.sh tools/campaign.sh` empty at 57a52cf, re-checked by rounds 1-3)

## land report
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | yes | campaign.sh new worktree/branch; landed via PR #20 (repo's branch→PR→review→merge route) |
| 0.5 plan recorded    | yes | plan (8 items) written before dispatch; all closed |
| 1 working-tree safety| yes | code commits worktree-only; anchor docs-only; implementer's trunk-owned-doc commit (9c4abbb) caught and dropped pre-review |
| 2 re-validation      | yes | five suites green @57a52cf plain + hermetic; CI green push+PR; plugin-validator PASS @9642c71 |
| 2.5 reachability     | yes | plugin.json 0.6.1; deployed 0.6.0→0.6.1, cache dir present |
| 3 quality gate       | yes | r2c 3 rounds (log above), terminal clean, 3 residual LOWs disposed; simplifier: this release IS the v0.6.0 simplifier batch — no further pass |
| 4 docs same-land     | yes | CHANGELOG 0.6.1 (exactly 1 BEHAVIOR-CHANGE line); backlog #15 → RESOLVED (v0.6.1, 33284ea) in-branch; reference: nothing to graduate — defect fix + refactor, no new settled knowledge (the probes' rule already lives in its reference homes; this land strengthened its pointers); verification: promoted to tests/ — non-git + dirty-repo probe cases, TMPDIR fixture guard |
| 5 merge mechanics    | yes | PR #20 merged 82acc49; tag v0.6.1 == pushed HEAD; branch+worktree removed post-land |
| 6 distill + hygiene  | yes | sanity: delta-check — full audit ran same day at v0.6.0 land; this diff (`plugin.json CHANGELOG.md assets/checkup.sh assets/home-set/reference/conventions.md assets/probes/{engage_grep,provenance_block}.sh commands/ohd-checkup.md docs/backlog.md tests/probes-smoke.sh`) touches no CLAUDE.md/memory-contract line; version==tag==HEAD, lock-step 3/3, backlog fixing-commit convention re-verified by round 3; memory updated same land |

## convergence log (r2c on PR #20)
- round 1: plugin-validator PASS + independent review (code-reviewer) @9642c71 → APPROVE, 0 Critical/Important, 6 Minor (2 newly-added comments overstating code behavior, missing `local`, fixture env fragility, unanchored assertion, coinage absent from canonical home); reviewer ran its OWN 33-scenario output-identity harness incl. both named landmine cases → fixed 08f4c80.
- round 2: scoped @08f4c80 → 0 Crit/High/Med, 3 LOW (guard preempted by earlier unguarded fixture — reproduced; backlog SHA omission; coinage missing from second home) → fixed 57a52cf.
- round 3 (terminal): scoped @57a52cf → APPROVE, clean. All three L-fixes verified by execution incl. TMPDIR-inside-repo counterfactual at 08f4c80 vs HEAD. 3 residual LOWs disposed:
  - GIT_DIR-exported env fires the guard with a misleading message — PRE-EXISTING (reproduced at 9642c71 before the guard existed); suite is GIT_DIR-hostile end-to-end, fail-closed either way. Logged, no wave.
  - #15 heading credits 33284ea (defect commit) for a multi-commit resolution — precedent-consistent (singular "fixing commit"), body text disambiguates. Accepted.
  - Guard hoist trades point-of-use locality for coverage of both fixtures — accepted tradeoff, currently unreachable failure shape, noted by reviewer as net positive.
