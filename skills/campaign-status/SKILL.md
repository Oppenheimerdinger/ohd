---
name: campaign-status
description: This skill should be used before claiming any branch/campaign is merged or unmerged, before pin/clean/re-run, or whenever a note asserts merge status — derives the verdict from git refs + the PR API, never from memory, and catches the squash-merge trap that fabricates phantom backlogs.
---

# Campaign status — merge-status is derived, never remembered

A note that says "pushed, awaiting merge" goes stale the moment someone
merges. Trusting it afterwards fabricates a phantom land backlog. **Merge
status is a property of the git graph + the PR API, not of any note** —
re-derive it every time. Never answer "is X merged?" from memory, a campaign
doc, or a memory file.

## The squash-merge trap

GitHub's default merge is a squash: it creates a NEW commit on trunk, so the
campaign branch is NOT an ancestor of trunk, and
`git merge-base --is-ancestor` returns false for a branch that is genuinely,
fully merged. Ancestry alone → false UNMERGED → phantom backlog.

**Verdict rule: MERGED = ancestry MERGED *or* a MERGED PR exists. UNMERGED
only when BOTH signals are negative and the branch still exists.**

## Reconciliation (parameterize BR / TRUNK)

```bash
BR=<branch> TRUNK=main
git fetch origin -q --prune                                   # prune stale refs

# 0) branch existence FIRST (avoid fatal → false UNMERGED)
git rev-parse -q --verify "origin/$BR" >/dev/null || echo "NO-BRANCH"

# 1) ancestry signal (catches ff/rebase merges; false for squash)
git merge-base --is-ancestor "origin/$BR" "origin/$TRUNK" && echo "MERGED (ancestry)"

# 2) PR-API signal (catches squash; baseRefName exposes the stacked trap)
gh pr list --head "$BR" --state all --json number,state,mergedAt,baseRefName

# 3) content-reach proof — only when signals disagree, or a MERGED PR has base≠trunk:
#    pick a token that exists ONLY in this campaign's diff, then
git show "origin/$TRUNK:<file>" | grep "<token>"
```

(`campaign.sh status <name>` runs 0–2 for you and prints the verdict.)

## Verdict table

| Signals | Verdict |
|---|---|
| ancestry true | MERGED |
| ancestry false, MERGED PR with base=trunk | MERGED (squash — confirm with step 3 if anything looks off) |
| ancestry false, MERGED PR with base≠trunk | STACKED — content is on the base, maybe not trunk; step 3 is mandatory |
| ancestry false, PRs only OPEN / CLOSED with mergedAt=null / none | UNMERGED — genuine, safe to land |
| origin branch absent | NO-BRANCH (cleaned post-merge, or never pushed) |

Rules: multiple PRs per head → MERGED if ANY is merged. A CLOSED PR with
`mergedAt: null` was closed WITHOUT merging — not merged. The step-3 token
must exist only in this campaign's diff, or the grep can false-positive.

## When to run

Before claiming a land backlog / "awaiting merge" / "needs landing"; before
`pin` (the dep branch must really be in the dep trunk) and before `clean`
(never delete an unmerged branch); before re-running or rebasing a campaign;
whenever any note asserts a merge status.
