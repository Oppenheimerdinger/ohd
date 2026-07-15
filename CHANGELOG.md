## v0.4.4 (2026-07-15)

- Drop-in guide: new "Adopting an EXISTING project" section — full harness
  wiring for existing repos (session anchor, machine×env matrix, pointers,
  facts), merged into the existing CLAUDE.md and audited by claude-md-sanity.
  /ohd-adopt automation added to the backlog.

## v0.4.3 (2026-07-14)

- Session-anchor guidance in four places (scaffolded CLAUDE.md "How we work"
  header, new-project next-steps, USAGE-ko, README): open Claude Code sessions
  at the trunk-checkout root, never inside a campaign worktree; drive worktree
  work from the anchor. Smoke asserts the scaffolded guidance.

## v0.4.2 (2026-07-14)

- new-project: `--env name:none` — scaffolds no files, records "managed
  manually" in the CLAUDE.md matrix (non-Python / manually-managed setups;
  makes the harness genuinely field-agnostic). Interview Q9 updated; smoke
  assert added.

## v0.4.1 (2026-07-14)

Activation-wiring fixes, driven by a 5-probe live simulation of a fresh
colleague session (3 FIRED / 2 PARTIAL / 0 MISSED) plus a wiring audit:

- deep-solve description: the "mention /deep-solve when stuck" fallback is now
  affirmative (was "at most briefly mention" — measured not to fire).
- review-to-convergence description: carries the multi-reviewer workflow
  escalation rule (3+ files / ~100+ lines) — moved to where activation
  actually happens (was 2 hops deep inside way-of-working's body).
- way-of-working: completed implementation is explicitly a deliverable
  (outside subagent-driven flows it gets an explicit review-to-convergence
  pass); **loop termination is judged by an independent evaluator agent,
  never by the looping session itself**.

## v0.4.0 (2026-07-14)

- **Plugin renamed: `oppenheimerdinger` → `ohd`** (repo:
  https://github.com/Oppenheimerdinger/ohd — old URLs redirect). Migrate an
  existing install:

      claude plugin uninstall oppenheimerdinger@dipark
      claude plugin marketplace remove dipark
      claude plugin marketplace add Oppenheimerdinger/ohd
      claude plugin install ohd@dipark

- No functional changes; skill ids now `ohd:<skill>`.

# Changelog

## v0.3.1 (2026-07-14)

- fix: new-project preflight hardening (trunk ref-format, env/node name
  validation, host-repo whitespace, github format, repo-local-identity probe
  gap), portable sed (macOS), CLAUDE.md template-comment residue, gh
  partial-failure guidance, post-mkdir failure hint; backlog carries v0.3
  exclusions.

## v0.3.0 (2026-07-14)

- New: `/ohd-new-project` — interview-driven research-project scaffolder
  (deterministic `assets/new-project.sh`; campaign lifecycle instantiation,
  protected trunk, machine×env matrix CLAUDE.md, external-code hosts
  machinery with adopt-safe setup.sh, data symlink, gh repo creation).
- New: 3-profile network-free smoke in CI.
- way-of-working routing table gains the new-project row.

## v0.2.2 (2026-07-14)

- fix: clean refuses never-pushed campaigns (data-loss guard, new smoke
  assertion); clean/status stacked-PR verification tightened (per-PR base
  matching); pin robustness (PIN= guard, portable sed, pathspec commit); list
  handles spaced paths; CI guards assets↔tools drift; doc polish.

## v0.2.1 (2026-07-14)

- fix: campaign.sh status treats a FAILING gh call as UNVERIFIED (was:
  silently treated as no-PRs → false UNMERGED on non-GitHub remotes / auth
  failures; caught by CI)

## v0.2.0 (2026-07-14)

- New skills: `way-of-working` (quality routing, delegation/review
  force-multipliers, lightest-first persistence loops, collaboration
  discipline), `campaign-land` (generalized land ritual), `campaign-status`
  (squash-safe merge verdicts).
- New: parameterized `assets/campaign.sh` worktree lifecycle template +
  `assets/install-hooks.sh` + interview-driven drop-in guide
  (`docs/campaign-dropin.md`), smoke-tested in CI.
- Self-hosted: this repo now uses `tools/campaign.sh` (hook skipped —
  intentional trunk-direct development).

## v0.1.1 (2026-07-14)

- Release-gate hygiene: untrack the local ops note
  (`docs/migration-checklist.md`) so it no longer trips the repo's own
  release gates; it stays on disk, now gitignored.
- Rollback recipe fix: the pin-old-version recipe in README now removes the
  `dipark` marketplace before adding the clone's (same-named) marketplace,
  avoiding a conflict, and explains how to return to the live version.
- README fallback wording: the Requirements section now says deep-solve's
  isolated mode falls back to a manual Agent-tool loop when the Workflow
  tool is absent (grounded mode is unaffected).
- Lock-step rule now names all three label locations
  (`commands/ohd-setup.md`, `README.md`, and the future way-of-working
  skill) instead of two.
- RELEASING tag discipline clarified: commit everything, then tag on the
  final commit, push with tag; noted that v0.1.0's tag trails main by one
  docs commit (known, do not force-move the published tag).
- docs/USAGE-ko.md heading nesting: deep-solve-specific sections (언제
  쓰나 / 실행 흐름 / 두 가지 모드 / 옵션 / 결과 읽는 법 / 팁) are now
  demoted to `###` so they nest under `## deep-solve 사용법`.

## v0.1.0 (2026-07-14)

- Initial public release. Absorbs deep-solve v0.2.2 verbatim (formerly the
  standalone `deep-solve@dipark` plugin).
- Promotes `claude-md-sanity` (anonymized) and `review-to-convergence`
  (+ scope guard) to this harness.
- Adds `/ohd-setup` — environment checkup with approved-install flow.
- Completes migration from the standalone deep-solve plugin.
