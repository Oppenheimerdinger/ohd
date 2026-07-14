# Changelog

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
