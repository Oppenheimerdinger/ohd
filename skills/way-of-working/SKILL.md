---
name: way-of-working
description: This skill should be used when the user asks about the harness "way of working" / "작업 방식" / "어떤 도구를 써야", at project onboarding, or when unsure whether to produce (deep-solve), verify (review-to-convergence), review code (/code-review), run a workflow review, or set up a persistence loop. The routing layer of this plugin.
---

# Way of working

This harness has one design language: **interview-driven decisions, exactly one
recommendation per fork, honest gates over enforcement.** This skill is the
router — which tool, when.

## Quality routing

| Situation | Tool |
|---|---|
| The answer does not exist yet (unsolved problem) | `deep-solve` (it routes isolated/grounded internally) |
| A deliverable exists and must be checked | `review-to-convergence` |
| The deliverable is a code diff | `review-to-convergence`, using `/code-review` as the instrument |
| A creative/structural piece of work just completed | workflow review (below) |
| CLAUDE.md / memory hygiene check | `claude-md-sanity` |

**Workflow-review trigger (default, user-adjustable):** work where judgment
(not a single right answer) shaped the result — a new design, a new module, an
algorithm choice — gets a multi-agent workflow review when (a) it spans 3+
files or ~100+ lines of new logic, or (b) later work will build on top of it.
Below that, a single independent reviewer (review-to-convergence) suffices.
Run it as 2–3 independent fresh-context reviewers with distinct lenses (design
soundness, correctness, simplicity), each given the goal + the diff; reconcile
findings before banking.

## Two force-multipliers (defaults, not ad-hoc)

1. **Delegate with a verified brief.** A separable sub-problem with a definite
   right answer (derivation, root-cause, design tradeoff, algorithm) does not
   get ground through inline in a long, anchored context — write a
   self-contained brief and hand it to a fresh clean-context agent. The brief
   carries ONLY verified information: real numbers, real `file:line`; anything
   unverified is explicitly marked "unverified:" — never stated as fact. Invite
   the agent to challenge the premise. Withhold your tentative answer. (For the
   full unattended loop, escalate to `deep-solve`.)
2. **Review to convergence before banking.** Any substantive deliverable gets
   an independent fresh-context reviewer until a clean pass. Your confidence is
   not evidence; a fresh solver's isn't either — gate load-bearing answers on
   ground truth, not self-consistency. Compose the two: delegate to produce,
   independently review before adopting.

## Persistence loops — lightest thing that works

| Need | Reach for |
|---|---|
| Recurring run / polling | built-in `/loop` (zero install, self-pacing) |
| Scheduled / cron | built-in `schedule` |
| "Keep going until done" in-session | only then a persistence mode such as oh-my-claudecode's ralph — a heavy install with a known keyword-misfire history |

If ralph (or similar) is used: ① mentioning the word in a design conversation
can auto-register its state — a status question is not a task; cancel misfired
modes instead of "continuing" them. ② Cancel path: the mode's cancel command →
`--force` → if the stop hook STILL loops, look for state under the **current
repo's own `.omc/state/sessions/` (ls it — newest session dir) and remove the
misfired mode's state file** (state tools may resolve a different root). ③ An
autonomous loop always gets a termination condition and an iteration cap.

## Collaboration discipline

- **Git is the only truth.** Code moves between machines/agents by
  commit→push→pull only; no scp of repo files. Assume filesystems are NOT
  shared: when handing a file path to another machine or agent, include the
  file's content in the same message.
- **One scarce resource = one lane.** Serialize work on a scarce resource (a
  single GPU box, a license seat) into one lane and parallelize everything
  else; jobs on that lane are bounded (timeout), tracked, and cleaned up.
- **Idle ≠ dead.** A quiet worker is usually working. Require positive
  confirmation (git activity, a received message) before declaring an agent
  dead or killing its work.
- **Anchor + worktrees.** The session anchors at a stable trunk checkout;
  every unit of work is its own worktree+branch (see the campaign skills and
  `docs/campaign-dropin.md` for the lifecycle tooling).

## The superpowers flow

Creative work starts at brainstorming; multi-step work gets a written plan
(writing-plans) and subagent-driven execution; nothing is declared complete
without verification-before-completion. This is why superpowers is
required for the full workflow from v0.2 (see `/ohd-setup`).
