# campaign: plan-layers
- goal: encode the planning-layers doctrine (v0.5.20) — campaign plan section in the state doc scaffold, land-report 0.5 row, verdict-grep anchoring, delegation-license inversion — per the 3-lens design review (minimal/efficacy/coherence)
- status: OPEN (2026-07-31)
- validation gate: node tests + both smoke suites green (incl. new regex fixtures); plugin-validator PASS; code-review:code-review on the PR clean after fixes; release greps clean
- result / verdict: LANDS — merged as PR #9 (squash 1043d95), tag v0.5.20
- follow-on: measure plan-section fill rate next cycle (baseline 6% = 33/522, grep -lc '^## plan' docs/campaigns/*.md per project); escalate to a land die-gate only if the rate stalls near the 38% scaffold band

## plan
- [x] campaign.sh ×2 (parity): `## plan` scaffold (3 lines, heredoc-safe), land-report `0.5 plan recorded` row, clean-gate verdict regex anchored to bullet lines
- [x] checkup.sh: land-reports audit regexes anchored the same way
- [x] way-of-working: routing row (save plan into state doc), delegation rows 1–2 re-cut on one axis + inverted default paragraph, campaign-sizing layering bullet (trunk-lane, plan-file pointer, backfill prohibition), sub-plan reconciliation sentence; superpowers-flow section untouched (lock-step phrase)
- [x] campaign-land: 0.5 row in the report table + one gloss sentence
- [x] tests: fixtures proving a plan-section `result:` line defeats neither the clean gate nor checkup's audit; full suites re-run
- [x] CHANGELOG (BEHAVIOR-CHANGE ×3 + baseline 6% = 33/522 measurement) + version 0.5.20

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | yes | design 3-lens review before impl; user go 2026-07-31 |
| 0.5 plan recorded    | yes | ## plan above, cut at campaign open, updated once mid-campaign (review finding) |
| 1 working-tree safety| yes | wt clean; branch pushed (ba2ec7e = origin/plan-layers) |
| 2 re-validation      | skip | single open campaign — no overlap set |
| 2.5 reachability     | yes | nothing gated; scaffold/regex fire on next campaign.sh run; checkup syncs assets on next /ohd-checkup |
| 3 quality gate       | yes | plugin-validator PASS (7 checks); code-review:code-review PR#9 → 1 confirmed finding (85), fixed ba2ec7e, suites re-run green; simplifier: not needed (review found no over-complexity) |
| 4 docs same-land     | yes | CHANGELOG v0.5.20 + residuals in same PR; state doc updated now |
| 5 merge mechanics    | yes | base=main, squash 1043d95; anchor ff to origin/main |
| 6 distill + hygiene  | yes | lock-step phrase verified in 3 files (validator #4); memory ohd-plugin.md updated same pass |
- [x] (review finding, added mid-campaign) bare-word verdict branch position-anchored + fixtures — reason: cr:cr reproduced a clean-gate bypass via a plan bullet containing LANDED
