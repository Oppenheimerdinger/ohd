# campaign: normalization
- goal: v0.5.23 — the normalization bundle per docs/superpowers/specs/2026-07-31-normalization-design.md (APPROVED by 3-lens review; plan converged there — this section materializes it)
- status: OPEN (2026-07-31)
- validation gate: all suites green; validator PASS; cr:cr on the PR; convergence log ends clean (the new Phase-3 contract, applied to its own release)
- result / verdict: LANDS — merged as PR #17 (squash a9085fa), tag v0.5.23; 5-round convergence ending clean, no finding left undisposed
- follow-on: post-ship probe in ~1 month — re-count "clean pass" (baseline 1/365) and r2c-named docs (7/365); fleet reload + /ohd-checkup relays 6 BEHAVIOR-CHANGE lines; hook STALE rows expected on 3 adopted projects

## plan
- [x] 1 r2c description: act-scoped rewrite (~50w, negative clause, "wraps code-review; never replaces it")
- [x] 1b routing row clause: converge plan before execution + materialize into task list; results flow back
- [x] 2 way-of-working superpowers-flow: spec/plan get r2c (author-only self-review upstream); SDD termination rule = r2c clean-or-ruled (lock-step phrase untouched, single line)
- [x] 4 micro-edit row re-cut to work-size disqualifiers (one line in, one line out)
- [x] 5 autonomous-mandate: DELETE "work you did directly this turn" from ADVANCE; lane rule + review-naming into the loop-prompt template (step-2 code block); 2 evaluator questions (step 3)
- [x] 6 campaign-land Phase 3: convergence log (round|reviewer|SHA, ends clean or explicit rulings; round N+1 SHA != N) + simplifier "not needed" needs a reason
- [x] 6b campaign-land Phase 6: evidence cell must contain sanity: findings-or-skip-with-diff-artifact
- [x] 7 routing row: late entry into SDD/TDD -> enter at the NEXT unit; verified work is reviewed, never reverted
- [x] 8 install-hooks.sh version stamp + checkup.sh version-detect (legacy hook without stamp -> STALE row offering re-install)
- [x] tests: checkup-smoke fixture for the hook STALE branch; suites green
- [x] CHANGELOG (BEHAVIOR-CHANGE lines; state plainly items 1/2/6 are ONE intervention across three surfaces) + baselines for the post-ship probe ("clean pass" 1/365, r2c named 7/365) + version 0.5.23

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | yes | design of record (3-lens converged) + user 정상화 approval |
| 0.5 plan recorded    | yes | ## plan above — materialized from the converged spec at open, updated per fix wave |
| 1 working-tree safety| yes | wt clean; d41bb78 = origin tip |
| 2 re-validation      | skip | single open campaign — no overlap set |
| 2.5 reachability     | yes | skills reach via plugin update; hook stamp reaches via checkup STALE/AHEAD rows; 6 BEHAVIOR-CHANGE lines relay (validator-tested) |
| 3 quality gate       | yes | convergence log above — r1 6-reviewer 17 findings, r2 6, r3 clean-with-logged-disposition; simplifier: not needed — instruction-text release, no code beyond the hook check |
| 4 docs same-land     | yes | CHANGELOG (6 one-sentence BC lines + baselines), spec doc truth-synced, backlog untouched |
| 5 merge mechanics    | yes | base=main, squash a9085fa; anchor ff |
| 6 distill + hygiene  | yes | sanity: 1 finding — lock-step verified 3 files/1 line each as part of validator run, no dangling pointers introduced (skills renamed nothing); disposition: clean. memory updated same pass |
- [x] (implementer rulings, mid-campaign) round-SHA parser SKIPPED — contradicts campaign-land's free-form row contract (spec corrected); escalation rule moved to r2c body; 6 BEHAVIOR-CHANGE lines
- [x] (review fix waves) r2 17 findings fixed @7064ad9 (1 code: directional hook check; 16 text); r3 6 findings fixed @d41bb78 (r2c owns the ruling vocabulary)

## convergence log (per the Phase-3 contract this release ships)
round 1: 6× (validator + 5 lenses) @2d0fee8 → 17 findings → fixed
round 2: 1× independent convergence agent @7064ad9 → 6 findings (2 substantive) → fixed
round 3: maintainer mechanical verification of reviewer-prescribed fixes @d41bb78 → clean-by-transcription (interim; reviewer agent died on weekly limit — superseded by round 4)
round 4: 1× independent fresh-eyes verifier @d41bb78 → 2 findings (F2 structurally half-closed: r2c lacked the OR branch five surfaces cited, with a convergence-deadlock repro; uphold polarity flip) → fixed @e3c41db per the reviewer's own prescriptions
round 5: same verifier @e3c41db → four criteria met, 1 nit (L30 lone non-disjunctive holdout) → fixed @4e46a43 (four words, the reviewer's exact prescription) — terminal: clean, no finding left undisposed
