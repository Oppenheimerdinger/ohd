---
description: Harness doctor for an existing project — 하네스 점검/정비/채택. Detects drift between the project and the ohd harness (campaign.sh template, trunk hook, state dir, CLAUDE.md wiring, plugin dependencies, landed docs missing their land-report, stale plugin cache), reports a fix table, and repairs per-item on approval. Also the adoption path for projects that never had the harness.
argument-hint: [project-root]
---

Check (and on approval repair) a project's ohd harness. Target = $ARGUMENTS if
given, else the current directory; it must be a git repo root.

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
   item missing.
4. **Drift table**: print ONE table — `item | status | fix` — merging all
   passes, ENDING with the script's scope footer relayed verbatim (what a
   green table does NOT attest: discipline compliance, code correctness).
   This is the artifact; findings not in the table didn't happen.
5. **Per-item repair, gated**: AskUserQuestion per drifted item (batch
   independent ones), exactly one recommendation each:
   - campaign.sh drift/missing → `checkup.sh <root> --sync` (key-based config
     merge: project values and custom vars survive; review `git diff` after).
   - hook missing → copy + run `assets/install-hooks.sh` (skip is legitimate
     for trunk-dev repos — say so).
   - CLAUDE.md wiring gaps → MERGE the missing blocks into the existing file
     from the template's shape; never replace the file.
   - state dir → mkdir + .gitkeep.
6. **Content hygiene**: after repairs, if CLAUDE.md was touched (or the user
   asks), invoke the `ohd:claude-md-sanity` skill — do NOT re-implement its
   audit here.
7. Uncommitted repairs at the end: remind the user to review `git diff` and
   commit (docs-only trunk hooks allow the .md and tools/ paths involved —
   if a hook blocks, say which paths and why instead of forcing).

## Adoption (project never had the harness)

Same procedure — everything reports MISSING and step 5 becomes the dropin
install (follow `docs/campaign-dropin.md` §Install + §Adopting; the
interview questions and defaults live THERE). `/ohd-new-project` remains the
path for brand-new projects; this command is for existing code.

Relay the mechanical report and the final table verbatim to the user.
