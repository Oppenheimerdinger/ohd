# campaign: v061-probe-fix-simplify
- goal: v0.6.1 — backlog #15: provenance_block fabricated `git=n/a-dirty` outside a git tree (real defect) + the five simplifier worth-doing items (P2-P6) from the v0.6.0 land pass
- status: OPEN (2026-08-06)
- validation gate: defect gets fixture RED first (non-git dir → block must read `git=n/a`, never `n/a-dirty`); pure simplifications prove OUTPUT-IDENTICAL behavior (suites green + before/after output diff where a consumer greps it); validator PASS + independent review (2b — script logic); r2c ends clean or fully disposed; campaign.sh untouched; marginal/rejected simplifier items NOT in scope (backlog #15 records them — do not re-litigate)
- result / verdict:
- follow-on:

## plan
- [x] P1 provenance_block.sh:78-79 — non-git fixture RED, then guard: `[ "$GIT" = n/a ] || git diff --quiet 2>/dev/null || GIT="$GIT-dirty"`; probes-smoke case pinned
- [x] P2 checkup.sh:217-221 — always-loaded row: single `report` with status variable (emitted lines byte-identical both directions)
- [x] P3 checkup.sh:337-344/457-467 — one `sol_candidates()` for the row count AND the structure list (explicit `return 0` — non-zero fn return inside `$( )` aborts under set -e; AND-list exemption does NOT carry); census/audit split stays
- [x] P4 checkup.sh:105/115 — hoist the template config-inner slice out of the per-line loop (one sed, reused)
- [x] P5 checkup.sh:85-90 — nest the --sync guard (outer sync gate, inner markerless fork); truth table unchanged
- [x] P6 ohd-checkup.md:27-31 — cut the restated exit-code-shaped paragraph to a pointer (canonical text lives in engage_grep.sh header + home-set conventions.md)
- [x] version 0.6.1 + CHANGELOG (one BEHAVIOR-CHANGE line: the probe no longer fabricates a dirty flag outside git)
- [ ] campaign.sh body untouched (verify at land)

## convergence log (r2c on PR #20)
- round 1: plugin-validator PASS + independent review (code-reviewer) @9642c71 → APPROVE, 0 Critical/Important, 6 Minor (2 newly-added comments overstating code behavior, missing `local`, fixture env fragility, unanchored assertion, coinage absent from canonical home); reviewer ran its OWN 33-scenario output-identity harness incl. both named landmine cases → fixed 08f4c80.
- round 2: scoped @08f4c80 → 0 Crit/High/Med, 3 LOW (guard preempted by earlier unguarded fixture — reproduced; backlog SHA omission; coinage missing from second home) → fixed 57a52cf.
- round 3 (terminal): scoped @57a52cf → APPROVE, clean. All three L-fixes verified by execution incl. TMPDIR-inside-repo counterfactual at 08f4c80 vs HEAD. 3 residual LOWs disposed:
  - GIT_DIR-exported env fires the guard with a misleading message — PRE-EXISTING (reproduced at 9642c71 before the guard existed); suite is GIT_DIR-hostile end-to-end, fail-closed either way. Logged, no wave.
  - #15 heading credits 33284ea (defect commit) for a multi-commit resolution — precedent-consistent (singular "fixing commit"), body text disambiguates. Accepted.
  - Guard hoist trades point-of-use locality for coverage of both fixtures — accepted tradeoff, currently unreachable failure shape, noted by reviewer as net positive.
