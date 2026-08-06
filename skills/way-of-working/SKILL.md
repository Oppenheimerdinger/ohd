---
name: way-of-working
description: This skill should be used when the user asks about the harness "way of working" / "작업 방식" / "어떤 도구를 써야", at project onboarding, or when unsure whether to produce (deep-solve), verify (review-to-convergence), review a code diff (the code-review plugin or a review subagent), run a workflow review, or set up a persistence loop. The routing layer of this plugin.
---

# Way of working

This harness has one design language: **interview-driven decisions, exactly one
recommendation per fork, honest gates over enforcement.** This skill is the
router — which tool, when.

## Routing

| Situation | Tool |
|---|---|
| The answer does not exist yet (unsolved problem) | `deep-solve` (it routes isolated/grounded internally) |
| A deliverable exists and must be checked | `review-to-convergence` |
| The deliverable is a code diff | `review-to-convergence`; instrument = the code-review plugin (agents: `Skill(code-review:code-review)` on the PR — the bare `/code-review` built-in is user-only) or a review subagent |
| RISKY coding just completed (numerics, hot paths, code whose output experiments will trust) | the session may CHOOSE the heavy route on its own judgment — push the campaign branch, open a (draft) PR, run `Skill(code-review:code-review, <PR#>)` plus an independently-dispatched mutation/numerics reviewer, and loop fixes to a clean pass (r2c rules; the plugin runs once per PR — later rounds use subagents). Announce the choice in one line. Skipping it is fine for routine code — land Phase 3 remains the backstop |
| A creative/structural piece of work just completed | workflow review (below) |
| Landing/merging a campaign branch (incl. after push+PR) | `campaign-land` — re-load on EVERY land; never re-enact from memory |
| "Is X merged?" / before pin/clean/re-run / any note asserting merge status | `campaign-status` |
| CLAUDE.md / memory hygiene check | `claude-md-sanity` |
| The ohd plugin may have updated since session start | `/reload-plugins` (or restart) → `/ohd-checkup` per project — the session stays pinned to its start-time version otherwise (checkup reports `plugin-cache | STALE` when it can see this) |
| Starting a new research project | `/ohd-new-project` (interview-driven scaffolder) |
| Existing project: harness drift check / adoption ("하네스 점검") | `/ohd-checkup` (mechanical drift + CLAUDE.md wiring, repairs on approval) |
| Orientation: what exists, where, which interface, which route | read `docs/reference/` — NOT a subagent scan. Independence adds nothing to "does this pipeline exist"; tree archaeology only when the tier has no answer, and what you then learn graduates back into it at land (campaign-land Phase 4) |
| The corpus itself feels heavy (docs to archive, orphan probes, no reference tier) | `/ohd-checkup structure` — it GENERATES the work-list; executing it is ordinary project campaigns, and that cleanup is the reference tier's first fill |
| A campaign-scale ask (multi-day, several tasks) | draft the plan — plan mode or directly — and SAVE it into the campaign state doc's `## plan` section before starting; an approved plan left in chat evaporates at the next compaction. **Converge the plan (`review-to-convergence`) BEFORE execution begins** — a plan is the stage with the highest error-replication factor, and reviewing it before the approval gate means the user approves an already-reviewed plan. Then MATERIALIZE its items into the session task list (TaskCreate / todos) and track execution there, writing results back to the plan section as units complete: the plan section is the durable artifact, the task list the in-session tracker |
| Already implementing when you reach for SDD/TDD (late entry) | enter the discipline at the NEXT unit. Work already verified gets REVIEWED, never reverted to RED — destroying bitwise-verified work to restore discipline is TDD's iron law applied at the wrong moment (one field occurrence, the only observed failure here with a negative payoff) |

**Workflow-review trigger (default, user-adjustable):** work where judgment
(not a single right answer) shaped the result — a new design, a new module, an
algorithm choice — gets a multi-agent workflow review when (a) it spans 3+
files or ~100+ lines of new logic, or (b) later work will build on top of it.
Below that, a single independent reviewer (review-to-convergence) suffices.
Run it as 2–3 independent fresh-context reviewers with distinct lenses (design
soundness, correctness, simplicity), each given the goal + the diff; reconcile
findings before banking, and close on review-to-convergence's rule rather than
by adjudication: a final pass comes back clean, or every residual carries an
explicit ruling — r2c's recorded disposition, never the author's own fiat.

## Two force-multipliers (defaults, not ad-hoc)

1. **Delegate with a verified brief.** A separable sub-problem with a definite
   right answer (derivation, root-cause, design tradeoff, algorithm) does not
   get ground through inline in a long, anchored context — write a
   self-contained brief and hand it to a fresh clean-context agent. The brief
   carries ONLY verified information: real numbers, real `file:line`; anything
   unverified is explicitly marked "unverified:" — never stated as fact. Invite
   the agent to challenge the premise. Withhold your tentative answer. (For the
   full unattended loop, escalate to `deep-solve`.) Briefs carry POINTERS, not
   payloads — point at **`docs/reference/` FIRST** (capabilities and gotchas,
   conventions and invariants and the route map, the state registry: the
   project's present-tense truth, every line anchored to a test, gate or config
   the agent can RE-RUN), then the campaign state doc, then `file:line`,
   inlining only what has no home. Orientation is a LOOKUP: a brief that
   inlines what the tier already holds pays for the same knowledge in every
   dispatch, and one that omits the pointer sends a fresh agent to re-derive it
   from the tree. And a fan-out wider than the situational default needs ONE stated
   reason line in the dispatch message. A sweep that becomes root-cause
   REASONING is two dispatches: the sweep, then a reasoning agent briefed on
   its findings — one agent when the sweep is trivial.
2. **Review to convergence before banking.** Any substantive deliverable gets
   an independent fresh-context reviewer until a clean pass. Your confidence is
   not evidence; a fresh solver's isn't either — gate load-bearing answers on
   ground truth, not self-consistency. Compose the two: delegate to produce,
   independently review before adopting.

## Who does the work — the delegation boundary

The main session writing everything is a physics problem before a discipline
problem: everything it writes stays resident in its context, accelerating
compaction — and long contexts are where turns die on promises. Delegation
is context outsourcing. But delegating a 3-line edit costs more than the
edit; the boundary:

| Work | Who | Vehicle |
|---|---|---|
| Micro-edit — a STANDALONE fix outside any plan or dispatched task, sized by the WORK not the diff: it is NOT a micro-edit if it writes a new test, needs a mutation or negative control, or needs a gate run to judge it | main session directly | — (delegation would cost more) |
| Any step of a written plan's implementation task, regardless of size | fresh implementer per task | superpowers:subagent-driven-development |
| Shell/filesystem INVESTIGATION — enumerating, measuring, censusing, grepping across a tree (a measured session spent 66% of its coordinator tool calls on Bash) | a read-only sweep subagent | `Explore` is the named vehicle — it reads excerpts, not whole files; model tier is an explicit lever (a mechanical sweep does not need the top model) |
| Bulk writing (docs, reports, large generated text) | a writer/executor subagent | Agent tool (oh-my-claudecode's tiered `writer`/`executor` roster, when installed) |
| Separable hard reasoning | fresh agent with a verified brief | force-multiplier 1, escalating to `deep-solve` |
| Must-complete long-running work | a persistence loop (independent evaluator judges termination — below) | `/loop` / schedule / ralph |
| Independent parallelizable tasks | a subagent fleet, dispatched in one message | superpowers:dispatching-parallel-agents |

Row 1's disqualifiers are a FLOOR, not a factor to be weighed: work that writes
a new test, needs a mutation or negative control, or needs a gate run to judge
it is not a micro-edit at any cost ratio. Once they pass, weigh the actual
costs: if writing the brief plus reading and verifying the reply costs more
than just doing the work, do it directly — row 1's case, and the investigation
row's too: one command answered in one breath stays inline, since that row is
for SWEEPS, not one-liners. The exemption is per QUESTION, not per command: a
RUN of one-liners in service of ONE question IS a sweep — dispatch it, or the
row's evidence (coordinator Bash call-share) is satisfied away one breath at a
time. Otherwise delegate — the output then lives in the subagent's context,
not yours.

Inside an open campaign the default is that an edit belongs to the plan —
"standalone" is a claim you support by pointing at the plan section, not the
fallback when no plan exists (no plan line yet = the signal to write one, not
a license to edit). An exploratory campaign whose plan is a one-line
next-probe has dispatched nothing: the probe belongs to that plan, so what
decides is row 1's DISQUALIFIERS rather than the standalone test — and the
probe's result gets written back into the plan line (writing that result is
analysis, not a code edit).

## Campaign sizing — a campaign is ONE coherent increment

The land is the harness's reset: it forces the session's knowledge into
artifacts (state doc, distill, report), re-sharpens review (small diffs
review sharply; review bluntness grows superlinearly with diff size), and
restores trunk as truth. Long-lived worktrees and sessions drift — the
field observation behind this rule.

- **Size at the start**: big work decomposes BEFORE campaigns exist —
  brainstorming and writing-plans already carry the scope checks (their
  rule: each sub-plan yields independently working, testable software).
  **One sub-plan = one campaign = one land.** Open campaigns cut to the
  increment you intend to land, not to the whole ambition. Work that arrives
  WITHOUT that decomposition — most exploratory research — is sized here
  instead, and its plan is the state doc's `## plan` section (below).
- **Plans are layered by volatility**: direction (roadmap doc, stable) →
  campaign (the state doc's `## plan` section — living, and TRUNK-owned like
  the rest of that doc: edited at the anchor, never on the campaign branch) →
  task (frozen brief via writing-plans/SDD; a dispatched brief never mutates
  — kill the task and cut a new one). Depth follows certainty: known stretch
  = task checkboxes; unknown stretch = ONE line, next probe + decision rule —
  replanning is then cheap and normal (edit the line, add a one-line reason).
  A plan line that turns implementation-shaped gets a plan FILE cut by
  writing-plans and becomes a pointer to it — the plan section itself is
  never an SDD plan file (it lives on trunk, outside the worktree SDD runs
  in). And a gate demanding a plan you don't have means you entered from the
  wrong end: do not backfill — stop and write the honest plan line first.
- **The land signal is state, not calendar**: the moment you catch yourself
  stacking the NEXT increment on top of already-validated work, land first.
  Batching related commits into one coherent increment is normal; one
  campaign absorbing several distinct increments is the anti-pattern.
- **Small lands run lean, legitimately**: land-report skip rows exist for
  exactly this — no overlap → Phase 2 skip; no docs/CLAUDE.md/memory
  touched → Phase 6 sanity skip (campaign-land names both conditions).
  Review depth and re-validation scope scale with the diff; the ritual's
  FIXED overhead (skill reload, report scaffold, merge mechanics) does not
  — land often enough to keep review sharp, not so often that the fixed
  tax dominates.
- **When a campaign HAS dragged**: land the validated core (campaign-land
  Phase 0's partial-land rule), open a follow-on campaign, and prefer a
  fresh session on the far side — the reset is most valuable exactly when
  it feels hardest to stop.

## Persistence loops — lightest thing that works

| Need | Reach for |
|---|---|
| Recurring run / polling | built-in `/loop` (zero install, self-pacing) |
| Scheduled / cron | built-in `schedule` |
| "Keep going until done" in-session | the official **ralph-loop** plugin (installed by /ohd-setup); oh-my-claudecode's ralph also works — heavier, with a known keyword-misfire history |

**An autonomous mandate means a loop, FIRST.** When the user hands over
unattended completion ("자율로 완수해", "run this to the end while I'm
away"), the session's FIRST action is to set up the persistence loop it
will run under (pick from the table above — for must-complete work that is
the official ralph-loop plugin, or oh-my-claudecode's ralph) before
touching the work itself.
A bare session under an autonomous mandate dies silently at its first
promise-ending turn — three field occurrences, and no prose reminder has
ever prevented one. The user can verify compliance at a glance: the first
visible action after granting autonomy is loop setup, or the session is
not running autonomously. The ohd:autonomous-mandate skill carries the
trigger phrases and the setup procedure — it fires on the mandate wording
itself ("자율진행", "자율로 완수해"), not on this paragraph being read.

**Loop termination is judged by an independent evaluator agent, never by the
looping session itself** — a session grading its own loop quits (or declares
victory) far too easily. The evaluator gets the goal + concrete evidence and
returns done / not-done with reasons. **The verdict is an artifact**: a loop
may only be declared finished by quoting the evaluator's verdict verbatim
(who evaluated, what evidence it saw, done/not-done, reasons) AND appending
that quote to the loop's own state/notes file — chat scrolls away, and loops
are exactly the workloads that outlive the attention span of whoever started
them. No quoted verdict = the loop is not done — "the evaluator would agree"
is the looping session grading itself with extra steps — and so is
DELETING the loop's state file (a looping session never cancels its own
loop; cancellation is the user's).

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
- **An owner correction to the session's PROCESS is a trigger failure.** When
  the owner corrects HOW the session works (not what it concluded), a trigger
  that should have fired didn't — file a backlog entry naming that missing
  trigger in the project's `docs/backlog.md` in the same pass (campaign-land
  Phase 6's discipline); the metric is corrections-per-week, read per project.
- **The coordinator seat does not solve inline.** A long-lived anchor
  session's job is orchestration; minutes-long inline reasoning there is a
  solver's job in the wrong seat — write the brief and hand it to a fresh
  agent (force-multiplier 1, escalating to deep-solve), or a persistence
  loop for must-finish work. Long inline thinking in a long context is also
  where turns die on promises (below).
- **End turns on evidence or a question — never on a promise.** "I'll
  continue" as a final line ENDS the turn; absent an explicit persistence
  loop, nothing resumes a session that promised instead of acted. If the closing paragraph announces work not yet
  done, do that work now (tool calls), then report. (A silent stall despite
  acting is a known upstream bug — any user message resumes it; that class
  is not yours to fix.)
- **Anchor + worktrees.** The session anchors at a stable trunk checkout;
  every unit of work is its own worktree+branch (see the campaign skills and
  `docs/campaign-dropin.md` for the lifecycle tooling). **The anchor itself
  is a scarce resource**: concurrent sessions are normal, but trunk WRITES
  (docs commits, merges, resets — git staging is shared) are one lane, the
  coordinator's; everyone else treats the anchor read-only and drives their
  own worktree.
- **Memory is the machine-local buffer; git is the durable tier.** Auto-memory
  is keyed to this machine and this anchor path — a fact that another machine,
  person, or agent will need is MISPLACED the moment it lands only in memory;
  put it in the repo (CLAUDE.md, docs, the campaign state doc). Land-time
  distill (campaign-land Phase 6) is the graduation path. Parallel-session
  hygiene: re-read `MEMORY.md` from disk before adding an index line (one-line
  edit, never full-file rewrite), and re-read a memory file before basing a
  load-bearing decision on it — your session-start copy ages while other
  sessions write.

## The superpowers flow

Creative work starts at brainstorming; multi-step work gets a written plan
(writing-plans) and subagent-driven execution; nothing is declared complete
without verification-before-completion. Model choice for SDD's final
whole-branch review follows the same risk scaling as every other review —
reserve the top model for risky or complex branches instead of defaulting to
it (a routine branch's final review on a mid-tier model is not a corner cut). **Completed implementation is itself
a deliverable**: subagent-driven execution's final whole-branch review covers
it, and work built outside that flow gets its own explicit
review-to-convergence pass. But being INSIDE the flow is not an exemption, on
two counts. **(i) The spec and the plan are reviewed by their AUTHOR only** —
writing-plans says so verbatim ("a checklist you run yourself — not a subagent
dispatch") and brainstorming's spec self-review is likewise author-run ("look
at it with fresh eyes… Fix any issues inline. No need to re-review") — so each
gets an independent r2c pass before execution begins. **(ii) SDD's own review loop terminates on ADJUDICATION, not on a clean
pass** ("there is no second fix wave — residual load-bearing findings surface to
your human partner"), so r2c supplies the stopping rule it lacks: the last round
comes back clean, or every residual carries an explicit ruling — r2c's recorded
disposition — in the state doc. The instrument stays SDD's own reviewer — this
adds no tool, only a termination condition — and it binds hardest under an unattended mandate, where
the "surface to your human partner" exit does not exist. A completion claim NAMES its review pass (what
reviewed it, verdict) — a claim that names none is unreviewed work, whatever
its confidence. This is why superpowers is
required for the full workflow from v0.2 (see `/ohd-setup`).
