---
description: Check (and on approval install) the plugins ohd builds on, verify the Workflow tool, and report an environment checklist
---

Run ohd's environment checkup. Interview tone throughout:
recommend, ask before acting, never force. Do the steps in order; end with
the checklist.

1. Run `claude plugin list` (Bash) and evaluate:
   - **superpowers** — recommended — required for the full workflow from v0.2; v0.1 works without it.
   <!-- lock-step 세 곳!: keep this label in sync with the way-of-working skill (v0.2). -->
   - **code-review** — recommended; campaign-land Phase 3's default agent
     route (`Skill(code-review:code-review)` on the land PR). Without it,
     agent-led lands fall back to a generic review subagent.
   - **code-simplifier** — recommended; campaign-land Phase 3's
     simplification instrument (the `code-simplifier` agent on over-complex
     diffs, findings re-validated). Without it, simplification falls back to
     a generic subagent prompt.
   - **claude-md-management** — recommended; the repair path for
     claude-md-sanity findings (sanity AUDITS only — `revise-claude-md` /
     `claude-md-improver` do the rewriting). Without it, fixes are manual
     edits proposed by sanity's report.
   - **deep-solve@dipark (stale)** — if installed, warn: this plugin bundles
     deep-solve, so both register the same skill and command; recommend
     `claude plugin uninstall deep-solve@dipark`.
2. For each missing plugin, show the exact commands — marketplace add BEFORE
   install — then ask "install it now?" PER ITEM; on approval run the
   commands yourself, on decline leave them visible for copy-paste:
   - superpowers: `claude plugin install superpowers@claude-plugins-official`
     (the official marketplace normally ships with Claude Code; confirm with
     `claude plugin marketplace list` and say so honestly if it is absent).
   - code-review: `claude plugin install code-review@claude-plugins-official`
   - code-simplifier: `claude plugin install code-simplifier@claude-plugins-official`
   - claude-md-management: `claude plugin install claude-md-management@claude-plugins-official`
3. Auto-update: third-party marketplaces default to autoUpdate OFF — offer
   to enable it for `dipark` via settings.json `extraKnownMarketplaces`
   (`"autoUpdate": true`; verify the exact schema against
   https://code.claude.com/docs/en/discover-plugins at apply time — do not
   guess it). On approval apply; on decline note that updates then require
   manual `claude plugin update ohd@dipark`.
4. Workflow tool: check your OWN tool list for `Workflow`. It powers
   deep-solve's isolated mode; if absent, say that grounded mode and the
   manual fallback still work.
5. Final message = a checklist: one line per item — name, status
   (✓ installed / ✗ missing / ⚠ stale), and a dependency note in the form
   "X is needed by Y; without it, Y degrades to Z". Never overstate a
   requirement. End with EXACTLY this line:
   "새로 설치한 플러그인이 있다면 세션을 재시작(또는 /reload-plugins)한 뒤
   /ohd-setup 을 다시 실행해 확인하세요."
6. Render the report in the conversation language (the step-5 final line stays
   verbatim in Korean; if the conversation language is not Korean, add a
   translation in parentheses after it).
