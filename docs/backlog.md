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

## 3. ohd-share — shared-dir deployment tooling — OPEN

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

## 12. v0.6.0 must narrow the brief-hygiene pointer — RESOLVED (v0.6.0, dd9887b)

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

## 13. The land-report scaffold heredoc still lacks the two new rows — RESOLVED (v0.7.0, 96f2eb2)

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

RESOLVED in v0.7.0: that release is the one that touches campaign.sh, so all
three of the blockers above are now false and the paragraph should be read as
history. `land --report` seeds both cells with the literal prompts (96f2eb2) AND
emits an explicit era marker, `<!-- ohd:land-report-scaffold v0.7.0 -->`.

The marker is the correction this entry is really about. The original plan —
and the spec's own wording — made the seeded PROMPT the era boundary, on the
belief that "nothing on disk marks a report as post-adoption". The prompts
cannot do that job: `reference:` and `verification:` became MANDATED ritual
vocabulary at v0.6.0, so a report written before the scaffold existed
legitimately contains both. This repo's own two land reports are the proof —
written 2026-08-06 under v0.6.0's contract, four days before the scaffold
landed, and counted as scaffold-born by every token-based version of the rule.
No anchor position fixes that, which is why two rounds of moving the anchor
(narrowed to the named cell in a table line, then widened off cell-initial
because real reports write the token after the evidence text) each fixed a
real defect and left the era boundary exactly as broken.

What works is a literal only the scaffold emits. On that marker the scoped
audit row shipped as the advisory `ritual-bypass` sub-count — the
"version- or date-scoped audit row" this entry predicted would become
derivable, needing neither a version nor a date. Its content checks read the
land-report REGION rather than the whole doc, so a `sanity:` in unrelated
prose cannot attest a land report.

## 14. The structure row cannot say when the last full audit ran — OPEN (opened v0.6.0)

v0.6.0's default structure row ships the honest string `last full audit: no
record`: the structure report is output-only, so nothing on disk marks that a
run happened. The obvious quick fix — have `--structure` stamp a dated line
into `docs/reference/state.md` — was tried and REJECTED on measurement, not on
taste. state.md is exactly the file the default reference row gates for
`as of <date>` claims older than 14 days, so the stamp turns every structure
run into a guaranteed `reference | STALE` row 14 days later (reproduced: a
15-day-old stamp yields `state.md dated claim(s) older than 14 days`). That
breaks the rule the default run is built on — a default run is a drift doctor
and must never nag a project into structural work — and it does so on a project
whose only sin was running the opt-in mode once. Unblocking condition: an age
signal scoped AWAY from the default reference row (its own stamp file or row,
with its own staleness policy), which is a design pass in its own right, not a
line of code. Until then the row says "no record" rather than implying it
knows. (implementer finding, v0.6.0)

## 15. provenance_block fabricates `git=n/a-dirty` outside a git tree + simplifier worth-doing batch — RESOLVED (v0.6.1, 33284ea)

The land-time simplifier pass (report-only, over the merged v0.6.0 diff) found
one real defect and five worthwhile simplifications; none block v0.6.0
correctness in its intended (in-repo) use, so they ship as a follow-up batch:
- **Defect**: `assets/probes/provenance_block.sh:78-79` — outside a git work
  tree `git diff --quiet` exits 129 and the `||` records `git=n/a-dirty`, a
  fabricated dirty flag in the one artifact whose job is honest provenance.
  One-token fix: `[ "$GIT" = n/a ] || git diff --quiet 2>/dev/null || GIT="$GIT-dirty"`.
- checkup.sh: duplicated always-loaded detail string (217-221); solidation
  candidate rule written twice for the SAME consumer pair (337-344 vs 457-467 —
  not the census/audit split, which stays); per-line `sed` re-slice in the
  config loop (105/115); `--sync` guard spelled twice (85-90).
- ohd-checkup.md:27-31 restates canonical exit-code-shaped text directly above
  its own DRY invariant — cut to a pointer.
Eleven marginal items and four considered-and-rejected (incl. probe `die`/`need`
sharing — breaks standalone-copyability) are in the land records; do not
re-litigate the rejected set without new evidence.

RESOLVED in v0.6.1: the defect is fixed (the probe no longer fabricates a dirty
flag outside a git tree — `git=n/a` stays `n/a`, pinned by a probes-smoke case
that was RED first), and all five checkup/command simplifications shipped
output-identical, verified row-by-row over a 26-scenario fixture sweep. The
worth-doing set shipped in v0.6.1; the marginal and rejected sets remain the
record of what was considered.

## 16. Project-relay lines from two field incidents — OPEN (opened v0.6.0 land, v0.6.1 candidates)

Two GPU-research field sessions independently hit failure modes the harness
already guards against in its OWN development but never relays to projects.
The v0.6.1 shape is relay text (scaffold/skill lines), NOT new machinery:
- **Code→doc pointers** (read-direction gap) — SHIPPED v0.7.0 (bc44181): a multi-consumer physics helper
  was misused because its purpose lived only in a campaign doc the session
  never opened — doc→code pointers (`<claim> — <file:line>`) serve audits, but
  working sessions read CODE first. What shipped is 2 conventions.md scaffold lines —
  helpers whose output is a physical quantity / split index with ≥2 consumers
  carry `VALID FOR / NOT VALID FOR` + `DERIVATION: <doc#anchor>` in the
  docstring. Scope-limited by design (blanket application is ceremony).
- **Absence-with-reason**: a structurally-absent risk gets a recorded reason,
  never a vacuous guard (two injected "protections" proved VACUOUS in the
  field — they asserted properties the code didn't hold and didn't need).
- **r2c round-cap relay**: ">3 rounds = suspect the design/scope" exists only
  in harness-dev lore; the field session self-diagnosed over-build at round 5.
  Candidate: one sentence in review-to-convergence.
- **Run-artifact router row**: the writing router's rows are doc-centric; run
  artifacts (figures/data/logs) have no named row, and a field session's 25
  files landed flat before being split `<date>-<campaign>/{plots,data}/`.
  Candidate: one router row + one conventions.md scaffold line.

## 17. Land-time sanity residuals: slashless-fsx gate blind spot, whitelist pairing, description budgets, probe headroom — OPEN (opened v0.6.0 land)

- SHIPPED v0.7.0 (2b73e51, corrected 2d41540 — see #20): Release gate 1's `/f[s]x` pattern required a leading slash, so slash-evading
  forms (a project-slug path fragment, a "-style" prose reference) were
  invisible; the two live instances were scrubbed at v0.6.0 land. DONE: the
  slash was dropped and the whitelist re-derived rather than eyeballed — the
  project-slug form's marketplace name is exempted by name, and the widening
  was corrected again in review (see #20).
- WATCH pairing (from the same audit): CLAUDE.md's gate whitelists pass ONLY
  because §RELEASING bullet 3 exempts the marketplace name in
  docs/superpowers/{specs,plans} — the whitelist lines and bullet 3 must move
  together; neither may be edited alone.
- Skill description budget is "~50 words" but claude-md-sanity measures 87 and
  deep-solve 78 (others ≤61). deep-solve was trimmed to 60 words, SHIPPED
  v0.7.0 (3078c7a). STILL OPEN for claude-md-sanity's 87: trim it or annotate
  the convention.
- `assets/probes/mutation_run.sh` sits at 117 of its 120-line budget and is
  the file that attracts explanatory prose; next substantive edit likely trips
  the size gate for unrelated reasons. Decide deliberately: move prose out or
  move the cap (fleet-flagged at v0.6.0 land).

## 18. solve-converge.js cannot evaluate the severity terminal — OPEN (opened v0.7.0)

B1 made the review terminal severity-anchored (zero Critical, zero Important;
residuals Minor-only, each disposed). The isolated-mode runner's finding schema
has NO severity field — `SOLVE_SCHEMA`/`REVIEW_SCHEMA` findings carry
`summary`/`detail` only — so the runner cannot evaluate that terminal and still
converges on a count. Named non-ship, not an oversight: the prose skill governs
the terminal, and the runner's own COLD confirmation pass is its independent
check. Deliberately NOT shipped in v0.7.0 to keep B1 one wording intervention
rather than a schema migration. Revisit trigger: a runner-converged answer is
later contradicted by a defect that a severity label would have held open.

## 19. Issue #7 disposition: retired-route fossils — OPEN (recorded v0.7.0)

Issue #7 stays OPEN, deliberately and not by neglect. Recording the
disposition here so it is not re-triaged from scratch by every session that
reads it, and because v0.7.0's issue-comment draft for #7 states that this
entry exists.

PREFERRED FUTURE FORM: a ONE-TIME full-history sweep for references to
retired routes, not an ongoing gate. The failure #7 describes is a fossil
problem — text that was true when written and was never revisited — so its
population is bounded by history rather than generated by ongoing work. A
permanent check would run forever against a set that stops growing, which
costs more attention than the fossils cost.

NOT scheduled: the sweep is cheap to run and expensive to keep current, so it
is worth doing once, when there is a reason to believe the population changed.

Revisit trigger: the next fossil incident — a session mis-briefed by a
reference to a route that no longer exists. That incident is what turns the
one-time sweep from speculation into scheduled work, and #7 is where it gets
recorded.

## 20. Privacy-gate abbreviation shape: narrowing a pattern bought a miss — RESOLVED (v0.7.0 review r1)

v0.7.0 first shipped the no-hyphen internal-name sibling narrowed to an
`[a-z]`-suffixed form, justified by a noise measurement (7 tree hits, all
`conda-forge` or English inflections). Round-1 review found the narrowing let
a real leak through: an internal project name suffixed with a non-ASCII
particle (`<name>` + 형) in `docs/superpowers/specs/`, which is exactly where
the hardened policy grants NO whitelist. Two projects were affected, three
tokens, all anonymized to the doc's existing placeholder style.

Fixed by matching the suffix class as `([^a-z]|$)` — the `|$` alternation
because a bare negated class cannot match at end of line, a gap with no live
instance today and therefore exactly the acceptance bar this entry warns
against — and the second project by its 3-letter stem; `conda-forge` becomes a named whitelist entry rather than a
reason to narrow. Measured after the scrub: the stem forms add zero hits.

CARRIED LESSON, which is why this entry stays: the gate did not catch this —
a human reviewer did, by eye. A privacy pattern tuned on false-positive noise
optimizes the wrong side of the tradeoff, because the cost of one miss is
unbounded and the cost of one extra eyeballed hit is seconds. Prefer a named
whitelist entry over a narrower pattern. Revisit trigger: any future proposal
to narrow one of these patterns for noise reasons.
