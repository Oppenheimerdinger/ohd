# campaign: v070-field-hardening
- goal: v0.7.0 — field-hardening release per docs/superpowers/specs/2026-08-10-v0.7.0-field-hardening-design.md (issues #21-#29 + adoption findings; A×9 mechanical, B×5 contract, C observability compressed, D deep-solve appendix, E riders)
- status: LANDED (2026-08-10)
- validation gate: spec is the contract — every A/B/C/D/E item lands as specified or its deviation is written back into the spec in the same wave; fixture RED first for every gate/regex/script change; A1's field fixtures (second-phase-table, numbered headings) in campaign-smoke; r2c growth cap net ≤ +8 lines enforced; B1 sweep leaves ZERO stale stop-rule restatements (grep proof); suites green plain+hermetic; validator PASS + independent review (2b); r2c ends per the NEW terminal rule (dogfood); campaign.sh smoke unmodified except new legs; BEHAVIOR-CHANGE exactly 3; this doc must NOT carry the new table anchor at line start (spec A1 tail)
- result / verdict: LANDS — merged as PR #30 (a22a31c), tagged v0.7.0 == pushed HEAD, deployed 0.6.1→0.7.0 (cache verified)
- follow-on: git history rewrite for the two scrubbed abbreviation tokens (user re-confirm before force-push); issue-tracker follow-through (post comment drafts for #7/#14/#15, comment+close #21-#24, comment #25-#29 with shipped/cut-with-trigger map); fleet reload + /ohd-checkup (BC 3-line relay; skill-fork consumers port B1/B2/A2/A3 by hand per E6); ohd's own reference-tier adoption still pending from v0.6.0; backlog #19 (#7 sweep), #20 (pattern-tuning lesson), #21 (marker self-description)

## plan
- [x] D deep-solve appendix wording FROZEN first (7 co-moving sites) — single commit
- [x] B1 stop-rule multi-site sweep (r2c, way-of-working, campaign-land, deep-solve) + carve-outs — single commit, grep proof no stale restatement
- [x] A1+C0 campaign.sh: sentinel regexes ×2 sites + die msg + heredoc named-cell prompts (C1 marker) + smoke legs
- [x] C2 land debt line (~15 lines, NEVER-OFFERED set-difference, gh-absent honest)
- [x] A7/A8/A9/C1/C5/E2/E5 checkup.sh wave (try-both pointers, structure footer+staleness row, remedy text, bypass sub-count, fork contract incl. FORK-REFUSED, GAPS scoping)
- [x] A2/A5/B3/B4 r2c wave (cap ≤ +8 net)
- [x] A3/B2/C4b/E3 campaign-land wave
- [x] A4/A6/B5/E7 deep-solve wave
- [x] E4 home-set 2-liner; C4a/A3 scaffold comments
- [x] E1/E6/E8 docs+issues (comment-maps per spec — #14 map corrected form)
- [x] version 0.7.0 + CHANGELOG (BEHAVIOR-CHANGE: A1, B1, B2 — exactly 3)

## convergence log (r2c, terminal per the release's own new severity-anchored rule)
- round 1: plugin-validator PASS + independent review @b05977c → C0 I6 M9 (C1 marker not the scaffold literal; A5 deep-solve half unimplemented; #7 backlog entry missing while a shipped doc claimed it; E5 scoping unmeasured + C1 nesting; E8 rationale measurement wrong AND the narrowed pattern let a real leak shape through — 축약형 2건, scrubbed; #13/#16/#17 backlog hygiene) → fixed 0ddaacd..038b31a (+ pre-existing probes-smoke flake root-caused as test-harness SIGPIPE, fixed).
- round 2: scoped @038b31a → C0 I3 M7 (I1's fix over-tight — cell-initial anchor silenced the row on this repo's own real mid-cell reports incl. genuine bypasses; gate pattern EOL gap `f[o]rge([^a-z]|$)`; #13 body still asserting the falsified premise) → fixed d57d3e8.
- round 3: scoped @d57d3e8 → C0 I1 M2 — the root cause surfaced: TOKEN-BASED ERA SCOPING IS IMPOSSIBLE (`reference:`/`verification:` are v0.6.0 ritual vocabulary; this repo's own two reports predate the scaffold by 4 days and legitimately carry them; two rounds of anchor tuning could not have worked). Design corrected, not patched: explicit era marker `ohd:land-report-scaffold` emitted by the scaffold alone; region-scoped content checks; spec carries the RECORDED LESSON ("an era boundary must be drawn with a literal the new era ALONE can emit") → fixed 25c395d. ">3 rounds = suspect the design" fired here, correctly.
- round 4: scoped @25c395d → C0 I2 M1, all disclosure/contract text (marker-strip false negative undisclosed; campaign-land's fifth scaffold-describing site incl. the copyable fenced example) → fixed 859d538 (+ 28/3-hit restatement sweep, every hit read).
- round 5 (terminal): scoped @859d538 → C0 I0; both fixer judgment calls upheld; 1 new Minor DISPOSED-DEFERRED → backlog #21 (in-band marker self-description; trigger: field report of a tidied marker or next heredoc-touching release).
- cross-round lesson (implementer's own, logged): detectors were validated against constructed fixtures instead of the repo's real artifacts, twice; the fix each time was one `git log` on the real files. Candidate relay text for a future release; not shipped now.

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
<!-- ohd:land-report-scaffold v0.7.0 -->
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | yes | campaign.sh new worktree/branch; landed via PR #30 (branch→PR→review→merge route); anchor clean at land |
| 0.5 plan recorded    | yes | plan (11 items) written before dispatch from the converged spec; all closed |
| 1 working-tree safety| yes | 21 code commits worktree-only; anchor docs-only (spec, plan, convergence log); no shared-tree incidents |
| 2 re-validation      | yes | five suites green @6310fa0 plain + hermetic; CI green push+PR; plugin-validator PASS @b05977c (round 1) |
| 2.5 reachability     | yes | plugin.json 0.7.0; deployed 0.6.1→0.7.0, cache dir present; this land report is the FIRST scaffold-written report (marker above — the new row's denominator goes 0→1 here) |
| 3 quality gate       | yes | r2c 5 rounds terminal @859d538 under this release's own severity-anchored rule — see convergence log above; simplifier: not needed — the release's reviews enforced the r2c +8 growth cap and text compression per wave (one-clause reason per contract) |
| 4 docs same-land     | yes | CHANGELOG (3 BEHAVIOR-CHANGE lines) + spec deviations recorded in-wave + backlog #13 RESOLVED / #19-#21 opened + issue comment drafts in docs/superpowers/plans/; reference: nothing to graduate — the recorded-lesson class lives in the spec postmortem; ohd's own reference tier remains the named dogfood follow-on |
| 5 merge mechanics    | yes | PR #30 merged a22a31c; tag v0.7.0 == pushed HEAD (`git describe --exact-match`); branch+worktree removed post-land |
| 6 distill + hygiene  | yes | sanity: delta-check — this release's own reviews measured §RELEASING's pattern changes (r1 I5 re-measurement, r2 I-2 EOL synthetic); version==tag==HEAD, lock-step 3/3 (validator), backlog conventions verified by rounds 1/3/5; memory updated same land; verification: promoted to tests/ — marker matrix (7 assertions), EOL synthetic, mid-cell fixtures, mocked PR-list truncation leg, SIGPIPE capture-then-match conversion |
