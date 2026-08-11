# campaign.sh drop-in guide (interview-driven)

Adds the worktree campaign lifecycle to an EXISTING repo. Every parameter is a
question with a recommended default — press through the defaults for a
standard single-repo project.

## The interview

| Question | Config | Default (recommended) |
|---|---|---|
| Trunk branch? | `TRUNK` | `main` |
| Where should worktrees live? | `WT_ROOT` | (empty — derives `$HOME/wt/<repo-name>/`, per-project) |
| Campaign naming: free-form or numbered `NNN-slug`? | `NAMING` | `free` (numbered suits milestone-style projects) |
| Who merges? One anchored coordinator session, or a GitHub review gate? | `MERGE_MODEL` | `coordinator` for a single-owner repo; `review-gate` for collaborative repos |
| Where do campaign state docs live? | `STATE_DIR` | `docs/campaigns` |
| Is there a pinned dependent/fork repo? | `DEP_DIR`, `DEP_TRUNK`, `PIN_FILE` | none (enables the `pin` subcommand when set) |
| How does one run tests inside a fresh worktree? | `WORKTREE_HINT` | empty (`{wt}` substitutes the worktree path — e.g. `test: PYTHONPATH={wt}/src <trunk-venv>/bin/pytest`; worktrees have no `.venv`) |
| Protect the trunk with a docs-only pre-commit hook? | — | yes for shared repos; **skip** for repos that intentionally develop on trunk (this plugin repo itself skips it) |

## Install

1. Copy `assets/campaign.sh` from the plugin into the repo as
   `tools/campaign.sh` (the plugin's files live under
   `~/.claude/plugins/cache/dipark/ohd/<version>/assets/` after
   install, or clone the repo); edit the config block at the top with the
   interview answers (env `CAMPAIGN_*` variables override at runtime);
   `chmod +x`. If the defaults already match your answers, no edits are
   needed — just note that in a header comment for provenance.
2. `git add`-track the empty state directory: `touch <STATE_DIR>/.gitkeep`
   (`cmd_new` will `mkdir -p` it on first use, but an untracked empty dir is
   invisible to git — commit the placeholder now so the drop-in leaves a
   visible trace even before any campaign exists).
3. If trunk protection was chosen: copy `assets/install-hooks.sh` to
   `tools/install-hooks.sh` and run it once per clone
   (`CAMPAIGN_TRUNK_ALLOW` adjusts the allowed-path regex).
4. Smoke: `tools/campaign.sh new scratch-test` → confirm the worktree, branch,
   and state doc appeared → `tools/campaign.sh abort scratch-test` → **manually
   remove the scratch state doc** (`rm <STATE_DIR>/scratch-test.md`): `abort`
   only tears down the worktree and branch, the state doc is a trunk artifact
   and deliberately survives (so real aborts keep a paper trail) — the smoke
   test needs an explicit cleanup step or it leaves scratch litter in the repo
   (with NAMING=numbered, use `000-scratch` as the test name).

## Daily lifecycle

`new <name>` → work inside the worktree → `land <name> --report` (scaffolds
the land-report table into the state doc) → fill it per the campaign-land
skill → `land <name>` (push + PR — REFUSES without the land-report;
`LAND_GUARD=0` bypasses) → merge per your model →
`status <name>` to verify (squash-safe) → `clean <name>`. Stuck/abandoned?
`abort <name>` (keeps the remote branch unless `--purge`). `list` shows open
campaigns so none go stale silently.

**Local gates only is the DEFAULT model here — CI is opt-in**, which is already
what this scaffold does (nothing it installs defines a check), and it is opt-in
rather than merely absent because a red suite on a long workflow can burn a free
Actions tier in days and leave every land bypassing a check that can no longer
go green (measured — issue #31). If a project adopts CI and later retires it,
declare that with one line — `- ci: retired (<date> — <reason>)` in CLAUDE.md or
`docs/reference/conventions.md` — and campaign-land's Phase 0 attests the skip
instead of re-deriving the story every land.

## Adopting an EXISTING project (full harness, not just the lifecycle)

The steps above give an existing repo the campaign lifecycle. To get the FULL
harness — the part that measurably drives good session behavior — also wire
the project's CLAUDE.md (merge INTO the existing one; don't replace it):

1. **Session anchor line** (top of a "How we work" section): open Claude Code
   sessions at the trunk-checkout root, never inside a campaign worktree;
   drive worktree work from the anchor (cd or `git -C <worktree>`).
2. **Machine × environment matrix**: one row per machine (name / role / ssh /
   fs shared-or-separate), its environments underneath (name / type /
   activation command). If filesystems are separate, add: "code moves between
   machines by commit→push→pull only — no scp of repo files."
3. **Harness pointer**: "Working discipline lives in the ohd plugin
   (way-of-working · campaign-land · campaign-status · claude-md-sanity);
   lifecycle tooling is `tools/campaign.sh`."
4. **Facts block**: trunk / campaign naming / merge model / data location /
   deploy shape — whatever applies.

`assets/CLAUDE.md.template` in the plugin is the reference shape for all four.
After merging, run the claude-md-sanity skill once — it audits the result and
will keep auditing it as the project drifts.

`/ohd-checkup` automates this section: it runs the mechanical drift check
(assets/checkup.sh — template diff with config preserved, hook, state dir)
plus the CLAUDE.md wiring check above, and repairs per-item on approval. It
is also the RE-SYNC path after every plugin update ("하네스 점검"). This
guide remains the source of truth for what the pieces are; the command only
compares and repairs.
