# campaign: regress-verdict-projroot
- goal: v0.5.22 — fix two regressions found by an independent convergence (round-2) pass on v0.5.20/v0.5.21: over-tight verdict grep (silently under-counts checkup's land-report audit) and PROJECT_ROOT derivation breaking --separate-git-dir/submodule layouts (reintroduces issue #10 collisions)
- status: OPEN (2026-07-31)
- validation gate: repro-driven — each fix must flip its own reproduction (bold/Korean/checkbox verdict rows accepted again; sibling separate-git-dir clones both succeed; submodule derives its own name), all four suites green, parity intact
- result / verdict: LANDS — merged as PR #16 (squash 1e1f5f8), tag v0.5.22; 5-round convergence ending clean-by-ruling
- follow-on: fence fail-open + checkbox fail-closed edges (0/365 witnesses, backlog §11); audit label-branch exclusion asymmetry (0 witnesses)

## plan
- [x] F1 verdict grep: allow checkbox/emphasis/non-English label decoration between the bullet marker and the verdict word or key, in assets/campaign.sh + tools/campaign.sh (clean gate) and assets/checkup.sh (land-report audit); the 8-word-prose bypass line that motivated the anchoring must STAY blocked
- [x] F2 PROJECT_ROOT: replace the unconditional --git-common-dir derivation with the layout-conditional form (main worktree -> $ROOT; linked worktree -> first entry of `git worktree list --porcelain`), verified across main/linked/subdir/symlink/--separate-git-dir/submodule/worktree-of-submodule
- [x] F4 land gate (pre-existing sibling of F1): same decoration tolerance + reject plan-bullet false positives (`- [ ] add a | phase | table later` must NOT satisfy it)
- [x] fixtures: one per repro above, in campaign-smoke + checkup-smoke; each must fail against the current shipped code
- [x] F3 doc indent; CHANGELOG (BEHAVIOR-CHANGE for the audit-coverage restoration) + version 0.5.22
- [x] (implementer finding, mid-campaign) two MORE sites carried the same unanchored `| phase |` hole — checkup's audit exemption (would have half-fixed the audit) and `--report`'s duplicate detection (blocked scaffolding)
- [x] (live dogfood, mid-campaign) this campaign's own land hit the bug: the plan line above quoting the header satisfied the ANCHOR's still-buggy land gate, so `land` pushed with NO report table and `--report` refused to scaffold one — table written by hand below

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | yes | round-2 convergence verdict (2 regressions, live repros) |
| 0.5 plan recorded    | yes | ## plan above, cut at open, updated twice mid-campaign |
| 1 working-tree safety| yes | wt clean; 45235b5 = origin tip |
| 2 re-validation      | skip | single open campaign — no overlap set |
| 2.5 reachability     | yes | nothing gated; gates fire on next campaign.sh/--sync; BEHAVIOR-CHANGE ×6 relayed via checkup |
| 3 quality gate       | yes | convergence log above — 5 rounds ending clean-by-ruling; validator FAIL→fixed→re-verified; simplifier: performed by review (23-line branch → 2 lines in r4), agent not separately run — reason: reviewer prescribed the simplification itself |
| 4 docs same-land     | yes | CHANGELOG (6 BEHAVIOR-CHANGE lines, one-corpus numbers), campaign-land Phase-4/7 notes, backlog §11 — same PR |
| 5 merge mechanics    | yes | base=main, squash 1e1f5f8; anchor ff |
| 6 distill + hygiene  | yes | sanity: skip NOT claimed — diff touches docs/skills, but v0.5.23 6b (evidence-cell naming) not yet shipped; lock-step untouched (grep: 3 files, 1 line each); memory updated same pass — honest gap noted, closes with v0.5.23 |
- [x] (r4, design change) clean/checkup rule SPLIT — three rounds of regex tightening failed because the two consumers have different input distributions (scaffold row: 100% for clean by construction, 23% for audit); clean now anchors on the scaffold's own row
- [x] (r5, text) four-surface honesty pass on teardown messages; 27/33 status-label attribution with method; fence/checkbox edges documented (0/365 witnesses each)
- [x] (r6, text) recovery recipe notes commit-or-force; remote-delete claim scoped to clean|abort --purge

## convergence log (r2c — prototype of the v0.5.23 Phase-3 evidence contract)
| round | reviewer | reviewed SHA | result |
|---|---|---|---|
| 1 | plugin-validator + 5 cr:cr lenses | c54f6e2 | 6 findings (2 posted ≥80, 3 folded, 1 rejected) |
| 2 | independent convergence agent | ce56c11 | 5 findings — shared-rule design defect named |
| 3 | same agent, fresh pass | ba66438 | behavior CLEAN; 3+1 text findings |
| 4 | same agent, scoped | 7866c8b | prior findings closed by execution; 2 low text |
| 5 | maintainer, mechanical | 45235b5 | reviewer-prescribed sentences applied verbatim; grep+suites+parity — RULING: text-only residuals closed per prescription, no behavior surface touched (comment-stripped diff empty) |
