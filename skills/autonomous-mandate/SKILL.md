---
name: autonomous-mandate
description: This skill MUST fire when the user grants UNATTENDED, session-scope autonomous completion — "자율진행", "자율로 완수해", "알아서 끝까지 해", "run this autonomously", "while I'm away". NOT for deep-solve's per-run gate waiver ("자율적으로 진행" scoped to one launch — that skill handles it). First action — persistence-loop setup; bare autonomous sessions stall.
---

# Autonomous mandate — the loop comes first

A session that accepts an autonomous mandate and starts working bare WILL
stall: it ends a turn on a declarative promise ("계속 진행하겠습니다") and
nothing resumes it (field record: way-of-working's mandate rule). The loop
is not optional overhead; it is what makes "autonomous" mechanically true.
**Scope check first**: "자율적으로 진행" said at a deep-solve gate waives
THAT gate only — deep-solve's own waiver path handles it; do not set up a
loop for it. This skill is for session-scope, user-absent mandates.

## Procedure (in this order)

1. **Fix the contract** — from the mandate itself, or ONE short question if
   the user is still present: what "done" means (the completion condition)
   and an iteration cap. If the mandate says don't ask ("묻지 말고"), derive
   them and STATE them before starting. The done-contract is not just prose
   here: step 2 writes it into the loop's PRD as the acceptance criteria the
   loop's own completion check reads.
2. **Launch the loop before touching the work.** The vehicle is
   oh-my-claudecode's **ralph**. Arming it is THREE acts in this order, and
   none of them is optional: **invoking the ralph Skill does not arm the
   loop.** Only OMC's user-prompt keyword detector writes arming state, and a
   model-invoked skill never passes through it — so a session that "started
   ralph" by calling the skill and then began working is a BARE session that
   believes it is looping. That belief is the failure this step exists to
   prevent, which is why (c) is a probe and not a reassurance.

   **(a) Arm the state explicitly** via OMC's sanctioned state tool. The stop
   hook reads exactly these fields:

   ```
   state_write(
     mode="ralph",
     session_id=<this session's id>,          # selects the session-scoped path
     active=true, iteration=1, max_iterations=<cap>,
     started_at=<ISO-8601 now>,
     state={
       session_id:      <this session's id>,  # ALSO inside the body — see below
       project_path:    <the project anchor>,
       last_checked_at: <ISO-8601 now>,
       prompt: "<the mandate, restated as the loop prompt>
                Your lane is dispatch, review, merge. Implementation goes to a
                fresh agent per task; only micro-edits stay inline — a
                STANDALONE fix outside any plan or dispatched task, and NOT a
                micro-edit if it writes a new test, needs a mutation or
                negative control, or needs a gate run to judge it.
                End every iteration having ADVANCED the mandate — a fresh
                dispatch or a backgrounded watch; work you did inline does not
                count as advancing.
                Every deliverable you call done NAMES the review pass that
                cleared it."
     })
   ```

   Four things about that call are load-bearing, each measured against the
   hook's source rather than inferred:
   - **`session_id` goes in BOTH places.** The tool parameter only chooses the
     file path; the hook separately compares the session id in the state BODY
     against the stopping session's, and a body without one never matches — an
     armed-looking state file that blocks nothing.
   - **`project_path` must be the directory the session actually runs in**
     (paths are compared normalized). Run this at the anchor.
   - **NEVER write `awaiting_confirmation`.** That field exists to hold
     keyword-armed state pending the user's yes; on state you armed
     deliberately it SUPPRESSES the stop hook for its lifetime — arming the
     loop and disarming it in the same call.
   - **`prompt` is the durable channel.** The hook re-injects it verbatim as
     the task line of every iteration, so the lane, advance and review-naming
     lines ride it rather than this skill's body: a skill is read once at
     minute zero, the prompt survives compaction and context rollover. Flip
     side: it is stored ONCE and re-injected AS STORED, so upgrading the
     plugin mid-mandate does not refresh a running loop's prompt — adopting
     new prompt text means cancelling and re-arming, the user's call (step 5).

   **(b) Invoke the ralph Skill** (`Skill(oh-my-claudecode:ralph)`) so the PRD
   machinery loads, and write step 1's done-contract INTO the PRD stories
   while arming — as task-specific acceptance criteria, not the scaffold's
   generic ones. The PRD is what ralph's own completion check reads; a
   done-contract that lives only in the mandate is a contract that check
   cannot see.

   **(c) VERIFY ARMED — the launch contract.** The next Stop must produce the
   ralph iteration banner (`[RALPH LOOP - ITERATION 2/<cap>]`). Seeing it is
   what makes the loop live; the state write alone is NOT trusted, because
   every way this can fail — session-id mismatch, a project-path that does not
   normalize to the cwd, a stale-looking timestamp — fails SILENTLY into a
   session that reads as autonomous and is not. If the banner does not appear,
   the loop is not live: fix the arming or drop to the fallback, and **never
   proceed bare**.

   If OMC is absent: SAY SO and fall back to the built-in `/loop`
   (zero-install, self-pacing) or `schedule`. State the capability gap
   honestly rather than calling it a loop and moving on — the fallback has no
   stop-hook persistence and no completion contract, so nothing re-injects the
   mandate and nothing blocks a promise-ending turn; **step 4's state-doc
   persistence is the only durability there**. An imperfect loop beats a bare
   session, but the user is owed which tier they got — say it in one line if
   they are still present.
3. **The completion exit obeys the loop-termination rule** (way-of-working):
   an independent evaluator judges done-ness from the goal + concrete
   evidence. Under this vehicle the exit is the session running the OMC cancel
   command (`/oh-my-claudecode:cancel`, `--force` if it does not take) — and
   that is legitimate ONLY after the verdict is banked, in this order:

   1. every PRD story passes,
   2. the independent reviewer signs off — its brief carries the ORIGINAL
      mandate alongside the PRD, because a PRD this session wrote and this
      session marked passing is otherwise a self-authored yardstick, plus two
      MANDATORY questions: **which work units were delegated versus done by
      the coordinator**, and **does every deliverable claimed done name the
      review pass that cleared it** (both answerable from git and the agent
      log),
   3. the verdict is quoted VERBATIM into the state doc — who evaluated, what
      evidence it saw, done/not-done, reasons,
   4. then, and only then, cancel.

   **Cancelling without a banked verdict is the unverdicted promise wearing
   the new vehicle's clothes** — the same self-grading termination, reached
   through the exit the tooling makes easiest. The banked verdict is the whole
   difference between an exit and a session declaring victory on itself, and
   because the quote is verbatim, an evaluator that answered neither mandatory
   question is visible after the fact.

   **The iteration cap is not a terminator — say so honestly.** OMC does not
   stop at the cap; it extends it and keeps going. The cap is a sanity bound
   on runaway cost, and the evaluator's verdict is the only real exit. Nor is
   hook behaviour a verdict: hook silence never means done, and a hook that
   keeps firing after a banked verdict means cancel has not taken — retry it
   (`--force`) and do NO further mandate work, rather than reaching past it
   into the state files (step 5).
4. **Persist the mandate**: record scope, cap, and the done-contract in the
   project's state doc or notes — an unattended session's chat record
   evaporates, and the loop may outlive this context window. Under the `/loop`
   fallback this record is not a backup of the loop's memory; it is the ONLY
   copy.
5. **Mid-flight ABORT is USER-owned.** Stopping a loop that is not done is the
   user's call — they run the cancel command or clear the state from their
   shell (OMC's ralph state lives at
   `.omc/state/sessions/<session-id>/ralph-state.json` under the project's
   `.omc/`; way-of-working's cancel-misfire block owns the stuck-hook path).
   The looping session never reaches into that file **on its own initiative**
   — executing the user's cancel is the USER cancelling, the session being
   only the mechanism, whereas killing the loop's state on the session's own
   judgment is self-grading termination through a side door. This is the exact
   line step 3 draws: a cancel BEHIND a banked verdict is the completion exit,
   a cancel INSTEAD of one is this violation. In particular, "the remaining
   work is owned by agents whose
   notifications will resume me" is NOT a termination verdict: an
   idle_notification means "nothing to say", not "done" (field record: three
   agents idled with uncommitted fixes, missing deliverables, and missing
   verdicts — the loop, not the notifications, was the only real resume
   mechanism). If you believe the loop should end, dispatch the independent
   evaluator and exit through its verdict — there is no other exit.
6. **An iteration with nothing to do is a symptom, not a signal to stop.**
   The loop fires on every Stop, so the loop re-fires exactly as fast as
   your turns end — a five-second status check re-fires within seconds. Two
   workarounds FAIL (both measured in the field):
   - *Short no-op turns*: the loop re-fires almost immediately and each
     iteration costs a full turn of context. The session can run out before
     the work does — a worse failure than the empty turns it tolerates.
   - *Padding the turn with a blocking wait*: frequency drops, but the
     session stops answering — the user had to background the running
     command by hand just to say something. Never lengthen a turn by
     sleeping; an unattended mandate is not an unreachable one.

   What to do instead, in order:
   - **End each iteration having ADVANCED the mandate** — a fresh dispatch,
     or a backgrounded watch on the blocking condition (Monitor /
     run_in_background — these are non-blocking; only sleeping is banned).
     Work you did INLINE does not count as advancing: a micro-edit is still
     legitimate (way-of-working's delegation boundary owns that line), but an
     iteration whose only content was the coordinator implementing IS the
     failure this mandate exists to prevent — a coordinator that did
     everything itself used to satisfy this list as written. An empty
     iteration is almost always a MISSING DISPATCH — the same failure the
     mandate exists to prevent, wearing a different hat. If a legitimate
     micro-edit really was the only actionable item and nothing is
     dispatchable or watchable, that iteration is the LAST RESORT case
     below — name it as such; do not manufacture a dispatch to dodge the
     label (manufacturing work is banned there for the same reason).
     (Step 3's completion exit is its own ending and needs none of these —
     including the cancel retries while the hook keeps firing.)
   - **Read deliverables from git or the agent log, never from the
     notification** (step 5: idle != done). "Agent notified" is not "agent
     committed"; check, then tell it to finish.
   - If the critical path is genuinely blocked on a running agent, open the
     next non-overlapping piece of work **as its own campaign**
     (`campaign.sh new` — not a bare worktree: the lifecycle CLI carries the
     state doc, staleness listing, and cleanup ownership). Two agents in one
     worktree contaminate each other's gate runs.
   - LAST RESORT — not a "works": genuinely gated on wall-clock with
     nothing dispatchable and no backgroundable watch — or the only
     actionable item was a legitimate micro-edit and it is already done —
     keep the turn short and NAME which of the two the iteration was. This
     IS the un-advanced iteration named above (an empty turn, or one whose
     only content was your own edit), unsolved — merely the smallest evil
     (smaller than manufactured work or a sleep).
     **Do not manufacture work to fill an iteration** — an artifact written
     to justify a turn costs more to review than the empty turn it
     replaced. If iterations keep landing here, record in the state doc
     that the mandate has narrowed to one serial pipe.
