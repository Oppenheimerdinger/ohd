# v0.5.23 "normalization" — design of record

Status: APPROVED (three-lens design review, 2026-07-31). Implementation pending
v0.5.22 landing (overlapping files).

## The question this answers

Do research sessions running under this harness (a) write a plan before working,
(b) delegate implementation to agents, (c) use superpowers properly, and (d) run
review-to-convergence on deliverables?

Measured before this release, over a corpus of 365 unique campaign state docs
(after de-duplicating worktree checkouts and one stale duplicate clone):

| behavior | state | evidence |
|---|---|---|
| (a) plan first | WORKS | 13 docs carry the `## plan` scaffold, 13/13 non-empty, 11/13 written before the work; two of those record their own decision rules resolving as predicted |
| (b) delegate | FAILS | one field session: 1 of 7 work units delegated |
| (c) superpowers | FAILS | entered SDD from the wrong end, began backfilling a plan, and on correction reverted bitwise-verified work to restart at TDD RED |
| (d) r2c | HALF-FAILS | reviewers are reached constantly (`code-review` named in 158 docs), but "clean pass" appears in **1** doc of 365 |

The diagnosis is three layers: the process is never REACHED (process skills are
named after methodology, so intent vocabulary misses them); the delegation
decision is SELF-APPROVED against a criterion that measures diff size rather
than work size; and everything is checked AFTER the fact (plan at land,
convergence never).

## What ships

**1 — `review-to-convergence` description re-aimed at the ACT, not the topic.**
Trigger on being about to dispatch a reviewer, hand off a deliverable, or call
something done — especially right after fixing findings — with an explicit
negative clause excluding discussing/reading/routing reviews, and the line
"wraps code-review; never replaces it" (the corpus shows r2c DISPLACING the
review instrument in 3 of ~15 firings). Under the ~50-word budget; the current
description is 76 words, so this is a convention repair, not growth.
Rationale for act-scoping: a topic-word trigger fires on every conversation
*about* review — including the harness's own maintenance sessions, where it was
observed misfiring live.

**1b — plan-mode sequencing (field-discovered by the owner, folded into items
1 and 2 rather than added as an item).** The strongest observed pattern:
enter plan mode, draft, CONVERGE THE PLAN (r2c) before the approval gate, then
save the approved plan into the state doc's plan section and execute. The user
then approves an already-reviewed plan — review happens before the approval
gate consumes their attention, at the pipeline stage with the highest error
replication factor. Encoding: one clause on the existing campaign-scale
routing row ("converge it before execution begins, then materialize its items
into the session task list — TaskCreate/todos — and track execution there,
writing results back to the plan section as units complete"); the r2c
description's "plan 다 썼다" trigger covers the moment. The task-list half
rides a NATIVE surface: the harness already nags about task tools via system
reminders, and SDD's own first step is "create todos" — this extends the same
move to non-SDD campaign execution. Division of labor: the plan section is
the durable artifact (survives the session), the task list is the in-session
execution tracker (visible progress, reminder-revived). Instrument stays free — the field
observation is that instrument selection self-organizes and only the MOMENTS
need naming; cr:cr stays forced at land Phase 3 only.

**2 — the superpowers-flow sentence stops granting a blanket exemption.**
Today it says anything built OUTSIDE the flow gets r2c, which reads as "inside
is covered". Two corrections: spec and plan are reviewed by their authors only
(both superpowers skills say so verbatim — "a checklist you run yourself, not a
subagent dispatch"), so they get r2c before execution; and SDD's own review loop
terminates on ADJUDICATION, not on a clean pass ("there is no second fix wave —
residual load-bearing findings surface to your human partner"). r2c supplies the
termination rule SDD lacks: **the last round must come back clean, or every
residual carries an explicit ruling recorded in the state doc.** The instrument
stays SDD's own reviewer — this adds no tool, only a stopping condition.
Under an unattended mandate the "surface to your human partner" exit does not
exist, which is why this matters most exactly where nobody is watching.

**4 — the micro-edit criterion moves from diff size to work size.** It is not a
micro-edit if it writes a new test, needs a mutation/negative control, or needs
a gate run to judge it. One line in, one line out. The criterion is
operationally answerable by the session ("am I writing a new test?" is yes/no,
"is this standalone?" is judgment) — but note the existing rule was already
correct and was quoted by the violating session *while* it was violated, so the
table row is not expected to carry the behavior. The same disqualifiers ride
item 5's loop prompt, which is where they are expected to fire.

**5 — the persistence-loop lane rule, delivered where a loop re-injects it.**
The autonomous-mandate skill currently lists "work you did directly this turn"
as a legitimate way to have ADVANCED the mandate — i.e. a coordinator that did
everything itself was in full compliance with the skill as written. Delete that
clause (dispatch and backgrounded watch remain), and add the lane question to
the LOOP PROMPT the skill already writes: the loop's stop hook re-injects that
prompt verbatim every iteration, so it survives compaction and context rollover,
which skill bodies do not. Two questions also join the mandatory
termination-evaluator brief: which work units were delegated versus done by the
coordinator, and does every deliverable claimed done name the review pass that
cleared it. The evaluator's verdict is already quoted verbatim into the state
doc, so an omission is visible afterwards.

**6 — convergence becomes a falsifiable artifact at land.** The land report's
Phase 3 evidence cell must carry r2c's round log — per round, the reviewer and
the SHA that round reviewed — ending in a clean round. Mechanical corroboration:
round N+1's SHA must differ from round N's (re-reviewing the same tree is not a
round), checked in the teardown command that already greps the same document.
No scaling by diff size: the regression that motivated this had ONE finding on a
small diff. This does not impose a new practice — 25 of 68 filled Phase-3 rows
already record a second look, in a dozen ad-hoc phrasings; standardizing is what
makes the behavior countable.

**6b — the same evidence-cell contract, extended to the phases that silently
drop.** Field check (2026-07-31, the maintainer's own two most recent lands):
`claude-md-sanity` was skipped in both despite the diff touching docs and
memory — the skip condition did not apply, no skip row was written, and a
validator's lock-step check was substituted, which campaign-land forbids by
name. `code-simplifier` passes on an unjustified self-attested "not needed".
Root cause is the same as item 6's: an evidence cell that does not demand an
item BY NAME loses it silently. Fix, riding the same die-gated artifact:
the Phase 6 evidence cell must contain `sanity:` — either findings and their
disposition, or `skip` quoting the named condition WITH the
`git diff --name-only` artifact the rule already requires; and Phase 3's
`simplifier: not needed` requires a one-clause reason. Two line-level edits
to campaign-land, no new mechanism.

**7 — a routing row for late entry into SDD/TDD.** Already implementing when you
reach for the discipline? Enter at the NEXT unit. Existing verified work gets
reviewed, never reverted to RED. This is the only observed failure with a
negative payoff — a session destroyed bitwise-verified work to restore
discipline, correctly applying TDD's iron law at the wrong moment.

**8 — the harness doctor learns to version-detect its own git hook.** The
adoption check greps the installed hook for a fixed string that every previously
installed hook also contains, so any future hook change reports as already
installed and is never offered. Fix this or no hook change ever reaches the
field again, whatever a future release decides.

## What is deliberately NOT shipped

**A commit-time gate on an empty plan section.** Cut on three independent
grounds: the state it fires on (a scaffolded plan section left empty) occurs
zero times in the corpus; its input is wrong in every measured case (of ten live
worktrees, four cannot see the state doc at all and all six that can hold a
stale copy, because the document is trunk-owned and edited at the anchor); and
it would never reach existing projects until item 8 lands. It also saves nothing
on the incident that motivated it — the first commit on that branch was the
already-completed inline implementation. Revisit only if a campaign is observed
committing source with a scaffolded-but-empty plan section.

**An edit-time PreToolUse hook.** Its unique capability — distinguishing the
coordinator from an implementer via the agent id present only in subagent hook
payloads — pays off only when a plan EXISTS and the coordinator executes a plan
step anyway. Not observed. Revisit on that exact trigger; the detection design
(walking to the nearest `.git`, reading the worktree's HEAD for the campaign
name, silence conditions) is recorded in the research and can be rebuilt.

**A machine matcher for plan coverage.** 42 docs record plans under 20+ heading
spellings; any matcher anchored to one spelling misclassifies well-planned
campaigns as unplanned. Only needed if coverage measurement is ever mechanized.

**Recovering the cost already spent in an incident.** Neither a commit-time gate
nor an iteration-boundary question returns context already burned. Prevention
only — stated so no future release claims otherwise.

## Honest residuals

- The delegation decision remains self-approved: the criterion improves, the
  judge does not change. The only surface that could observe it was the hook,
  correctly deferred.
- A session that never verbalizes "fixed, ready to merge" is not reached by a
  description; item 6 catches that path at land, and nothing catches it earlier.
- Items 1, 2 and 6 all move the same metric. The release notes must say they are
  ONE intervention across three surfaces, or the next release will mistake them
  for three independent data points.

## Post-ship measurement (no new instrument required)

Baselines over the 365-doc corpus: `"clean pass"` appears in **1** doc; docs
naming `review-to-convergence` number **7**. Re-count both in a month. Those two
numbers are the honest test of items 1 and 6. Coverage of the plan section
(13/365 today) is expected to rise on its own as pre-scaffold campaigns retire,
and is not evidence for or against this release.
