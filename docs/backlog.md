# Backlog — carried decisions & known deviations

Carried from the absorbed deep-solve plugin (v0.2.2 — history:
https://github.com/Oppenheimerdinger/deep-solve, archived). Do not delete
entries; mark resolved with the fixing commit.

## 1. SYNTH candidate selection deviates from spec (isolated mode) — OPEN

The design spec says the SYNTH round adjudicates "the best answer of EACH
lineage"; the implementation (`skills/deep-solve/solve-converge.js`,
`buildSolverPrompt` SYNTH branch) picks the global top-2 by findings count —
two candidates from the SAME lineage can be selected and the only independent
cold derivation excluded, exactly in the thrashing scenario SYNTH exists for
(verified empirically with findings r1=1, r2=2, r3=3 → SYNTH received r1 +
its own REPAIR r2, excluded cold r3). Fix sketch: track a lineage id on
history entries (COLD/CONFIRM start a lineage; REPAIR inherits), select
best-per-lineage; one regression test mirroring the probe above. Deferred by
user decision (2026-07-07); revisit before heavy isolated-mode use.

## 2. Confirmation-disagreement conclusions leak into COLD pitfall lists — OPEN, low

After a confirmation disagreement, both conclusions enter `allFindings` and
reach later COLD solvers via the pitfall list — a mild anchoring channel into
the round that exists to escape anchors. Normal path goes to SYNTH first, so
this only fires when the forced SYNTH itself gets findings.

## 3. ohd-share — fsx-style deployment tooling — OPEN

snapshot/mirror deploy recorded by new-project but no executing tool yet.

## 4. SessionStart brief-hook scaffold option — OPEN

deferred from v0.3 spec.

## 5. Multi-host scaffolding — OPEN

v0.3 scaffolds at most one host; additional hosts are manual.

## 6. /ohd-adopt — existing-project adoption command — RESOLVED (absorbed by /ohd-checkup, v0.5.0)

new-project covers greenfield; existing repos get the lifecycle via the
drop-in guide but the CLAUDE.md harness wiring (anchor line, machine×env
matrix, pointers — the measured activation surface) is a manual merge today
(campaign-dropin.md §Adopting an EXISTING project). An interview-driven
command that merges those sections into an existing CLAUDE.md (judgment task
— prose-driven, not scripted) would close the gap. (2026-07-15)

RESOLUTION (2026-07-28): adoption is the everything-MISSING special case of
the harness drift check; `/ohd-checkup` covers both (mechanical drift via
assets/checkup.sh + semantic CLAUDE.md wiring vs the template, per-item
approval). No separate command shipped.

## 7. new-project FS=shared: promised safety rules never injected — OPEN

`commands/ohd-new-project.md` (Q4 option 3) promises "shared-tree safety
rules in CLAUDE.md" when filesystems are shared, but `assets/new-project.sh`
only special-cases `FS=separate` (git-only code movement note); no
`FS=shared` branch injects anything. Pre-existing before v0.5.6, surfaced by
its review (2026-07-28). Fix = a small template/script block (shared-tree
rules: worktree isolation, commit-before-reset) + a smoke assert.

## 8. RETIRES: sub-marker — move retired-route judgment to release time — OPEN

Pass 3b (v0.5.14) asks the checkup executor to judge "does this relayed
BEHAVIOR-CHANGE retire a mechanism?" per project per session. The 5-lens
review of PR #6 identified the strictly better third option the PR's own
binary framing missed: author a `RETIRES: <literal token>` sub-marker next
to BEHAVIOR-CHANGE at release time (§RELEASING 2c extension) — judgment
made once with full context, read-time reduced to literal grep, movable
into assets/checkup.sh's mechanical tier. Cost: brittle to paraphrase in
project docs (same missed-row failure the bounded-judgment version already
accepts, made deterministic). (2026-07-30)

## 9. promise-guard Stop hook — DEFERRED pending upstream + loop adoption

Sessions ending turns on declarative promises ("계속 진행하겠습니다") stall
unattended work (3 field occurrences). Research verdict (2026-07-30): the
community-standard fix is STATE-based stop-blocking (ralph-style loops with
completion conditions), not phrase heuristics on the last message — and
plugin-shipped Stop hooks using EXIT CODE 2 fail to continue (upstream
#10412 — CORRECTED 2026-07-31: the bug is exit-2-specific; ralph-loop's
JSON decision:block form works, field-verified by its loop re-firing across
iterations). ohd still ships no Stop hook of its own. Adopted instead: the way-of-working rule that an
autonomous mandate's first action is loop setup (v0.5.15). Revisit a
phrase-tripwire hook only if stalls recur UNDER loops — the plugin path is
technically open today (JSON decision:block form, per the correction
above); what keeps this deferred is the research verdict against phrase
heuristics, not the upstream bug.

## 10. Context exhaustion under a session-locked loop — OPEN (residual of PR #8)

Step 6 reframes empty iterations as missing dispatches but does not slow
the loop: the ralph-loop stop hook has no throttle, and when the critical
path is truly gated on one agent's wall-clock, short status turns burn
context (named, unsolved). Known levers: auto-compaction (session persists,
the hook's session-id lock holds) and checkpoint+fresh-session — but the
loop is session-id-locked, so a fresh session needs a re-arm trigger nobody
has designed for an unattended run. Revisit on field evidence of a loop
dying of context exhaustion. (2026-07-31)

## 11. `clean`'s scaffold anchor refuses docs it cannot see a verdict in — CARRIED (v0.5.22)

`campaign.sh clean` matches only the scaffold's `- result / verdict:` row, while
/ohd-checkup's land-report audit stays tolerant of decorated, translated and
`status:`-labelled rows. Deliberate asymmetry: their inputs differ (100% scaffold
coverage for campaigns `new` opened, 84 of 365 for legacy docs) and their failure
modes differ (a report row vs a destroyed worktree). Three rounds of trying to
tighten ONE shared regex failed, because `- **verdict**: LANDS` and
`- **VERDICT: nrxx-tiling genuinely reduces the peak.**` are lexically
near-identical.

Two carried costs, both fail-SAFE and both `FORCE_CLEAN=1`-escapable:
- a doc recording its verdict only as a substitute row is refused;
- a campaign whose doc pre-dated `campaign.sh new` (which leaves an existing doc
  alone) has no scaffold row at all, so it is refused until one is added. Not
  measured in the field — the corpus has no witness — so if this shows up as
  routine friction, the fix is `new` ensuring the row exists in a doc it adopts,
  not loosening the gate.

Also carried: the audit over-reports `- TODO: LANDED upstream?` (no checkbox) as
a possible land gap. Separating it from `- status: LANDED (PR #12 merged)` needs
a list of blessed label words; the audit's output is a prompt to look, so the
over-report is the cheaper error. (2026-07-31)

Two documented edge cases in `clean`'s gate, each with 0 witnesses in the
365-doc corpus, both left OPEN rather than fixed:
- fail-OPEN: the gate greps line by line, so a filled scaffold row quoted
  inside a ``` code fence satisfies it. Plausible only when a campaign's own
  subject is this harness (the docs that quote the row are ohd's own). Closing
  it means teaching a shell gate to track fence state — more machinery than the
  risk justifies while the witness count is zero.
- fail-CLOSED: a CHECKED box in front of the scaffold label
  (`- [x] result / verdict: LANDS`) is refused by `clean` while the audit
  accepts it. Documented in the die message and campaign-land Phase 4 instead
  of allowed, because a checkbox on the scaffold row is a hand-decorated row —
  the class `clean` refuses by design — and allowing only the checked variant
  would leave `- [x] LANDED as PR #7` refused for a reason that no longer reads
  as a rule. 0 of 365 docs write the row that way. If it ever shows up as
  routine friction, the fix is one optional token in the anchor plus an
  accept-matrix row. (2026-07-31)

## 12. v0.6.0 must narrow the brief-hygiene pointer — RESOLVED (v0.6.0)

v0.5.24's way-of-working brief-hygiene sentence is deliberately home-agnostic
("the project's reference docs where they exist") because `docs/reference/`
does not exist until v0.6.0 ships the tier — naming it early would be the
dead-pointer class claude-md-sanity flags. When v0.6.0 lands the tier, narrow
that sentence to name `docs/reference/` directly, or the read side never
points at the new home. One-sentence edit; recorded here so it is not lost
between releases (implementer finding, v0.5.24).

RESOLVED in v0.6.0, which ships the tier: force-multiplier 1's brief-hygiene
sentence now names `docs/reference/` FIRST, ahead of the campaign state doc and
`file:line`, and the routing table gains an orientation row pointing at the
tier instead of at a subagent scan.

## 13. The land-report scaffold heredoc still lacks the two new rows — OPEN (v0.6.0)

v0.6.0 adds `reference:` (Phase 4) and `verification:` (Phase 6) as NAMED
evidence-cell contents, but the blank land-report table is a heredoc inside
`assets/campaign.sh`, whose body this release deliberately does not touch (the
parity pair with `tools/campaign.sh`). So both rows are skill-carried prose —
the carrier class this harness's own record says decays. The spec's proposed
backstop was to have checkup's land-report audit flag post-adoption reports
missing the two rows; that is NOT shipped, because nothing on disk marks a
report as post-adoption, so the audit cannot separate a pre-v0.6.0 report from
a non-compliant one, and flagging every historical report contradicts
campaign-land's forward-only contract. Fix belongs to the next release that
touches campaign.sh: add both lines to the scaffold heredoc, and only then a
version- or date-scoped audit row becomes derivable. (implementer finding,
v0.6.0)
