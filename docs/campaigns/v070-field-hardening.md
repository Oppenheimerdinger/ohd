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
- [x] version 0.7.0 + CHANGELOG (BEHAVIOR-CHANGE: A1, B1, B2 — exactly 3)

## convergence log (r2c, terminal per the release's own new severity-anchored rule)
- round 1: plugin-validator PASS + independent review @b05977c → C0 I6 M9 (C1 marker not the scaffold literal; A5 deep-solve half unimplemented; #7 backlog entry missing while a shipped doc claimed it; E5 scoping unmeasured + C1 nesting; E8 rationale measurement wrong AND the narrowed pattern let a real leak shape through — 축약형 2건, scrubbed; #13/#16/#17 backlog hygiene) → fixed 0ddaacd..038b31a (+ pre-existing probes-smoke flake root-caused as test-harness SIGPIPE, fixed).
- round 2: scoped @038b31a → C0 I3 M7 (I1's fix over-tight — cell-initial anchor silenced the row on this repo's own real mid-cell reports incl. genuine bypasses; gate pattern EOL gap `f[o]rge([^a-z]|$)`; #13 body still asserting the falsified premise) → fixed d57d3e8.
- round 3: scoped @d57d3e8 → C0 I1 M2 — the root cause surfaced: TOKEN-BASED ERA SCOPING IS IMPOSSIBLE (`reference:`/`verification:` are v0.6.0 ritual vocabulary; this repo's own two reports predate the scaffold by 4 days and legitimately carry them; two rounds of anchor tuning could not have worked). Design corrected, not patched: explicit era marker `ohd:land-report-scaffold` emitted by the scaffold alone; region-scoped content checks; spec carries the RECORDED LESSON ("an era boundary must be drawn with a literal the new era ALONE can emit") → fixed 25c395d. ">3 rounds = suspect the design" fired here, correctly.
- round 4: scoped @25c395d → C0 I2 M1, all disclosure/contract text (marker-strip false negative undisclosed; campaign-land's fifth scaffold-describing site incl. the copyable fenced example) → fixed 859d538 (+ 28/3-hit restatement sweep, every hit read).
- round 5 (terminal): scoped @859d538 → C0 I0; both fixer judgment calls upheld; 1 new Minor DISPOSED-DEFERRED → backlog #21 (in-band marker self-description; trigger: field report of a tidied marker or next heredoc-touching release).
- cross-round lesson (implementer's own, logged): detectors were validated against constructed fixtures instead of the repo's real artifacts, twice; the fix each time was one `git log` on the real files. Candidate relay text for a future release; not shipped now.
