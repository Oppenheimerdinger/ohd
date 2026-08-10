# campaign: v070-field-hardening
- goal: v0.7.0 — field-hardening release per docs/superpowers/specs/2026-08-10-v0.7.0-field-hardening-design.md (issues #21-#29 + adoption findings; A×9 mechanical, B×5 contract, C observability compressed, D deep-solve appendix, E riders)
- status: OPEN (2026-08-10)
- validation gate: spec is the contract — every A/B/C/D/E item lands as specified or its deviation is written back into the spec in the same wave; fixture RED first for every gate/regex/script change; A1's field fixtures (second-phase-table, numbered headings) in campaign-smoke; r2c growth cap net ≤ +8 lines enforced; B1 sweep leaves ZERO stale stop-rule restatements (grep proof); suites green plain+hermetic; validator PASS + independent review (2b); r2c ends per the NEW terminal rule (dogfood); campaign.sh smoke unmodified except new legs; BEHAVIOR-CHANGE exactly 3; this doc must NOT carry the new table anchor at line start (spec A1 tail)
- result / verdict:
- follow-on:

## plan
- [ ] D deep-solve appendix wording FROZEN first (7 co-moving sites) — single commit
- [ ] B1 stop-rule multi-site sweep (r2c, way-of-working, campaign-land, deep-solve) + carve-outs — single commit, grep proof no stale restatement
- [ ] A1+C0 campaign.sh: sentinel regexes ×2 sites + die msg + heredoc named-cell prompts (C1 marker) + smoke legs
- [ ] C2 land debt line (~15 lines, NEVER-OFFERED set-difference, gh-absent honest)
- [ ] A7/A8/A9/C1/C5/E2/E5 checkup.sh wave (try-both pointers, structure footer+staleness row, remedy text, bypass sub-count, fork contract incl. FORK-REFUSED, GAPS scoping)
- [ ] A2/A5/B3/B4 r2c wave (cap ≤ +8 net)
- [ ] A3/B2/C4b/E3 campaign-land wave
- [ ] A4/A6/B5/E7 deep-solve wave
- [ ] E4 home-set 2-liner; C4a/A3 scaffold comments
- [ ] E1/E6/E8 docs+issues (comment-maps per spec — #14 map corrected form)
- [ ] version 0.7.0 + CHANGELOG (BEHAVIOR-CHANGE: A1, B1, B2 — exactly 3)
