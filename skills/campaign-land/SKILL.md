---
name: campaign-land
description: This skill should be used when the user says "land the campaign" / "캠페인 land" / "merge to trunk" / "ship it", or a validated worktree branch is ready to reach a protected trunk. Encodes the land ritual and the trunk-merge gotchas (stacked PR, squash, living-doc conflicts).
---

# Campaign land

Landing takes a validated campaign branch from push+PR to merged-trunk +
cleaned-up, without the silent failure modes that bite this workflow. Workers
stop at `land` (push + PR); **merging is the anchored coordinator's job** —
unless the project uses the review-gate model, where merge happens on GitHub
after review and the session stops at the PR.

If the project has a lifecycle CLI (`tools/campaign.sh` — see
`docs/campaign-dropin.md`), use it; every phase below also lists the raw
commands so the ritual works without it.

## Phase 0 — preconditions (don't start a land that isn't ready)

- Validation gate GREEN with evidence you can point to. Partly validated →
  land ONLY the validated part; keep the rest as a documented follow-on and
  say so explicitly.
- A trunk merge is consequential: if unsure, surface the land plan to the user
  and get a go before merging.

## Phase 1 — working-tree safety

Every branch in every repo committed AND pushed: per worktree,
`git -C <wt> status` clean and `git -C <wt> log --oneline origin/<br>..HEAD`
empty. Single-copy worktrees are single points of failure — an unpushed commit
is one `reset --hard` away from gone. **Commit and push anchor/docs edits
BEFORE any `reset --hard`** (the post-merge refresh wipes the working tree).

## Phase 2 — overlap-aware re-validation

A campaign's validation holds against its own base, not post-merge trunk.
Compare its touched files/paths against everything landed since its base:
**disjoint → merge in any order, no re-validation; overlapping → after the
merge, re-run this campaign's validation against the new trunk — but only the
conflict set, not a blanket full pass.**
Raw overlap check: `comm -12 <(git diff --name-only <base>...origin/<trunk> | sort) <(git diff --name-only <base>...HEAD | sort)` — empty output = disjoint.

## Phase 3 — quality gate on the diff

Run `/code-review` on the final diff; fix real findings; **re-run the checks
after any fix — never claim "fixed" without re-running** (see
superpowers:verification-before-completion).

## Phase 4 — docs in the SAME land

Living documents drift silently unless updated in the same PR/merge: update
the campaign state doc (final RESULT / VERDICT / follow-on) and any living map
the change touches, now — not "later".

## Phase 5 — PR merge mechanics (the gotchas)

- ⚠ **Stacked-PR base check**: `gh pr view <n> --json baseRefName`. A PR whose
  base ≠ trunk merges into its base — `gh pr merge` reports MERGED while trunk
  never receives the content. Re-target to trunk first; afterwards verify a
  head-unique file actually reached `origin/<trunk>`.
- ⚠ **Server-side merges leave local trunk stale**: after `gh pr merge`, run
  `git fetch origin <trunk> && git reset --hard origin/<trunk>` before doing
  anything else locally (Phase 1 rule applies before this reset).
- ⚠ **Sequential lands conflict on living/append-only docs**: resolve as
  UNION — merge `origin/<trunk>` INTO the branch (never force-push), keep all
  rows from both sides.
- Merge promptly as each campaign becomes ready; don't batch.

## Phase 6 — distill + hygiene

- Record NON-obvious lessons (the gotcha, the why, the measurement) in
  memory/docs — not what git already says.
- **Never write merge-status as a bare fact**: phrase as verify-on-read ("as
  of <date> pushed NOT merged — re-derive, don't trust this line") and flip it
  to MERGED in the same pass as the merge. Stale status notes fabricate
  phantom backlogs — `campaign-status` is the re-derivation tool.
- Run `claude-md-sanity` at land time (dangling pointers, half-landed
  lock-steps).

## Phase 7 — cleanup (only after ALL PRs merged)

`campaign.sh clean <name>` (verifies merge before deleting) — or manually:
verify with the campaign-status verdict first, then remove worktree + local +
remote branch: `git worktree remove <wt> && git branch -D <br> && git push origin --delete <br> && git worktree prune`.
Whoever spawned the worktree owns its teardown. ⚠ Parallel
processes with identical argv can't be targeted by `pkill -f` (it kills both)
— sweep by PID.

## Multi-campaign lands

Group by overlap: disjoint groups land in any order; overlapping stacks land
base-first, re-validating each subsequent campaign against the new trunk. Hold
merges until in-flight background validation has written its completion
marker.

## Dependent-repo pin (only if the project has one)

A campaign that also changed a pinned dependent/fork repo merges in strict
order: dependent PR first → bump the pin (`campaign.sh pin <name>` updates the
PIN line to the merged dep-trunk SHA) → this repo's PR → clean.
Raw path: after verifying the dep branch merged (campaign-status), set the PIN line to `git -C <dep> rev-parse origin/<dep-trunk>`, commit (the trunk hook may require --no-verify for a non-docs file), push.

## What this skill does NOT do

It does not judge whether the work is correct (that's the validation gate),
will not merge a base≠trunk PR without re-targeting, will not pin to an
unmerged SHA, and will not land a result nobody has seen. When in doubt,
surface the plan and get a go.
