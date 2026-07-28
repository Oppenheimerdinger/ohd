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

An **independent** review of the final diff — independent meaning it did not
write the code, and it sees the final combined diff, not an earlier snapshot
from implementation. Fix real findings; **re-run the checks after any fix —
never claim "fixed" without re-running** (see
superpowers:verification-before-completion).

Three routes, in preference order:

- **The official code-review plugin (agent-invocable — the default route).**
  The land's push+PR already exists, so invoke
  `Skill(code-review:code-review, args: <PR number>)` — the NAMESPACED form.
  ⚠ The bare `/code-review` name resolves to a Claude Code BUILT-IN marked
  `disable-model-invocation` — an agent calling that form gets refused; do not
  conclude from that refusal that no agent route exists. Requires
  `code-review@claude-plugins-official` (checked by `/ohd-setup`).
- **User-run `/code-review`** — the built-in, fine in an attended session; the
  user runs it, the agent cannot.
- **A review subagent** — fallback when the plugin is absent or there is no
  PR. Dispatch one scoped to the final diff: give it the diff range, the
  files, and the *claims the campaign doc makes*, and ask it to check the
  claims against the diff. Findings that came back this way in the field:
  tests that could not fail, a "fix" that was a provable no-op, and a `[x]`
  on a phase that delivered one of its three required parts.

Whichever route, the report row names it (`code-review:code-review PR#n` /
`/code-review (user)` / `review subagent: <type>`) AND carries the normal
evidence — findings count and disposition, or the review output ref. The
route name alone is a label, not evidence.

**Ask the reviewer to run mutations, not just read.** A passing test suite
says nothing about whether the tests *can* fail. The highest-value reviews in
practice mutated the code (flip a sign, swap `.mH`→`.mT`, replace a variance
with a component-wise one) and reported which tests caught each one — plus a
no-op control to prove the harness was live. Mutation results go in the same
report row's evidence cell (`mutations: N tried / caught / no-op control ok`)
— unrecorded mutations are the prose-only rule this skill says gets skipped.

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
sanity"). Rules that live only as prose get skipped; artifacts don't. Two
field recurrences proved a chat-printed table gates nothing — so:

**The land report lives IN the state doc (`docs/campaigns/<name>.md`), not in
chat.** Scaffold it with `campaign.sh land <name> --report` (appends the blank
table); `campaign.sh land` REFUSES to push without it, and Phase-7 cleanup
still requires the filled verdict line. Fill rows as phases complete:

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

**Re-load this skill from file on EVERY land.** Re-enacting the phases from a
previous land's memory is itself a violation — both field recurrences began
exactly that way (the second one with the rule already written in memory;
memory is a soft layer, the script gate is the backstop).

- `evidence` must reference something that actually happened this land — a
  command you ran, an output you saw, a diff/commit hash. An empty or vague
  evidence cell means the phase DID NOT HAPPEN — go run it.
- **Substitution rationales are invalid.** A review that happened during
  implementation does not satisfy Phase 3 (it saw a different, earlier tree).
  "Low risk" is not an exemption. (A review **subagent** on the final diff is
  not a substitution — it is one of the two named routes in Phase 3.) The ONLY valid `skip` rows are conditions
  this skill itself names (e.g. "no dependent-repo pin", "single campaign —
  no overlap", "nothing gated — 2.5 trivially clean"), and the skip row must
  quote that condition as its evidence.
- Phase 7 deletes branches and worktrees — it is the point of no return. A
  land with a missing or hand-waved report row is not ready to clean.

## Phase 7 — cleanup (only after ALL PRs merged)

`campaign.sh clean <name>` (verifies merge AND a filled verdict/result line in
the state doc before deleting — Phase 4's on-disk artifact; `FORCE_CLEAN=1`
bypasses) — or manually:
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
