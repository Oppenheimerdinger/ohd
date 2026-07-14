# campaign.sh drop-in guide (interview-driven)

Adds the worktree campaign lifecycle to an EXISTING repo. Every parameter is a
question with a recommended default — press through the defaults for a
standard single-repo project.

## The interview

| Question | Config | Default (recommended) |
|---|---|---|
| Trunk branch? | `TRUNK` | `main` |
| Where should worktrees live? | `WT_ROOT` | `$HOME/wt` |
| Campaign naming: free-form or numbered `NNN-slug`? | `NAMING` | `free` (numbered suits milestone-style projects) |
| Who merges? One anchored coordinator session, or a GitHub review gate? | `MERGE_MODEL` | `coordinator` for a single-owner repo; `review-gate` for collaborative repos |
| Where do campaign state docs live? | `STATE_DIR` | `docs/campaigns` |
| Is there a pinned dependent/fork repo? | `DEP_DIR`, `DEP_TRUNK`, `PIN_FILE` | none (enables the `pin` subcommand when set) |
| Protect the trunk with a docs-only pre-commit hook? | — | yes for shared repos; **skip** for repos that intentionally develop on trunk (this plugin repo itself skips it) |

## Install

1. Copy `assets/campaign.sh` from the plugin into the repo as
   `tools/campaign.sh`; edit the config block at the top with the interview
   answers (env `CAMPAIGN_*` variables override at runtime); `chmod +x`.
2. If trunk protection was chosen: copy `assets/install-hooks.sh` to
   `tools/install-hooks.sh` and run it once per clone
   (`CAMPAIGN_TRUNK_ALLOW` adjusts the allowed-path regex).
3. Smoke: `tools/campaign.sh new scratch-test` → confirm the worktree, branch,
   and state doc appeared → `tools/campaign.sh abort scratch-test`.

## Daily lifecycle

`new <name>` → work inside the worktree → `land <name>` (push + PR; the
campaign-land skill carries the full ritual) → merge per your model →
`status <name>` to verify (squash-safe) → `clean <name>`. Stuck/abandoned?
`abort <name>` (keeps the remote branch unless `--purge`). `list` shows open
campaigns so none go stale silently.
