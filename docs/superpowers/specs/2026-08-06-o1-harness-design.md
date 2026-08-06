# "O(1) harness" — design of record (v0.5.24 candidate)

Status: three-lens top-model design review CONVERGED (minimality / mechanism /
blind-spot, 2026-08-06); terminal pass pending. Evidence: two converged project
audits (project A: 7-round, project B: v3 + adversarial review), one live
light-task trace, and fresh corpus measurements by all three lenses.

## The goal

Work quality is right; the cost of one unit of work grows with project size N.
Target: make the marginal cost of the Nth question/task ~independent of N,
without touching the quality machinery (review/solve spend is accepted).
Owner's framing: sessions must manage a project like professional developers —
reuse instead of regenerate, organize instead of accumulate, look up instead of
re-derive.

## What the evidence established

- The audits measured mostly CONSTANTS (one 25M-token session; a 2.4M doc
  rebuild; coordinator shell habit at 46.8% of intake). The only direct
  observation of the SCALING term is the light-task trace: 11 tool calls to
  answer "plot bands from the best checkpoint of the current run", nearly all
  spent re-deriving settled facts — what is training where, what "best" means,
  that a finished, well-built plot pipeline already exists, and its two gotchas
  — knowledge that then evaporated with the session.
- Dominant recurring terms, measured: always-loaded mass O(N_age) × every
  actor-wake (139KB project CLAUDE.md of which 65% is one incident-narrative
  section; a 168KB plan file all workers must read; ~340KB before a worker's
  first useful token); archaeology-per-question against a 42,714-line narrative
  with a 34-line reference tier (1:1,256); per-campaign RE-IMPLEMENTATION of
  verification the harness itself mandates by name but does not ship (known-bug
  recurrence measured: one trap re-hit 3×; two hand-rolled greps that could
  never match); orphan verification code accumulating with no failure path
  (29 of 62 bench/tools files: no test, no inbound reference; a FIXED bug
  stayed alive 8 days in an untested duplicate).
- The field already graduates knowledge ORGANICALLY (live-run guides, capability
  matrices grown by hand in three repos) — but the only destination is each
  project's capped CLAUDE.md, so graduation overflows the hot tier. Demand is
  proven; the destination and the gates are what is missing.
- The harness's own exhaust has the same diseases: its auto-memory release
  narrative is 20-30× the size of every other memory file and duplicates the
  repo CHANGELOG; its plans/specs corpus is the fastest-growing doc class in
  the youngest repo (81% of the doc corpus at 3 weeks); its own dev sessions
  left six copies of the same script under scratchpad. The rules below apply to
  the harness itself.

## The independence discriminator (what this design must NOT break)

Independent re-derivation is the fleet's quality mechanism — independent
reviewers re-measuring is what caught real defects, repeatedly. The audits'
finding is not "re-derive less"; it is that independence's ONLY implementation
is an agent-scan. The principle: **independence lives in the judgment, not in
the scan.** A reference line that cites executable truth lets a consumer
re-run the probe — independent evidence at tool cost — instead of trusting a
cached result or re-deriving by agent-scan.

| situation | independence required? | correct implementation |
|---|---|---|
| adversarial review of NEW work (round 1) | YES — reviewer must not inherit author assumptions | fresh-context agent, full derivation; this spend is untouched |
| banking a load-bearing claim the first time | YES | independent probe + control (existing 3-PASS class) |
| convergence rounds 2+ | scoped | fix-diff only (already doctrine since the convergence-log release) |
| settled fact with an executable anchor | evidence yes, agent-scan no | RE-RUN the cited test/gate (tool call); never serve the cached result as truth |
| orientation: what exists, where, interfaces | NO — independence adds nothing to "does this pipeline exist" | reference lookup; archaeology only when the reference has no answer |

This is why S1's format law is constitutive: a reference tier whose lines are
prose claims would TRADE independence for cheapness; one whose lines are
pointers at runnable checks keeps both.

## The home-set (4 homes + 2 cross-cutting scopes)

| home | artifact | writes | reads | staleness gate |
|---|---|---|---|---|
| code (incl. verification code) | src/ + tests/ (+ plugin probe assets) | campaigns | CI / every run | tests; verification disposition row at land; orphan census at checkup |
| knowledge / reference (present-tense truth) | `docs/reference/` (3-4 files MAX) + CLAUDE.md hot kernel + MEMORY.md as pointer index | the land graduation row | every wake; DISPATCH BRIEFS FIRST | checkup byte-budget + pointer-resolve rows; every line cites executable truth (state registry exempt — see state row) |
| state (in-flight) | ONE registry file inside the reference tier (live runs, active worktrees, best-ckpt policy) | whoever starts/stops a run or campaign | session start; coordination | pointer-targets-exist + dated-claim expiry (checkup) |
| history (append-only) | docs/campaigns/ + docs/archive/ + docs/superpowers/ | campaigns, append-only | grep archaeology | solidation at checkup/milestone; false-OPEN census |

Cross-cutting: (1) the FLEET scope — shared-infrastructure facts get one home
(global-config section or a fleet reference doc), project files carry pointers;
(2) the MEMORY layer — subject to the same size/pointer discipline, audited by
claude-md-sanity. Artifacts (runs, checkpoints, preserved evidence) are not a
fifth home: live ones are state, preserved ones are history-with-manifest.

## What ships (v0.5.24) — all skill/checkup/asset-carried; ZERO campaign.sh body changes

**S1 — Reference tier, double-gated, with a READ side.**
- Scaffold `docs/reference/`: capabilities+gotchas / conventions+invariants /
  state registry. Hard cap 3-4 files. The conventions file's named contents
  include the ROUTE MAP for multi-route computations: computation → routes →
  which is canonical → the assertion command that proves engagement (the
  owner's wiring knowledge, first-class). Format law: EVERY line points at
  executable truth (`file:line` of a test, gate, or config) — prose with a
  failure path; this one law subsumes the proposed fact-store.
- Write side: campaign-land row `reference: updated <file> | nothing to
  graduate — <reason>`.
- Read side (the blind-spot lens's core finding — without this the 98% of
  tokens spent in subagents never benefit): dispatch guidance in
  way-of-working gains "briefs carry POINTERS, not payloads — point at
  reference/ first; inline only what has no home". The orientation rule's
  CARRIER is the CLAUDE.md template's hot kernel, not a skill — one line
  ("orientation: docs/reference/ first; tree archaeology only when it has no
  answer", ~60 bytes) delivered by scaffold + checkup's CLAUDE.md wiring
  audit, because the light-task session class that produced the 11-call
  baseline never loads any skill: the always-loaded surface is the only
  100%-survival carrier.
- State file gates: pointer targets must exist; "as of <date>" claims older
  than 14 days are flagged (both as checkup rows). The state registry is
  EXEMPT from the executable-truth law — live runs and policy lines have no
  test to cite; these two gates are its failure path instead.
- Known killer, stated: a rotted catalog misdirects (worse than absence). The
  gates are constitutive. If the staleness row goes red twice with no action,
  delete the tier rather than let it lie.

**S2 — Mass budget and tier discipline (the only mechanism that reaches every
subagent with zero adoption behavior).**
- Checkup byte-count row over the always-loaded set — CLAUDE.md hot kernel
  (budget ~20KB; the pure-rule kernel measured 19,435B in the worst offender)
  AND any all-workers-must-read plan/ledger file (the 168KB plan escapes a
  CLAUDE.md-only budget).
- Archive convention: `docs/archive/` in the same grep root; a retracted claim
  keeps its literal search key in the hot tier (`~~old claim~~ → archive/X`).
  Solidation of settled campaign docs runs at checkup/milestone — NEVER per
  land (fixed-tax rule). Census rows: false-OPEN count (baseline 71/331 in
  project A), doc-size histogram (count-only), plans/specs corpus size; an
  executed plan archives with its campaign.
- Memory layer: claude-md-sanity gains size/answer-in-index rows (index lines
  are pointers, not answers; one fact per file; release narrative lives in the
  repo CHANGELOG, not in memory).

**S3 — Verification-code lifecycle (the owner's "professional developer" core).**
- Principle (owner requirement, GPU-heavy fleet): the same computation has
  MULTIPLE execution routes, and silent wrong-route runs are frequent and
  near-invisible — agent consumers read logs through tails and summarizers,
  so a warning line is structurally unseen. **Agent-facing failure must be
  exit-code-shaped, not log-shaped**: route assertions DIE on mismatch, never
  warn. The land-time engage assertion (Phase 2.5) generalizes to EVERY run:
  expected route declared in config, runner compares actual vs expected,
  non-zero on divergence.
- Plugin ships THREE probe assets: the two campaign-land already mandates by
  name and never shipped — `mutation_run` and `engage_grep`
  (self-testing: one line that must match, one that must not, positive-state
  anchor, fixed-string default; mutation_run's spec — forced serial arms,
  untouched-phase control, no-op control — follows the audit's §2.3 form)
  PLUS `provenance_block` — its deferral trigger ("until a project asks")
  fired: the owner asked, for the silent-route class. Every run artifact
  carries a compact route proof (backend / kernel / device / active flags),
  so "which route actually ran" is a recorded fact, not archaeology.
  Everything else (A/B runners, md5-pin, census) stays DEFERRED.
- campaign-land row: `verification: promoted to tests/ | one-shot — <reason>
  (state doc) | deleted`. Session-scratchpad verification is not a deliverable.
- Checkup census row: verification orphans (no test AND no inbound reference),
  count-only with an allowlist. Baseline 29/62 in project B.
- These rules apply to the harness repo itself.

**S4 — Delegation routing (the cheapest large constant).**
- way-of-working delegation table gains the missing row: shell/filesystem
  INVESTIGATION goes to a subagent — Explore is the named vehicle for
  read-only sweeps (excerpt reads); model tier is an explicit lever.
- Brief hygiene: pointers-not-payloads (S1 composition); a fan-out wider than
  the stated default needs one stated reason line (the only lever pointed at
  the measured budget-death bursts).
- Carrier adjudication (three-lens disagreement, resolved): ship as table row
  + measured baseline, with a PRE-COMMITTED escalation — if the re-count does
  not move coordinator shell share materially, the next release ships the
  PreToolUse counter-nudge hook (design already researched and backlogged).
  Rationale: table rows are the one prose surface with a positive field record
  (the row that existed was honored; the gap was the missing row) — but the
  owner-correction ledger says prose triggers fail, so the escalation is
  numeric and count-based (token-share re-measurement is R22-blocked):
  baseline = coordinator Bash calls / total coordinator tool calls (1,436 of
  2,170 = 66%) and Explore dispatches (4/218); trigger = **if the Bash
  call-share has not HALVED at the ~1-month re-count, the next release ships
  the PreToolUse counter-nudge hook** — no adjectives to renegotiate.

**Failure path for the new land rows (terminal-pass finding).** The blank
land-report table is a heredoc inside campaign.sh, which this release does not
touch — so `reference:` and `verification:` would exist only as skill prose,
the carrier class that decays. Fix within constraints: checkup's land-report
audit (skill/checkup-carried, already parses these docs) flags post-adoption
land reports missing the two rows; adding them to the scaffold heredoc is a
NAMED item for the next campaign.sh-touching release.

**S5 — Riders (one line each).**
- autonomous-mandate: completion is judged by the evaluator's verdict, not by
  whether the stop hook fired (field-recorded race).
- Cell grammar law (campaign-land): a land-report cell carries verdict +
  pointer (≤~200 chars); the argument lives in a named section of the same doc
  (baseline: 155 cells >400 chars, max 2,935). v0.5.23's named cells
  (the convergence log, `simplifier:` with its reason, `sanity:`) KEEP their
  names — only argument mass moves.
- Owner corrections are trigger failures: each one gets a backlog entry naming
  the missed trigger (rides the existing backlog discipline; the metric is
  corrections-per-week).
- Fleet home: recommend one shared-infra section in the user-owned global
  config with project files pointing at it; claude-md-sanity gains a
  cross-home contradiction check. (Recommendation + audit only — the global
  file is the user's.)

## The writing router (owner question, 2026-08-06: "문서 작성 체계가 명시적인가")

The home-set gives every document class a home; the ROUTER is the explicit
decision rule a session consults BEFORE creating any document — absent it, the
flat-corpus mechanism reproduces itself. It ships as a short table in the
reference conventions file, with a one-line pointer in the CLAUDE.md hot
kernel ("writing: consult the router before creating any new doc"):

| you are about to write... | it goes to | form |
|---|---|---|
| campaign narrative / results | the campaign's state doc (append) | existing scaffold |
| a present-tense fact, interface, gotcha, route | docs/reference/ | one line + executable-truth pointer |
| what is running / in flight | the state registry | dated line, 14-day expiry |
| a lesson / decision / failure | land-time distill (memory/backlog) | existing Phase-6 rules |
| a plan / spec | docs/superpowers/ | archives when executed |
| a one-off analysis | a SECTION of the requesting campaign's doc | never a new root doc |

Rule: a NEW root-level document requires naming its home and why no existing
home fits — the same attested-skip shape as every other gate.

**Retrofit is explicit**: `/ohd-checkup structure` GENERATES the cleanup
work-list (solidation candidates, orphan lists + allowlist proposals, archive
moves, reference scaffold); EXECUTION is ordinary project campaigns driven by
that list — the harness never bulk-moves a project's documents itself. The
recursion is intended: cleanup campaigns run under the new rules, so the
verification they touch takes the disposition row and the present-tense facts
they excavate take the graduation row — retrofit IS the tier's first fill.

## Usage model and versioning (owner decision, 2026-08-06)

Three entry paths, one skill:
- **New project**: ohd-new-project scaffolds the full home-set at birth
  (reference tier, archive dir, hot-kernel CLAUDE.md shape) — no retrofit.
- **Daily**: default /ohd-checkup stays the fast drift doctor. New rows are
  COUNTS AND GATES only (byte budget, false-OPEN count, pointer-resolve, hook
  stamp — all cheap, none action-proposing), plus ONE summary line pointing at
  the structure mode ("structure | N candidates | last full audit: <age> —
  run /ohd-checkup structure"). A count is a pointer, not an audit; default
  runs must never nag a project into structural work.
- **Adoption / periodic**: `/ohd-checkup structure` (explicit argument, same
  skill — the two share walkers and a report format, so a second command
  would be a second home for one behavior). This mode is the WORK-LIST
  GENERATOR: solidation candidates, orphan-verification lists with allowlist
  proposals, archive moves, memory-layer trims, reference-tier scaffolding
  for an existing project. Its FIRST run on a project IS the adoption audit,
  and it banks that project's baselines. Opt-in by construction.

Versioning: S4+S5 riders ship as v0.5.24 (pure skill text, immediate, no
adoption action). S1+S2+S3 + the structure mode ship as **v0.6.0** — the
largest coherent change of the 0.5 line (a new artifact class, the first
measurement assets, a new checkup mode, the home-set doctrine); the minor
bump is the signal that adoption action exists.

## Deliberately NOT shipped (named, with reasons)

- Fact/probe store as an artifact (its payoff is unmeasured; S1's
  executable-truth format law captures the defensible core).
- Any production/rework instrumentation: **the single largest measured cost
  (document rework, 2.4M tokens one task) ships with NO mechanism** — the
  measurement scripts are hard-blocked (5 bug classes incl. 42× inflation),
  and a prose passes-counter is a 0%-survival class. Post-rebuild count rows
  are the path. This release moves the recurring structural terms, not the
  one-off production spend — stated so the re-count is read honestly.
- Symbol+pin citation standard (later claude-md-sanity convention line).
- Notification/mailbox overhead instrumentation (no honest measure exists yet).
- Deep memory-layer restructure (only the sanity rows above; MEMORY.md is
  simultaneously the best-working pointer index in the fleet and unmeasured —
  measure before rebuilding).
- Per-doc size gates on campaign docs (write-once read-light; census only).
- Disposal-residue enforcement (worktree residue measured at 76 dirs / 10GB /
  29 empty shells) and dormant-symbol accumulation (66/287) — both real
  accumulation terms; cheap checkup census rows are the candidate next step.
- CONFOUND on S3's re-count, named now: "orphan inflow ~0" presumes the
  upstream driver is fixed project-side — a test suite structurally red where
  sessions start makes re-authoring RATIONAL; a flat orphan count under a
  still-red suite is not S3 failing.

## Delivery mechanics

Everything above is skill-, checkup-, or asset-carried: it reaches every
project on plugin update. Nothing touches campaign.sh's body, so the
non-syncing fork in project A is unaffected. Project A's port of older
campaign.sh-carried fixes remains that project's own backlog item.

## Baselines (banked now; re-count ≈1 month after deploy)

| item | baseline | command shape |
|---|---|---|
| S1/S2 wake mass | 139,144B CLAUDE.md (worst); ~340KB pre-first-token | wc -c on the always-loaded set |
| S1 marginal question | 11 tool calls (band-plot trace) | replay the same request |
| S2 false-OPEN | 71/331 | grep -c 'status: OPEN' |
| S2 memory outlier | 33,926B (one file; 20-30× median) | wc -c memory/* |
| S2 plans/specs corpus | 78 / 79 / 9 files per repo | ls \| wc -l |
| S3 orphan verifiers | 29/62 (project B) | no-test AND no-inbound-ref census |
| S3 probe re-implementation | 4 re-builds / 1 session; trap re-hit ×3 | grep campaign docs |
| S4 coordinator shell share | 66% Bash call-share (1,436/2,170); Explore 4/218 | transcript tool-name census (counts — R22-safe) |
| S5 cell overflow | 155 cells >400 chars, max 2,935 | awk length census |
| S4 fan-out deaths | 20 session-limit deaths, burst of 6 | transcript census (observational) |
| S4 brief mass | 216k tok / 218 dispatches | transcript census (observational) |
| S5 owner corrections | 3 recorded classes | corrections-per-week (observational) |
| S3 silent wrong-route runs | owner-reported; no pre-ship count possible (failures are silent) | post-ship: provenance-block greps + assertion die-count (observational) |

Success = the RECURRING terms move (marginal question ≤3 calls; wake mass
toward hot-kernel size; orphan inflow ~0; Bash call-share halved).
The one-off production term is explicitly out of scope this release.
