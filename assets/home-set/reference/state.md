# State registry

What is in flight RIGHT NOW: live runs, active campaigns and worktrees, and the
policies that choose between artifacts ("best checkpoint" and friends). One
registry file — state does not get a second home.

**This file is EXEMPT from the executable-truth format law** the rest of the
tier obeys: a live run has no test to cite. Two gates stand in for it, both
checked by `/ohd-checkup`:

1. **pointer targets must exist** — a path that has been deleted is a lie;
2. **dated-claim expiry: any `as of <date>` older than 14 DAYS is flagged** —
   refresh the line or delete it.

Whoever starts or stops a run, campaign, or worktree edits this file in the
same breath. A rotted registry MISDIRECTS, which is worse than an empty one: if
the staleness gate goes red twice with no action, delete the entries rather
than let them lie.

## Live runs

- (example) sweep `alpha`, started as of <YYYY-MM-DD>, owner: <who> — `runs/alpha/`

## Active campaigns / worktrees

- (example) campaign `refactor-io` OPEN as of <YYYY-MM-DD> — `docs/campaigns/refactor-io.md`

## Policies (what "best" means here)

- (example) "best checkpoint" = lowest validation loss, ties broken by latest step, as of <YYYY-MM-DD> — `configs/eval.yaml`
