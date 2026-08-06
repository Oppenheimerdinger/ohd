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
