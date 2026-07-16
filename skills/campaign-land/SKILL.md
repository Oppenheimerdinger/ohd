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

## Phase 2.5 — reachability / graduation (dormant-feature guard)

"Merged" is not "enabled." Optimized or new code that ships behind a flag,
env gate, or non-default config can land cleanly and then NEVER RUN — the
classic silent waste: someone pulls trunk, runs the default path, and the
work they were waiting for isn't engaged.

- If the work shipped gated (flag/env/config), **graduation to default-ON
  happens AS PART OF this land** — the gate is demoted to a kill-switch, not
  left as an opt-in. "Graduate later" = dormant feature; it does not happen.
- If it deliberately stays gated (genuinely experimental), say so explicitly
  in the state doc — a conscious exception, not a default.
- **Positively assert the new path fires post-merge**: a smoke run, log line,
  or counter that proves the landed code actually executes on the default
  path. Pulling on another machine? Same assertion there before trusting it.

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

## Land report — MANDATORY gate before Phase 7

Skipping a mandated phase by rationalizing is the known failure mode of this
skill ("the whole-branch review already covers Phase 3", "low-risk, skip
sanity"). Rules that live only as prose get skipped; artifacts don't. So:

**Before any Phase-7 cleanup, print the land report table:**

```
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | yes/skip | <command or output ref> |
| 1 working-tree safety| yes/skip | ... |
| 2 re-validation      | yes/skip | ... |
| 2.5 reachability     | yes/skip | ... |
| 3 quality gate       | yes/skip | ... |
| 4 docs same-land     | yes/skip | ... |
| 5 merge mechanics    | yes/skip | ... |
| 6 distill + hygiene  | yes/skip | ... |
```

- `evidence` must reference something that actually happened this land — a
  command you ran, an output you saw, a diff/commit hash. An empty or vague
  evidence cell means the phase DID NOT HAPPEN — go run it.
- **Substitution rationales are invalid.** A review that happened during
  implementation does not satisfy Phase 3 (it saw a different, earlier tree).
  "Low risk" is not an exemption. The ONLY valid `skip` rows are conditions
  this skill itself names (e.g. "no dependent-repo pin", "single campaign —
  no overlap", "nothing gated — 2.5 trivially clean"), and the skip row must
  quote that condition as its evidence.
- Phase 7 deletes branches and worktrees — it is the point of no return. A
  land with a missing or hand-waved report row is not ready to clean.

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
