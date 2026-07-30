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
     "<the mandate, restated as the loop prompt>" \
     --max-iterations <cap> --completion-promise '<exact phrase>'
   ```
   (installed_plugins.json is the authoritative path source; the cache glob
   is the fallback.)

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
   failure of this loop pattern.
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
