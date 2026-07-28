---
description: Harness doctor for an existing project — 하네스 점검/정비/채택. Detects drift between the project and the ohd harness (campaign.sh version, trunk hook, state dir, CLAUDE.md wiring), reports a fix table, and repairs per-item on approval. Also the adoption path for projects that never had the harness.
argument-hint: [project-root]
---

Check (and on approval repair) a project's ohd harness. Target = $ARGUMENTS if
given, else the current directory; it must be a git repo root.

**DRY invariant — this command carries NO canonical content.** What the
harness *should* look like lives in exactly one place each:
`${CLAUDE_PLUGIN_ROOT}/assets/campaign.sh` (lifecycle tooling),
`${CLAUDE_PLUGIN_ROOT}/assets/CLAUDE.md.template` (CLAUDE.md wiring shape),
`${CLAUDE_PLUGIN_ROOT}/assets/install-hooks.sh` (trunk hook),
`${CLAUDE_PLUGIN_ROOT}/docs/campaign-dropin.md` (adoption checklist). Read
them at runtime; never restate their content here or in the report. When the
plugin updates, this command's standard updates with it.

## Procedure

1. **Mechanical pass**: run
   `bash "${CLAUDE_PLUGIN_ROOT}/assets/checkup.sh" <root>` — it reports
   `item | status | detail` for campaign.sh (template diff, config-block
   excluded), trunk hook, state dir, and CLAUDE.md existence. Do not
   re-derive these by hand.
2. **Wiring pass (semantic)**: read the dropin guide's "Adopting an EXISTING
   project" section AT RUNTIME and check the project's CLAUDE.md for the
   PRESENCE (not wording) of each numbered item that section lists, using
   `assets/CLAUDE.md.template` as the reference shape. The item list lives
   ONLY there — do not rely on a remembered copy. A missing CLAUDE.md = every
   item missing.
3. **Drift table**: print ONE table — `item | status | fix` — merging both
   passes. This is the artifact; findings not in the table didn't happen.
4. **Per-item repair, gated**: AskUserQuestion per drifted item (batch
   independent ones), exactly one recommendation each:
   - campaign.sh drift/missing → `checkup.sh <root> --sync` (key-based config
     merge: project values and custom vars survive; review `git diff` after).
   - hook missing → copy + run `assets/install-hooks.sh` (skip is legitimate
     for trunk-dev repos — say so).
   - CLAUDE.md wiring gaps → MERGE the missing blocks into the existing file
     from the template's shape; never replace the file.
   - state dir → mkdir + .gitkeep.
5. **Content hygiene**: after repairs, if CLAUDE.md was touched (or the user
   asks), invoke the `ohd:claude-md-sanity` skill — do NOT re-implement its
   audit here.
6. Uncommitted repairs at the end: remind the user to review `git diff` and
   commit (docs-only trunk hooks allow the .md and tools/ paths involved —
   if a hook blocks, say which paths and why instead of forcing).

## Adoption (project never had the harness)

Same procedure — everything reports MISSING and step 4 becomes the dropin
install (follow `docs/campaign-dropin.md` §Install + §Adopting; the
interview questions and defaults live THERE). `/ohd-new-project` remains the
path for brand-new projects; this command is for existing code.

Relay the mechanical report and the final table verbatim to the user.
