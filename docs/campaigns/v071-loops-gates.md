# campaign: v071-loops-gates
- goal: v0.7.1 — loops ride OMC ralph (official ralph-loop unwired) + 'ci: retired' first-class + ohd repo drops GitHub Actions, per docs/superpowers/specs/2026-08-11-v0.7.1-loops-gates-design.md
- status: OPEN (2026-08-11)
- validation gate: spec is the contract (deviations written back same wave); 2a's verify-armed probe IS the launch contract (state_write + banner check, never proceed bare); 2d grep proof — zero `ralph-loop` refs outside CHANGELOG/specs history; 1c row report-only, exit 0 under gh-absent/403/404/rulesets paths (fixtures); §RELEASING names the FULL local gate (node --test + 4 smokes + hermetic step) BEFORE the workflow file is removed; suites green plain+hermetic; validator PASS + independent review (2b); r2c terminal per severity rule; BEHAVIOR-CHANGE exactly 2
- result / verdict:
- follow-on:
<!-- a finding made during REVIEW belongs on the follow-on line above: the
review log is not read at land time. Harness friction goes on a '- friction:'
line as it happens — reconstructing it at the end loses the small stuff. -->

## plan
<!-- living plan: certain stretch = task checkboxes; uncertain stretch = ONE
line (next probe + decision rule). Results edit this section, plus a one-line
reason. -->
- [ ] 2a/2b autonomous-mandate re-wire FIRST (8-item delta list in spec: state_write arming w/o awaiting_confirmation, verify-armed banner probe, PRD done-contract injection, verdict-before-cancel exit, cap-is-soft note, OMC state path, /loop fallback honesty) — single commit
- [ ] 2c/2d sweep: ohd-setup roster, way-of-working rows + 4a filing rule, README, USAGE-ko, backlog #9/#10 restamps — grep proof zero ralph-loop refs
- [ ] 1a/1b campaign-land: declaration form + Phase 0 three-branch (half-retired warning; v0.7.0 clauses intact as branch 2)
- [ ] 1c checkup CI-coherence row (guarded first network call; workflow list + protection 200/404/403 branches + rulesets endpoint; MANUAL-CHECK honesty; fixtures for each path)
- [ ] 1d campaign-dropin sentence (local-gate default + cost warning)
- [ ] 3a/3b parity guard → local suite; §RELEASING full-gate + hermetic named step; README Test section; THEN remove .github/workflows + disable
- [ ] 3c CLAUDE.md `ci: retired` declaration (dogfood — 1c must read consistent)
- [ ] 4a .github/ISSUE_TEMPLATE (web filers) + the plugin-shipped filing rule line
- [ ] version 0.7.1 + CHANGELOG (BEHAVIOR-CHANGE exactly 2; 3d honest-residue prose)
- [ ] campaign.sh body untouched (verify at land)

## convergence log (r2c, severity-anchored terminal)
- round 1: plugin-validator PASS + independent review @1b7cc11 (first reviewer instance died to an API error immediately after source-confirming the flagship claim; relaunched fresh, no inheritance) → C0 I3 M10. FLAGSHIP VERIFIED at OMC source (three-link chain: state_write's session_id param selects only the path; the stop hook strict-matches the BODY id; the state bag merges to body root — implementer's beyond-spec session_id-in-body catch was mandatory and correct; all three spec deviations accepted on written rationale). I-3 (state doc untouched on branch) DISPOSED — trunk-owned convention, v0.6.1/v0.7.0 precedent. Fixes f72dd5a (I-2 rulesets blind flag, M4 branch encoding + Branch-not-found ordering w/ STUB_BRANCH_GONE witness, M7 arg-aware stub incl. dead-auth + older-gh fallback, M8 parity guard fail-not-skip) + 096a1ff (I-1 command-doc sweep + timeout honesty, M10-M13). 6/6 mutations caught.
- round 2 (terminal): scoped @096a1ff → C0 I0, M4 L4 all non-blocking; every round-1 fix survived targeted mutation; blind-arm ordering verified right in four shapes incl. both-halves-blind; M11 judged resolved in place (pointer supplementary, not load-bearing). Micro-commit folds the reviewer's three worth-folding items (stale header comment, ~40s figure, rulesets-encoding fixture); disposed-logged: both-blind singular message + cause collapse (cosmetic, no witness), ② scope opener (pre-existing adjacency, next way-of-working touch), desc budget 65w (backlog #17's bullet), CHANGELOG blindness clause (folded if trivial).
- residual watch: row 0 is the only NAMED-contents row with no mechanical backstop (skill-carried by explicit tradeoff — a seeded prompt would read as owed on every land); revisit if a field land skips the branch-1 citation.
