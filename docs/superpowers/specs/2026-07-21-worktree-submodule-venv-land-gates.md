# Harness fix spec — `campaign.sh new` submodule init, worktree test hint, land verdict gate

> **Handoff spec.** Written 2026-07-21 from a ml-proj session that ran two full
> campaigns end-to-end and hit these gaps. Self-contained — implement in the ohd
> repo (dev tree, `Oppenheimerdinger/ohd`); no
> prior-session context needed. Three independent fixes (A/B/C), A is the
> high-value one.

## Background

ohd's campaign lifecycle CLI is `assets/campaign.sh`, copied verbatim into each
scaffolded project as `tools/campaign.sh` (only the config block —
`TRUNK/NAMING/MERGE_MODEL/…`, lines 7-11 — is rewritten by
`assets/new-project.sh::set_default`). So a fix to `assets/campaign.sh` reaches
every future project; **existing projects must re-sync their `tools/campaign.sh`
by hand** (they are byte-identical to the template modulo the config block —
verified for ml-proj).

`cmd_new` (line 48) is currently, in full effect:
```
git fetch origin -q
git worktree add "$wt" -b "$n" "origin/$TRUNK"    # line 54
# … writes the docs/campaigns/<name>.md state doc, prints "worktree: …" (line 67)
```

## Gap A (HIGH VALUE) — `cmd_new` does not initialize git submodules

**Problem.** `git worktree add` deliberately does NOT populate submodules. A
project that uses submodules therefore gets a **broken worktree on every
`campaign.sh new`**: the submodule paths are empty, so any test/import touching
them fails.

**Evidence (ml-proj, this session).** ml-proj has two submodules
(`.gitmodules`: `external/sub-a`, `external/sub-b`). A fresh campaign worktree
had empty `external/`, so ~10 unit tests errored with `No module named 'subpkg'`
(a package under `external/sub-b/`). This looked like "pre-existing failures"
and was one `git submodule update --init external/sub-b` away from a true green
baseline (491 → after init). A less careful run would have merged on a false-green
baseline or dismissed a real regression as pre-existing. This is exactly the
silent-failure class the campaign harness exists to prevent, sitting in the
harness itself.

**Fix.** In `cmd_new`, immediately after the `git worktree add` (line 54), add:
```bash
if [ "${CAMPAIGN_INIT_SUBMODULES:-1}" != "0" ] && [ -f "$ROOT/.gitmodules" ]; then
  echo "init submodules in worktree (set CAMPAIGN_INIT_SUBMODULES=0 to skip)…"
  git -C "$wt" submodule update --init --recursive || \
    echo "WARN: submodule init failed in $wt — run 'git -C $wt submodule update --init --recursive' manually" >&2
fi
```
- `$ROOT` is already computed at line 33 (`git rev-parse --show-toplevel`).
- Guarded on `.gitmodules` existing, so it is a **no-op for non-submodule
  projects** — safe to ship in the template unconditionally.
- `CAMPAIGN_INIT_SUBMODULES=0` escape hatch for campaigns that don't need the
  (potentially slow/large) submodule clone.
- Non-fatal on failure (warn, don't `die`) — a submodule-init hiccup shouldn't
  destroy an otherwise-created worktree.

**Acceptance.** In a submodule-using clone (ml-proj works): `campaign.sh new X`
then `ls "$HOME/wt/X/external/<submodule>/"` shows the populated submodule; in a
no-submodule clone, `new` behaves exactly as before (no new output, no error).
Note: linked-worktree + submodule works on modern git (≥2.30) — the submodule
git-dirs are shared via the superproject's `modules/`; verify on the target git
version.

## Gap B (small) — `cmd_new` gives no worktree test/env hint

**Problem.** `.venv/` is gitignored (`new-project.sh` `.gitignore` block), so a
new worktree has **no virtualenv**. The correct way to test in the worktree is
project-specific (e.g. point `PYTHONPATH` at the worktree `src` and use the trunk
clone's interpreter), and nothing tells the operator/subagent that. This session
lost time to a subagent guessing the test invocation.

**Fix.** Add a config var to the block at lines 7-11:
```bash
WORKTREE_HINT="${CAMPAIGN_WORKTREE_HINT:-}"   # optional; {wt} is substituted with the worktree path
```
and at the end of `cmd_new` (near the `worktree:` echo, line 67), if set:
```bash
[ -n "$WORKTREE_HINT" ] && echo "${WORKTREE_HINT//\{wt\}/$wt}"
```
Template default empty (stays generic — not every project uses PYTHONPATH+trunk-venv).
`new-project.sh` needs no change (leave `WORKTREE_HINT` empty; projects fill it).
**ml-proj sets** (in its `tools/campaign.sh` config block):
```bash
WORKTREE_HINT="${CAMPAIGN_WORKTREE_HINT:-test: PYTHONPATH={wt}/src ~/projects/ml-proj/.venv/bin/pytest -q -m \"not slow\"  (worktree has no .venv)}"
```

**Acceptance.** With `WORKTREE_HINT` set, `campaign.sh new X` prints the hint with
`{wt}` replaced by the real path; empty → prints nothing new.

## Gap C (debatable — decide the strength) — land ritual is unenforced at the point of no return

**Problem.** `cmd_land` is push + PR only; the land ritual (validation, review,
**docs-same-land**, land report) lives in the `campaign-land` skill as prose. The
skill's own text says "rules that live only as prose get skipped; artifacts
don't" — yet its mandatory land-report is chat output, read by no script.
`cmd_clean` (line 148) already mechanically refuses to tear down unless verifiably
merged (lines 158/163) — a real gate — but nothing checks that the **state doc
was updated with a verdict** (Phase 4, "docs in the SAME land"), which is the one
Phase-4 artifact that lives on disk.

**Evidence (this session).** A campaign's land ran the phases from memory instead
of re-invoking the skill, and printed the land-report table AFTER `cmd_clean`
deleted the worktree — the gate gated nothing. The retro verification passed that
time, but the worktree was already gone.

**Fix (recommended: hard gate with bypass, matching `cmd_clean`'s existing
refuse-style).** In `cmd_clean`, AFTER the existing merge verification passes and
BEFORE the teardown, add:
```bash
doc="$STATE_DIR/$n.md"
if [ "${FORCE_CLEAN:-0}" != "1" ] && [ -f "$doc" ] && \
   ! grep -qiE 'verdict|LANDS|final review|result[ /]*:' "$doc"; then
  die "refusing clean: '$doc' has no land verdict/result line — update the state doc (campaign-land Phase 4) first. Bypass: FORCE_CLEAN=1 campaign.sh clean $n"
fi
```
**Decision the ohd session must make:** the grep pattern couples to state-doc
wording conventions. Options: (i) hard `die` as above (consistent with the two
existing `cmd_clean` refusals; bypass `FORCE_CLEAN=1`); (ii) downgrade to a
`WARN:` to stderr (softer, but that's prose again). Recommend (i) with a
permissive pattern; tune the alternation to match the actual verdict wording the
`campaign-land` skill writes (check the skill + a couple landed
`docs/campaigns/*.md`). If the state-doc template doesn't reliably contain such a
line, either (a) extend the `cmd_new` state-doc heredoc with an explicit
`- verdict:` field, or (b) drop C — do not ship a gate that false-fails a correct
land.

## Out of scope (noted, not part of this spec)

- The `.superpowers/sdd/task-N-brief.md` scratch collision (a fresh campaign's
  subagent got a PRIOR campaign's task-2 brief) is a **superpowers SDD-skill**
  artifact, NOT ohd — its `scripts/task-brief` writes into a repo-shared
  `.superpowers/sdd/` with generic `task-N` names and prints the trunk path while
  writing to the worktree. ohd prescribes per-campaign `docs/campaigns/<name>.md`
  and never touches `.superpowers/`. Fixing it belongs in superpowers, or in
  campaign-scoped brief paths (`.superpowers/sdd/<campaign>/task-N`).
- Full per-worktree venv automation (`--local-venv`/symlink) was considered in
  `docs/superpowers/specs/2026-07-14-*` and dropped; Gap B's hint is the
  lightweight substitute, not a revival of that.

## Rollout

1. `assets/campaign.sh` — apply A + B (+ C if adopted). `assets/new-project.sh` —
   no change needed (B's config default is empty; A is generic).
2. Sync each existing submodule-using project's `tools/campaign.sh` to the new
   template (they are identical modulo the config block). **ml-proj** is the
   first consumer: apply A + B (with its `WORKTREE_HINT` value above) + C, via a
   ml-proj campaign (`tools/campaign.sh` is code → not docs-only, so it lands
   through a worktree branch, not a direct trunk commit).
3. Version bump + CHANGELOG in ohd; projects re-pull the plugin.
