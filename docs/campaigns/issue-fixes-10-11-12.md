# campaign: issue-fixes-10-11-12
- goal: v0.5.21 — external issues #10 (flat wt root collision), #11 (sync discards body silently), #12 (checkup step-7 false hook claim)
- status: OPEN (2026-07-31)
- validation gate: suites green incl. new fixtures (per-project root derivation, sync backup); validator PASS; cr:cr on PR clean after fixes
- result / verdict: LANDS — merged as PR #13 (squash 819b5f1), tag v0.5.21
- follow-on: teardown-WARN smoke fixture (validator cosmetic); same-second backup clobber accepted (scripted-only path)

## plan
- [x] #10 campaign.sh ×2: config WT_ROOT default empties; body derives $HOME/wt/<repo-basename> after ROOT; teardown WARN when worktree survives removal
- [x] #11 checkup.sh sync: pre-sync backup + honest SYNCED wording (body-level customizations do not survive)
- [x] #12 ohd-checkup.md step 7: drop false "hooks allow tools/" claim; name the --no-verify+reason route, warn against widening ALLOW_RE
- [x] tests: derivation fixture (HOME=$TMP), backup fixture; full suites
- [x] CHANGELOG (BEHAVIOR-CHANGE ×3) + version 0.5.21; close #10/#11/#12 with comments after release

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | | |
| 0.5 plan recorded    | | |
| 1 working-tree safety| | |
| 2 re-validation      | | |
| 2.5 reachability     | | |
| 3 quality gate       | | |
| 4 docs same-land     | | |
| 5 merge mechanics    | | |
| 6 distill + hygiene  | | |
- [x] (review findings, added mid-campaign) --git-common-dir derivation + inside-worktree fixture; timestamped backup; dropin/step5/step7/header doc truth — reason: cr:cr B85/D100 + reporter's issue-thread correction (A75, C75, E75 folded in)

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | yes | user approval; 3 external issues w/ repros |
| 0.5 plan recorded    | yes | ## plan above, cut at open, updated once for review findings |
| 1 working-tree safety| yes | wt clean; 34d053e = origin tip pre-merge |
| 2 re-validation      | skip | single open campaign — no overlap set |
| 2.5 reachability     | yes | nothing gated; derivation/backup fire on next campaign.sh / --sync run |
| 3 quality gate       | yes | validator PASS ×2 (full + delta, 4-path worktree experiments); cr:cr PR#13 → 6 findings scored, B85/D100 posted, A/C/E folded, F rejected; fixed 34d053e; suites re-run green; simplifier: not needed |
| 4 docs same-land     | yes | CHANGELOG amendments bullet; dropin/step5/step7/header truth fixes in same PR |
| 5 merge mechanics    | yes | base=main, squash 819b5f1; anchor ff to origin/main |
| 6 distill + hygiene  | yes | lock-step untouched (agent-1); memory updated same pass |
