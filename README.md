# oppenheimerdinger

A research-and-development harness plugin for Claude Code, built for people
who are strong researchers but not professional developers. It encodes one
working style: interview-driven decisions, exactly one recommendation per
fork, honest gates over enforcement.

한국어 안내: [docs/USAGE-ko.md](docs/USAGE-ko.md)

## Install

    claude plugin marketplace add Oppenheimerdinger/oppenheimerdinger
    claude plugin install oppenheimerdinger@dipark

Then restart the session (or `/reload-plugins`) and run `/ohd-setup`.

## What's inside (v0.1)

- `/deep-solve` — user-gated hard-problem convergence harness
  (isolated / grounded modes)
- `review-to-convergence` — verify a finished deliverable to zero findings
- `claude-md-sanity` — audit a repo's CLAUDE.md / memory files for drift
- `/ohd-setup` — check (and on approval install) the plugins this harness
  builds on

Roadmap: v0.2 way-of-working + campaign-land/status · v0.3 new-project.
Design docs live in `docs/superpowers/specs/`.

## Version note

oppenheimerdinger 0.1.0 includes **deep-solve v0.2.2 verbatim** (formerly the
standalone `deep-solve@dipark` plugin — history:
https://github.com/Oppenheimerdinger/deep-solve, archived). If you still have
the old plugin installed, remove it to avoid double registration:

    claude plugin uninstall deep-solve@dipark

## Requirements

- deep-solve's isolated mode runs on the Claude Code **Workflow tool**;
  without it the skill announces the limitation and falls back (grounded /
  manual loop).
- **superpowers**: recommended — required for the full workflow from v0.2;
  v0.1 works without it. **oh-my-claudecode**: optional (ralph persistence
  mode only). `/ohd-setup` checks both.

## Uninstall / rollback

    claude plugin uninstall oppenheimerdinger@dipark

To pin an older version: uninstall, `git clone` this repo, `git checkout
vX.Y.Z`, then `claude plugin marketplace add /path/to/clone` and install —
a local marketplace installs whatever the working tree contains.

## Test

    node --test tests/*.test.mjs

## License

MIT
