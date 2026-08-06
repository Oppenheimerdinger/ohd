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
   the user is still present: what "done" means (the completion condition),
   an iteration cap, and the exact completion phrase. If the mandate says
   don't ask ("묻지 말고"), derive them and STATE them before starting.
2. **Launch the loop before touching the work.** The official ralph-loop
   plugin's slash command is user-facing only (`hide-from-slash-command-tool`)
   — run its setup script directly:

   ```bash
   RL="$(jq -r '.plugins["ralph-loop@claude-plugins-official"][0].installPath' \
        ~/.claude/plugins/installed_plugins.json 2>/dev/null)"
   [ -d "$RL" ] || RL="$(ls -d ~/.claude/plugins/cache/claude-plugins-official/ralph-loop/*/ 2>/dev/null | sort -V | tail -1)"
   bash "$RL/scripts/setup-ralph-loop.sh" \
     "<the mandate, restated as the loop prompt>
      Your lane is dispatch, review, merge. Implementation goes to a fresh
      agent per task; only micro-edits stay inline — a STANDALONE fix
      outside any plan or dispatched task, and NOT a micro-edit if it
      writes a new test, needs a mutation or negative control, or needs a
      gate run to judge it.
      End every iteration having ADVANCED the mandate — a fresh dispatch or
      a backgrounded watch; work you did inline does not count as advancing.
      Every deliverable you call done NAMES the review pass that cleared it." \
     --max-iterations <cap> --completion-promise '<exact phrase>'
   ```
   (installed_plugins.json is the authoritative path source; the cache glob
   is the fallback.) The lane, advance and review-naming lines ride the
   PROMPT, not this skill's body, deliberately: the stop hook re-injects the
   prompt verbatim on every iteration, so it survives compaction and context
   rollover — which a skill read once at minute zero does not. The flip side:
   the prompt is written ONCE at setup and re-injected AS STORED, so upgrading
   the plugin mid-mandate does not refresh a running loop's prompt — adopting
   new prompt text means cancelling the loop and setting it up again, which is
   the user's call (step 5).

   The state file lands at `.claude/ralph-loop.local.md` in the cwd — run
   this at the project anchor. If the plugin is absent: SAY SO and offer the
   install (`/ohd-setup` owns the roster; `claude plugin install
   ralph-loop@claude-plugins-official`), or fall back to oh-my-claudecode's
   ralph if installed; if NEITHER exists and the user is already gone, fall
   back to the built-in `/loop` (zero-install, self-pacing) — an imperfect
   loop beats a bare session. **Never proceed bare**; if the user is still
   present, say which tier you got and why.
3. **The completion phrase obeys the loop-termination rule** (way-of-working):
   an independent evaluator judges done-ness from the goal + concrete
   evidence; output the completion phrase ONLY after quoting the evaluator's
   verdict verbatim and appending it to the loop's notes/state doc — and
   emit it in the loop's exit format, `<promise>exact phrase</promise>`
   (the stop hook matches the tag, not bare prose). Emitting
   the phrase without a verdict is self-grading — the known premature-COMPLETE
   failure of this loop pattern. Completion is judged by the evaluator's verdict
   and never by whether the stop hook fired or stopped firing — a hook can miss
   a correct promise (field-recorded race), and hook silence is not a verdict.
   In that exact race — verdict banked verbatim, hook still re-firing — re-emit
   the `<promise>` in the loop's exit format each iteration and do NO further
   mandate work; if it persists, the user-owned cancel (step 5) is the
   legitimate manual exit, and the banked verdict is what makes it legitimate.
   The evaluator's brief carries two MANDATORY questions on top of the goal:
   **which work units were delegated versus done by the coordinator**, and
   **does every deliverable claimed done name the review pass that cleared
   it**. Both are answerable from git and the agent log. The verdict is quoted
   verbatim into the state doc anyway, so an evaluator that answered neither is
   visible after the fact.
4. **Persist the mandate**: record scope, cap, and completion phrase in the
   project's state doc or notes — an unattended session's chat record
   evaporates, and the loop may outlive this context window.
5. **Cancellation is USER-owned.** The user runs `/cancel-ralph` or removes
   the state file from their shell. The looping session itself NEVER removes
   `.claude/ralph-loop.local.md` **on its own initiative** (executing the
   user's `/cancel-ralph` is the USER cancelling — the session is only the
   mechanism) — killing the loop's state on its own judgment is the same
   self-grading termination as emitting an unverdicted `<promise>`, just by
   another door. In particular, "the remaining work is owned by agents whose
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
     (Step 3's completion exit is its own ending and needs none of these.)
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
