# oppenheimerdinger — repo conventions

Public Claude Code harness plugin. Development happens on `main` directly
(dedicated repo); campaign self-hosting is reconsidered in v0.2.

## RELEASING (version-gated cache — the #1 trap)

1. Bump `version` in `.claude-plugin/plugin.json`. Content changes DO NOT
   reach installed copies without a bump.
2. `node --test tests/*.test.mjs` → all pass. NEVER `node --test tests/`
   (directory form fails on some Node versions).
3. Release gates (clean before push; run over git-tracked files only):
   - `grep -rniE "the-company|internal-|validation-proj|gpubox|<bigfs>|dipark" $(git ls-files)`
     — allowed hits ONLY: marketplace name `dipark`, plugin.json author,
     install commands `@dipark` in README/USAGE-ko.
   - `grep -rnE "Oppenheimerdinger/deep-solve|deep-solve@dipark|deep-solve:deep-solve" $(git ls-files)`
     — allowed ONLY: docs/backlog.md history links, README version note,
     USAGE-ko migration note, ohd-setup's stale-plugin check.
4. Commit, tag `vX.Y.Z`, push with tag.
5. `claude plugin update oppenheimerdinger@dipark` → restart/reload session
   → verify.

## Conventions

- Skill description budget ~50 words. Korean trigger phrases are a feature —
  include them.
- Generic-word commands take the `ohd-` prefix (first case: `/ohd-setup`) to
  avoid launcher collisions with other plugins.
- A command and skill with the SAME NAME in one plugin collide in the
  launcher. `commands/deep-solve.md` inlines its skill via
  `@${CLAUDE_PLUGIN_ROOT}` for exactly this reason — do NOT "simplify" it
  into a Skill-tool call.
- **Lock-step (두 곳!)**: the superpowers dependency label ("recommended —
  required for the full workflow from v0.2; v0.1 works without it") lives in
  BOTH `commands/ohd-setup.md` and (from v0.2) the way-of-working skill.
  Change them together. claude-md-sanity audits this rule.
- Open deviations and carried decisions live in `docs/backlog.md` — do not
  delete entries; mark them resolved with the fixing commit.
