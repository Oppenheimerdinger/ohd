---
description: Interview-driven scaffolder for a new research project — campaign lifecycle, protected trunk, machine×env matrix CLAUDE.md, optional external-code hosts machinery
argument-hint: [project-name]
---

Run oppenheimerdinger's new-project interview, then scaffold. The target user
may be research-strong but dev-weak: for EVERY question give one line of WHY
it matters, exactly ONE recommendation, and accept enter-for-default. Ask the
questions ONE AT A TIME; re-ask on ambiguous answers.

The interview (flag each answer maps to — collect them as you go):

1. Project name (`--name`, required; `--dir`, default `~/projects/<name>` —
   if the user's convention puts projects elsewhere, propose that instead).
2. Create a GitHub repo? (`--github <owner/name>` or none; recommend yes —
   it is created private.) (recommend free)
3. Trunk branch name (`--trunk`, default main).
4. Campaign naming: free-form (`--naming free`) or numbered NNN-slug
   (`--naming numbered`).
5. Who merges — one anchored coordinator session, or a GitHub review gate?
   (`--merge-model`; single-owner → coordinator, collaborative → review-gate.)
6. Protect the trunk with a docs-only pre-commit hook? (`--hook`/`--no-hook`;
   shared repos → hook, personal experiments → no-hook.)
7. External code to bring in? none / a fork you will modify
   (`--host-vehicle fork`, needs `--host-name --host-repo --host-trunk`) / an
   upstream you only patch (`--host-vehicle patches`, needs
   `--host-name --host-repo`).
8. Node topology: single machine, or remote compute nodes? For each remote:
   `--node name:role[:ssh-alias]`. Filesystems shared or separate?
   (`--fs`; default separate — code then moves by git only.)
9. Execution environment(s): one, or split per program/stage? Each:
   `--env name:uv|conda|module[@machine]` — the FIRST one is primary; uv is
   allowed only as primary.
10. Large shared data? (`--data-dir <path>` — the path must already exist;
    becomes a read-only-by-discipline symlink `data/`.)
11. Deployment shape later? (`--deploy none|snapshot|mirror` — recorded in
    CLAUDE.md only; tooling comes later.) (recommend none for now)

Then the SUMMARY GATE: show the full flag list you assembled and ask for an
explicit go (edit / cancel offered). Only on go, run:

    bash "${CLAUDE_PLUGIN_ROOT}/assets/new-project.sh" <flags...>

If the script dies at preflight, nothing was created — fix that answer and
rerun.

Relay the script's output — especially the next-steps block and any manual
gh/origin commands it printed — verbatim to the user. If $ARGUMENTS contains
a project name, use it as the answer to question 1.
