---
description: Harness doctor for an existing project — 하네스 점검/정비/채택. Detects drift between the project and the ohd harness (campaign.sh template, trunk hook, state dir, CLAUDE.md wiring, plugin dependencies, landed docs missing their land-report, stale plugin cache), reports a fix table, and repairs per-item on approval. Also the adoption path for projects that never had the harness, and `structure` generates the corpus cleanup work-list.
argument-hint: "[project-root] [structure]"
---

Check (and on approval repair) a project's ohd harness. Target = $ARGUMENTS if
given, else the current directory; it must be a git repo root.

## Two modes, one command

- **Default** — the fast drift doctor, run as often as you like. Its rows are
  COUNTS AND GATES only (template drift, hook stamp, byte budget, pointer
  resolution, false-OPEN count), all cheap and none action-proposing. A count
  is a POINTER, not an audit: a default run must never nag a project into
  structural work. It ends with ONE summary line naming the other mode.
- **`structure`** — `/ohd-checkup structure` (or `/ohd-checkup <root> structure`)
  passes `--structure` to the script. This is the opt-in WORK-LIST GENERATOR:
  solidation candidates, the orphan-verification census with its allowlist,
  plans/specs corpus size, a doc-size histogram, the reference-tier adoption
  offer, and a paste-ready baselines table. Its FIRST run on a project IS the
  adoption audit. It GENERATES only — **execution is ordinary project
  campaigns driven by the list; never bulk-move a project's documents
  yourself**, and never run it as part of a routine checkup the user asked for.
  The baselines live in the OUTPUT: offer to paste them into the cleanup
  campaign's state doc, since nothing is stamped on disk.
  It also lists **state-claim staleness** candidates — lines asserting state
  outside the reference tier — as re-verify prompts, counted and listed with no
  dating (the human judges staleness; mtime and git-log both mislead).
  **The EXECUTED work-list is a deliverable**: run `review-to-convergence` on
  it before committing. A docs-only cleanup on a docs-only trunk never reaches
  campaign.sh's land die-gate, so that pass is the only review it gets.

The probes' rule — agent-facing failure is exit-code-shaped, not log-shaped —
is canonical in `assets/probes/engage_grep.sh` and
`assets/home-set/reference/conventions.md` §Route map, and routed by
`ohd:campaign-land` Phase 6. No row below checks it.

**DRY invariant — this command carries NO canonical content.** What the
harness *should* look like lives in exactly one place each:
`${CLAUDE_PLUGIN_ROOT}/assets/campaign.sh` (lifecycle tooling),
`${CLAUDE_PLUGIN_ROOT}/assets/CLAUDE.md.template` (CLAUDE.md wiring shape),
`${CLAUDE_PLUGIN_ROOT}/assets/install-hooks.sh` (trunk hook),
`${CLAUDE_PLUGIN_ROOT}/docs/campaign-dropin.md` (adoption checklist),
`${CLAUDE_PLUGIN_ROOT}/commands/ohd-setup.md` §1 (plugin dependency list). Read
them at runtime; never restate their content here or in the report. When the
plugin updates, this command's standard updates with it.

## Procedure

1. **Mechanical pass**: run
   `bash "${CLAUDE_PLUGIN_ROOT}/assets/checkup.sh" <root>` — it prints one
   `item | status | detail` line per harness check plus a scope footer (the
   check list lives in the script; do not restate or re-derive it by hand).
   Add `--structure` ONLY when the user asked for the structure mode.
2. **Dependency pass**: evaluate the plugin checklist that
   `${CLAUDE_PLUGIN_ROOT}/commands/ohd-setup.md` §1 defines (read it at
   runtime — the list lives ONLY there). Report each missing plugin as a
   drift-table row (e.g. `plugin: code-review | MISSING | campaign-land
   Phase 3 degrades to the subagent route`); offer the install commands
   ohd-setup names, per-item on approval.
3. **Wiring pass (semantic)**: read the dropin guide's "Adopting an EXISTING
   project" section AT RUNTIME and check the project's CLAUDE.md for the
   PRESENCE (not wording) of each numbered item that section lists, using
   `assets/CLAUDE.md.template` as the reference shape. The item list lives
   ONLY there — do not rely on a remembered copy. A missing CLAUDE.md = every
   item missing. For items PRESENT: if the template's current block carries a
   load-bearing RULE the project's block lacks (a rule, not phrasing — e.g. a
   concurrency rule the old block predates), add an `OPTIONAL-REFRESH` row
   naming the missing clause; never auto-apply, and never flag mere wording
   differences.
3b. **Retired-route pass (semantic)**: a PRESENT item can name a **route a
   BEHAVIOR-CHANGE has RETIRED** — the rule survives, the mechanism it names
   no longer works. That is neither a missing rule nor mere wording, so 3's
   two cases both miss it and the table stays green while every session
   re-derives the dead route from the project's own CLAUDE.md. Bound this to
   the `harness-changes` rows the script just relayed — do NOT go hunting for
   prose to dislike, and do not re-derive project impact from CHANGELOG prose
   yourself (that judgment happened at release time). Run this pass ONLY when
   the mechanical pass's `harness-changes` row reports `REVIEW` — an
   inversion, not an enumerated skip list, on purpose: every OTHER status
   `assets/checkup.sh` can emit (see the script for the current set),
   including the row being absent entirely on a project with no
   `campaign.sh` yet, carries no bounded BEHAVIOR-CHANGE list for 3b to
   check — naming them here would drift out of sync the next time the
   script adds one. For each relayed BEHAVIOR-CHANGE that retires or
   re-routes a mechanism, grep the project's CLAUDE.md **and its memory
   store** for the retired mechanism. BOTH stores are in scope: the
   repo-relative `MEMORY.md` + `memory/*.md` if the project keeps one, AND the
   out-of-repo auto-memory store — resolve its location the way
   `ohd:claude-md-sanity`'s Check 3 does (read that skill at runtime for the
   path; do not inline it here, per the DRY invariant above). A project's
   standing rule commonly lives ONLY in the out-of-repo store, and no other
   checkup pass reads it. Add one `RETIRED-ROUTE` row per hit, naming the
   superseding route. **If a store cannot be located or read, say so in the
   table** — `retired-route-check | MANUAL | <which store> not resolved;
   grep it by hand for the relayed routes` — never silently emit zero rows:
   an unreadable store looking identical to a clean one is the exact
   blindness this pass exists to close.
4. **Drift table**: print ONE table — `item | status | fix` — merging all
   passes, ENDING with the script's scope footer relayed verbatim (what a
   green table does NOT attest: discipline compliance, code correctness).
   This is the artifact; findings not in the table didn't happen.
5. **Per-item repair, gated**: AskUserQuestion per drifted item (batch
   independent ones), exactly one recommendation each:
   - campaign.sh drift/missing → `checkup.sh <root> --sync` (key-based config
     merge: config-block keys survive — the script BODY is replaced wholesale,
     with a pre-sync backup written; review `git diff` after).
   - `harness-changes | NO-BASELINE` (campaign.sh may be IN-SYNC yet
     unstamped — every raw-copy install starts this way) → offer
     `checkup.sh <root> --sync` to establish the stamp; note the protection
     is forward-only, so pair it with the one-time hand review the row's
     own message describes.
   - hook missing → copy + run `assets/install-hooks.sh` (skip is legitimate
     for trunk-dev repos — say so).
   - `trunk-hook | STALE` → re-run `assets/install-hooks.sh`; hook changes
     never auto-propagate, so an older stamp stays until someone reinstalls.
   - `trunk-hook | AHEAD` (installed hook NEWER than this plugin ships — a
     sibling worktree ran a newer ohd) → the plugin cache is stale, not the
     hook: `/reload-plugins` or update the plugin, then re-run checkup. Do
     NOT reinstall the hook; that downgrades it.
   - CLAUDE.md wiring gaps → MERGE the missing blocks/clauses into the
     existing file from the template's shape; never replace the file.
   - `RETIRED-ROUTE` → replace the named mechanism with the superseding route,
     in place, at every hit (CLAUDE.md and the memory store — repo-relative
     and/or out-of-repo, whichever 3b found the hit in); KEEP the rule — the
     gate is not the thing that expired. A project may legitimately decline
     (a fork carrying its own route on purpose); record that and move on.
   - state dir → mkdir + .gitkeep.
   - `reference | MISSING` → offer to copy the plugin's
     `assets/home-set/` into `docs/` (reference tier + archive stub). Copy the
     scaffold ONLY; filling it is the project's work, and the structure mode's
     work-list is what supplies the first fill.
   - `reference | STALE` → a rotted catalog MISDIRECTS, which is worse than
     absence: fix the dead pointer or refresh the dated line, per hit. If this
     row goes red twice with no action, recommend DELETING the offending
     entries rather than letting them lie.
   - `always-loaded | OVER` → this is mass every actor-wake pays before its
     first useful token. Recommend moving narrative and incident history out of
     CLAUDE.md into `docs/campaigns/` or `docs/archive/` (leaving the search
     key), keeping the hot kernel to rules and pointers. Never auto-edit.
   - `campaigns | ... false-OPEN` → close the contradicting `status:` lines;
     a doc that says OPEN with a filled verdict reads as in-flight to every
     grep. Cheap and safe to batch, still gated.
6. **Content hygiene**: after repairs, if CLAUDE.md **or the memory store** was
   touched (or the user asks), invoke the `ohd:claude-md-sanity` skill — do NOT
   re-implement its audit here.
7. Uncommitted repairs at the end: remind the user to review `git diff` and
   commit. `.md` repairs pass the default docs-only trunk hook, but `tools/`
   repairs do NOT (default ALLOW_RE is `^docs/|\.md$`) — commit those with
   `--no-verify` and the reason in the commit message (harness maintenance,
   not campaign work); do NOT widen ALLOW_RE to make them pass, and if a
   hook blocks, say which paths and why instead of forcing silently. A
   `--sync` also leaves an untracked `tools/campaign.sh.pre-sync.*` backup —
   recovery material, not a commit candidate: point the user at it and
   suggest deleting it once the diff is reviewed. A
   `RETIRED-ROUTE` repair applied to the out-of-repo auto-memory store is not
   under version control and so never shows up in that `git diff` — call it
   out separately and point the user at the edited memory file(s) directly.

## Adoption (project never had the harness)

Same procedure — everything reports MISSING and step 5 becomes the dropin
install (follow `docs/campaign-dropin.md` §Install + §Adopting; the
interview questions and defaults live THERE). `/ohd-new-project` remains the
path for brand-new projects; this command is for existing code.

Relay the mechanical report and the final table verbatim to the user.
