# campaign: o1-riders
- goal: v0.5.24 — O(1) design vanguard: S4 delegation routing + S5 riders, per docs/superpowers/specs/2026-08-06-o1-harness-design.md (converged via fable 3-lens + terminal pass)
- status: OPEN (2026-08-06)
- validation gate: suites green; validator PASS; cr:cr on PR; convergence log ends clean; zero campaign.sh body changes (design constraint)
- result / verdict: LANDS — merged as PR #18 (squash 204b40d), tag v0.5.24; 3-round convergence ending clean
- follow-on: v0.6.0 body (reference tier, mass budget, 3 probe assets, structure mode); backlog #12 pointer-narrowing; ~1-month re-count of the S4 baselines (Bash call-share 66% — hook ships if not halved)

## plan
- [x] S4a way-of-working delegation table: shell/filesystem INVESTIGATION row (Explore = named vehicle for read-only sweeps; model tier = explicit lever)
- [x] S4b brief hygiene in dispatch guidance: briefs carry POINTERS not payloads; fan-out wider than default needs one stated reason line
- [x] S4c CHANGELOG banks the numeric baselines + pre-committed hook escalation (66% Bash call-share 1,436/2,170; Explore 4/218; trigger: not halved at ~1-month re-count -> PreToolUse counter-nudge hook ships)
- [x] S5a autonomous-mandate: completion judged by the evaluator's verdict, not by whether the stop hook fired (one line)
- [x] S5b campaign-land cell grammar law: cell = verdict + pointer (~<=200 chars), argument in a named section of the same doc; v0.5.23 named cells KEEP their names, only argument mass moves
- [x] S5c owner-correction ledger convention: an owner correction is a trigger failure -> backlog entry naming the missed trigger (rides existing backlog discipline)
- [x] S5d claude-md-sanity: cross-home contradiction check for shared-infra facts (fleet home recommendation stays user-owned; sanity only audits)
- [x] CHANGELOG (BEHAVIOR-CHANGE lines, one sentence each) + version 0.5.24; zero campaign.sh changes

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | yes | O(1) design of record (fable 3-lens + terminal, converged) + user approval |
| 0.5 plan recorded    | yes | ## plan above, materialized from spec S4/S5, updated per fix wave |
| 1 working-tree safety| yes | wt clean; 4b2e7a3 = origin tip |
| 2 re-validation      | skip | single open campaign — no overlap set |
| 2.5 reachability     | yes | skill-carried — arrives on plugin update; 4 BEHAVIOR-CHANGE lines relay (validator fixture-tested) |
| 3 quality gate       | yes | r1: 4 reviewers @5f14c25 → 8 findings → fixed; r2 @7c5b751 → 7 → fixed; r3 @4b2e7a3 → clean (full log in named section above). simplifier: not needed — prose-only release, ~200 net lines |
| 4 docs same-land     | yes | CHANGELOG relay-truth fixes were themselves r2's blocking finding — verified aligned with skill text; spec + backlog #12 same branch |
| 5 merge mechanics    | yes | base=main, squash 204b40d; anchor ff |
| 6 distill + hygiene  | yes | sanity: skip — diff touches skills/CHANGELOG only, lock-step verified x3 one line each (validator + r3), no new pointers introduced; memory updated same pass |
- [x] (implementer findings) spec cell-list abbreviation fixed (3 named cells); backlog #12 filed for the v0.6.0 pointer-narrowing follow-up

## convergence log (r2c format)
round 1: 4× (validator + 3 lenses: coherence/fidelity/field) @5f14c25 → 8 findings (row floor, cell-law conflict, check-8 guards ×3, verdict-race corrective, owner-bullet scope) → fixed @7c5b751
round 2: 1× scoped convergence agent @7c5b751 → 7 findings (1 BLOCKING: CHANGELOG relay carried the pre-fix contract — skill fixed but its describing line not; overflow propagation ×2; "single check" false; 2-loc MANUAL-CHECK shape; per-question exemption; step-6 parenthetical) → fixed @4b2e7a3
round 3: same agent @4b2e7a3 → clean pass (1 cosmetic nit logged: 130-char line, fold into future touch)
