# campaign: v071-loops-gates
- goal: v0.7.1 — loops ride OMC ralph (official ralph-loop unwired) + 'ci: retired' first-class + ohd repo drops GitHub Actions, per docs/superpowers/specs/2026-08-11-v0.7.1-loops-gates-design.md
- status: LANDED (2026-08-11)
- validation gate: spec is the contract (deviations written back same wave); 2a's verify-armed probe IS the launch contract (state_write + banner check, never proceed bare); 2d grep proof — zero `ralph-loop` refs outside CHANGELOG/specs history; 1c row report-only, exit 0 under gh-absent/403/404/rulesets paths (fixtures); §RELEASING names the FULL local gate (node --test + 4 smokes + hermetic step) BEFORE the workflow file is removed; suites green plain+hermetic; validator PASS + independent review (2b); r2c terminal per severity rule; BEHAVIOR-CHANGE exactly 2
- result / verdict: LANDS — merged as PR #32 (0a2690b), tagged v0.7.1 == pushed HEAD, deployed 0.7.0→0.7.1; workflow auto-delisted on merge (file removal on default branch delists — the recorded sequencing deviation resolved itself) and ci-coherence flipped DRIFT→CONSISTENT live
- follow-on: FIRST FIELD MANDATE under the new wiring is the acceptance test (verify-armed banner = wired; bare session = revert to /loop fallback + reopen); close #31 (done at land); fleet reload + /ohd-checkup (BC 2줄 relay; skill-fork consumers port the Phase-0 branches by hand); git history rewrite still awaiting owner force-push confirm; issue edit-history purge (owner UI) now incl. #31; disposed-logged residuals: both-blind message text, way-of-working ② scope opener (next touch), desc budget (backlog #17), row-0 no-mechanical-backstop watch
<!-- a finding made during REVIEW belongs on the follow-on line above: the
review log is not read at land time. Harness friction goes on a '- friction:'
line as it happens — reconstructing it at the end loses the small stuff. -->

## plan
<!-- living plan: certain stretch = task checkboxes; uncertain stretch = ONE
line (next probe + decision rule). Results edit this section, plus a one-line
reason. -->
- [x] 2a/2b autonomous-mandate re-wire FIRST (8-item delta list in spec: state_write arming w/o awaiting_confirmation, verify-armed banner probe, PRD done-contract injection, verdict-before-cancel exit, cap-is-soft note, OMC state path, /loop fallback honesty) — single commit
- [x] 2c/2d sweep: ohd-setup roster, way-of-working rows + 4a filing rule, README, USAGE-ko, backlog #9/#10 restamps — grep proof zero ralph-loop refs
- [x] 1a/1b campaign-land: declaration form + Phase 0 three-branch (half-retired warning; v0.7.0 clauses intact as branch 2)
- [x] 1c checkup CI-coherence row (guarded first network call; workflow list + protection 200/404/403 branches + rulesets endpoint; MANUAL-CHECK honesty; fixtures for each path)
- [x] 1d campaign-dropin sentence (local-gate default + cost warning)
- [x] 3a/3b parity guard → local suite; §RELEASING full-gate + hermetic named step; README Test section; THEN remove .github/workflows + disable
- [x] 3c CLAUDE.md `ci: retired` declaration (dogfood — 1c must read consistent)
- [x] 4a .github/ISSUE_TEMPLATE (web filers) + the plugin-shipped filing rule line
- [x] version 0.7.1 + CHANGELOG (BEHAVIOR-CHANGE exactly 2; 3d honest-residue prose)
- [x] campaign.sh body untouched (verify at land)

## convergence log (r2c, severity-anchored terminal)
- round 1: plugin-validator PASS + independent review @1b7cc11 (first reviewer instance died to an API error immediately after source-confirming the flagship claim; relaunched fresh, no inheritance) → C0 I3 M10. FLAGSHIP VERIFIED at OMC source (three-link chain: state_write's session_id param selects only the path; the stop hook strict-matches the BODY id; the state bag merges to body root — implementer's beyond-spec session_id-in-body catch was mandatory and correct; all three spec deviations accepted on written rationale). I-3 (state doc untouched on branch) DISPOSED — trunk-owned convention, v0.6.1/v0.7.0 precedent. Fixes f72dd5a (I-2 rulesets blind flag, M4 branch encoding + Branch-not-found ordering w/ STUB_BRANCH_GONE witness, M7 arg-aware stub incl. dead-auth + older-gh fallback, M8 parity guard fail-not-skip) + 096a1ff (I-1 command-doc sweep + timeout honesty, M10-M13). 6/6 mutations caught.
- round 2 (terminal): scoped @096a1ff → C0 I0, M4 L4 all non-blocking; every round-1 fix survived targeted mutation; blind-arm ordering verified right in four shapes incl. both-halves-blind; M11 judged resolved in place (pointer supplementary, not load-bearing). Micro-commit folds the reviewer's three worth-folding items (stale header comment, ~40s figure, rulesets-encoding fixture); disposed-logged: both-blind singular message + cause collapse (cosmetic, no witness), ② scope opener (pre-existing adjacency, next way-of-working touch), desc budget 65w (backlog #17's bullet), CHANGELOG blindness clause (folded if trivial).
- residual watch: row 0 is the only NAMED-contents row with no mechanical backstop (skill-carried by explicit tradeoff — a seeded prompt would read as owed on every land); revisit if a field land skips the branch-1 citation.

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
<!-- ohd:land-report-scaffold v0.7.0 -->
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | yes | campaign.sh new worktree; PR route (PR #32); Phase-0 checks branch 1 — ATTESTED SKIP, declaration quoted verbatim: `- ci: retired (2026-08-11 — owner directive; release gate is the local hermetic suite)`; no required checks bound (1c row CONSISTENT post-merge) |
| 0.5 plan recorded    | yes | plan (10 items) from the converged spec before dispatch; all closed |
| 1 working-tree safety| yes | 15 code commits worktree-only; anchor docs-only; no shared-tree incidents |
| 2 re-validation      | yes | full 5-leg local gate green plain + hermetic @edbc3f5 (rounds 1 AND 2 re-ran independently); plugin-validator PASS @1b7cc11 — this is the release's own new §RELEASING gate, exercised as documented |
| 2.5 reachability     | yes | plugin.json 0.7.1; deployed 0.7.0→0.7.1 cache verified; live ci-coherence row flipped DRIFT→CONSISTENT after merge (the row works both directions on this repo) |
| 3 quality gate       | yes | r2c 2 rounds terminal (log above) — flagship source-verified, 6/6 mutations; simplifier: not needed — reviewer-driven waves with mutation proofs, no growth beyond contract text (one-clause reason per contract) |
| 4 docs same-land     | yes | CHANGELOG (2 BEHAVIOR-CHANGE + honest-residue prose) + spec deviations recorded in-wave ×3 + backlog #9/#10 restamps; reference: nothing to graduate — the wiring contract lives in autonomous-mandate (skill-carried by design), spec carries the postmortem; verification: promoted to tests/ — arg-aware gh stub, 16-series ci-coherence fixtures, parity guard leg, rulesets-encoding regression case |
| 5 merge mechanics    | yes | PR #32 merged 0a2690b; tag v0.7.1 == pushed HEAD; workflow auto-delisted on merge; branch+worktree removed post-land |
| 6 distill + hygiene  | yes | sanity: delta-check — §RELEASING rewritten this release and reviewed in-wave (rounds 1-2 measured the gate text against the code); version==tag==HEAD, lock-step 3/3 (validator), no line-initial anchor; memory updated same land; #31 closed with shipped map |
