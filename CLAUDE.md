# ohd — repo conventions

Public Claude Code harness plugin. Development happens on `main` directly
(dedicated repo, trunk hook intentionally skipped); the repo self-hosts its
own lifecycle via `tools/campaign.sh` (drift-guarded against the template in
CI). Larger changes go branch→PR→`code-review:code-review`→merge.

## RELEASING (version-gated cache — the #1 trap)

1. Bump `version` in `.claude-plugin/plugin.json`. Content changes DO NOT
   reach installed copies without a bump.
2. `node --test tests/*.test.mjs` → all pass. NEVER `node --test tests/`
   (directory form fails on some Node versions).
2b. Verification tier is MECHANICAL, not judgment ("micro release" is not an
   exemption — that rationalization shipped five unreviewed releases on
   2026-07-28): diff touches `skills/`, `commands/`, or `assets/` → run
   plugin-validator before tagging; AND the diff adds/changes ≳30 lines of
   instruction text or any script logic → also an independent review
   (branch→PR→`code-review:code-review`, or a review subagent on the diff).
   Docs/CHANGELOG-only diffs may tag directly.
2c. If the release changes a gate, route, or requirement that PROJECT
   sessions rely on (campaign.sh semantics, land ritual, review routes),
   put a single line `BEHAVIOR-CHANGE: <one sentence>` at the TOP of the
   CHANGELOG entry (line-initial, one per change) — /ohd-checkup relays
   exactly these lines to projects on sync. The project-facing judgment
   happens here, at authoring time, never downstream.
3. Release gates (clean before push; run over git-tracked files only):
   - `grep -rniE "nanof[o]rge|f[o]rge[^a-z]|f[o]rgen[a-z]|x[r]d|sr[u]uk|f[s]x|dip[a]rk" $(git ls-files)`
     — allowed hits ONLY: marketplace name `dipark`, plugin.json author,
     install/rollback commands referencing the `dipark` marketplace in
     README/USAGE-ko/CHANGELOG, ohd-setup's stale-plugin
     check (`deep-solve@dipark` uninstall command — same exception gate 2
     already grants), the LICENSE copyright line, the public conda channel
     `conda-f[o]rge`, this §RELEASING section's
     own grep-pattern/whitelist text (self-referential — the rule has to
     quote the words it's filtering for), and the literal blind-spot NAME
     `slashless-f[s]x` where docs/backlog.md #17 and the v0.6.0 land report
     record this gate's own history (same self-referential exemption).
     v0.7.0 widened these patterns, and the widening is written the way it is
     because a NARROWER first attempt shipped a real miss (backlog #17, #20):
     `f[s]x` DROPPED its leading slash — requiring one made every
     slash-evading form invisible, which is how two live strings reached
     v0.6.0. The ABBREVIATION shape is the one that got past a first pass:
     an internal name suffixed with a non-ASCII particle (`<name>` + 형)
     matches neither the hyphenated pattern nor a `[a-z]`-suffixed sibling,
     and one such token sat in a design doc — where there is NO whitelist —
     until review caught it by eye. So the suffix class is `[^a-z]`, not
     `[a-z]`, and the powder-diffraction project's name is matched by its
     3-letter stem rather than its full slug. Measured after that scrub: the
     stem forms cost ZERO extra hits, and `f[o]rge[^a-z]`'s only noise is
     `conda-f[o]rge`, whitelisted above by name. English "forging"/"forges"
     stay unmatched, which is the point — a gate whose output must be
     eyeballed past every release is a gate that trains dismissal, but a gate
     narrowed until it misses the live shape is worse.
   - `grep -rnE "Oppenheimerdinger/deep-solve|deep-solve@dipark|deep-solve:deep-solve" $(git ls-files)`
     — allowed ONLY: docs/backlog.md and CHANGELOG.md history links, README
     version note, USAGE-ko migration note, ohd-setup's stale-plugin check,
     and this section's own text.
   - `docs/superpowers/{specs,plans}/` have NO whitelist for INTERNAL names
     (policy hardened 2026-07-16 — internal project/company/machine NAMES
     are sensitive, not just secrets/IPs; the 2026-07-14 wholesale whitelist
     leaked 45 name hits, scrubbed in v0.4.9). New design docs must be
     written anonymized from the start (umbrella-proj, pkg-proj,
     gpubox-style placeholders); quoted grep patterns in docs use
     `internal-` in place of real prefixes. PUBLIC-BY-NECESSITY strings are
     exempt everywhere, including these docs: `dipark` (the marketplace name
     — it is in the README install command) and the historical
     `Oppenheimerdinger/deep-solve` / `deep-solve@dipark` references (an
     archived public repo). Sensitive = names that identify internal
     projects, the company, machines, or people — not the plugin's own
     public identity.
4. Commit everything, THEN tag `vX.Y.Z` on the final commit, push with tag
   (the tag must equal the pushed HEAD).
   (v0.1.0's tag trails main by one docs commit — known, do not force-move
   the published tag.)
5. `claude plugin update ohd@dipark` → restart/reload session
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
- **Lock-step (세 곳!)**: the greppable single-line phrase "required for the
  full workflow from v0.2" must appear in `commands/ohd-setup.md`,
  `README.md` (Requirements), and the way-of-working skill — THAT phrase is
  the invariant (surrounding wording may vary per surface). Change all three
  together; claude-md-sanity audits it.
- Open deviations and carried decisions live in `docs/backlog.md` — do not
  delete entries; mark them resolved with the fixing commit.
