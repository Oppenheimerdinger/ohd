---
description: Check (and on approval install) the plugins oppenheimerdinger builds on, verify the Workflow tool, and report an environment checklist
argument-hint: (no arguments)
---

Run oppenheimerdinger's environment checkup. Interview tone throughout:
recommend, ask before acting, never force. Do the steps in order; end with
the checklist.

1. Run `claude plugin list` (Bash) and evaluate:
   - **superpowers** — recommended — required for the full workflow from v0.2; v0.1 works without it. [lock-step 두 곳!: keep this label in sync with the way-of-working skill from v0.2]
   - **oh-my-claudecode** — optional; only needed for the ralph persistence
     mode.
   - **deep-solve@dipark (stale)** — if installed, warn: this plugin bundles
     deep-solve, so both register the same skill and command; recommend
     `claude plugin uninstall deep-solve@dipark`.
2. For each missing plugin, show the exact commands — marketplace add BEFORE
   install — then ask "install it now?" PER ITEM; on approval run the
   commands yourself, on decline leave them visible for copy-paste:
   - superpowers: `claude plugin install superpowers@claude-plugins-official`
     (the official marketplace normally ships with Claude Code; confirm with
     `claude plugin marketplace list` and say so honestly if it is absent).
   - oh-my-claudecode:
     `claude plugin marketplace add Yeachan-Heo/oh-my-claudecode` then
     `claude plugin install oh-my-claudecode@omc`
3. Workflow tool: check your OWN tool list for `Workflow`. It powers
   deep-solve's isolated mode; if absent, say that grounded mode and the
   manual fallback still work.
4. Final message = a checklist: one line per item — name, status
   (✓ installed / ✗ missing / ⚠ stale), and a dependency note in the form
   "X is needed by Y; without it, Y degrades to Z". Never overstate a
   requirement. End with EXACTLY this line:
   "새로 설치한 플러그인이 있다면 세션을 재시작(또는 /reload-plugins)한 뒤
   /ohd-setup 을 다시 실행해 확인하세요."
5. Render the report in the conversation language.
