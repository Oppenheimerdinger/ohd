# campaign: o1-body
- goal: v0.6.0 — O(1) design body: S1 reference tier + S2 mass budget + S3 probe assets + checkup structure mode, per docs/superpowers/specs/2026-08-06-o1-harness-design.md
- status: OPEN (2026-08-06)
- validation gate: TDD for every checkup row and probe asset (fixture RED first); suites green; validator PASS; cr:cr on PR; convergence ends clean; campaign.sh body untouched (checkup.sh/new-project.sh MAY change)
- result / verdict:
- follow-on:

## plan
- [x] S1a ohd-new-project scaffolds docs/reference/ (3 files: capabilities+gotchas / conventions+invariants incl. ROUTE MAP + writing router / state registry) — every scaffold line demonstrates the executable-truth format; state registry exempt, own gates
- [x] S1b CLAUDE.md.template hot kernel gains the orientation line (~60B) + writing-router pointer line
- [x] S1c campaign-land row: `reference: updated <file> | nothing to graduate — <reason>`
- [x] S1d way-of-working: narrow the brief-hygiene pointer to docs/reference/ (backlog #12) + dispatch-brief guidance points at reference first
- [x] S2a checkup default rows (counts/gates only): always-loaded byte budget (CLAUDE.md + all-workers plan files, ~20KB hot target), reference pointer-resolve + 14-day dated-claim expiry, false-OPEN count, structure summary line (N candidates + last-audit age)
- [x] S2b checkup `structure` mode (explicit arg): work-list generator — solidation candidates, orphan-verification census (no-test AND no-inbound-ref, allowlist), plans/specs corpus size, doc-size histogram, memory-layer size/answer-in-index rows (via claude-md-sanity alignment), reference-tier adoption scaffold offer, baseline banking on first run
- [x] S2c archive convention: docs/archive/ in scaffold + solidation guidance (checkup/milestone only, never per-land) + search-key preservation rule
- [x] S3a assets: mutation_run + engage_grep + provenance_block (each self-testing; exit-code-shaped failure; audit §2.3 forms)
- [x] S3b campaign-land row: `verification: promoted to tests/ | one-shot — <reason> | deleted`; scratchpad verification is not a deliverable
- [x] S3c checkup structure-mode orphan row wiring (S2b) + probes apply to the harness repo itself
- [x] ohd-checkup.md: document both modes (default=counts, structure=work-list/adoption); route-assertion principle relayed
- [x] baselines banked in CHANGELOG (per spec table); BEHAVIOR-CHANGE lines one sentence each; version 0.6.0
- [x] campaign.sh body UNTOUCHED (verify at land)

## convergence log (r2c on PR #19)
- round 1: validator + 3-lens review @3d44a44 → findings B1 (probes hang on valueless flags — die-in-subshell), P1-P3 (mutation_run tree check, engage_grep caveat), C1-C7 (checkup verdict rule, reference gate, orphan census, marker parse), T1-T8 (text/skill fixes incl. marketplace-agnostic probes pointer) → fixed 4a3bfdb..4599ed2. CI exposed one further fixture defect (git identity absent on CI runners; local global config masked it) → fixed 2967424, CI green both runs.
- round 2: scoped re-review of fix wave (code-reviewer) @2967424 → 4 findings: F1 Important (VERDICT rule missed colon-inside-emphasis family `**verdict:** LANDS` — the exact form the fix claimed to count), F2 Important (prose false-positive class `- plan: LANDS eventually` fed batch-close/archive suggestions on live docs), F3/F4 Minor (mutation_run dirty-tree message misattribution; success-line overclaim) → fixed f0f80b4 (F1+F2, 18-case contract old-vs-new), aa118fb (F3+F4). CI green both runs.
- round 3 (terminal): scoped re-review (code-reviewer) @aa118fb → 0 Critical/Important; contract 18 cases + 36 adversarial reproduce intended counts; old-vs-new over all 37 tracked md: zero disagreements; land-report audit rule byte-identical/untouched; suites green plain + no-identity CI simulation. 4 Minor residuals, all disposed:
  - M1 bare branch admits ALL-CAPS prose bullets — accepted tradeoff (case IS the discriminator, documented in-code; 0 real-corpus hits; strictly less permissive than pre-wave rule).
  - M2 `[^:]*` after whitelist label admits pre-colon prose — structural (carries `result / verdict:` compound); bounded by colon; 0 corpus hits. Accepted.
  - M3 `- LANDED: PR #7` (verdict-word-as-label) now rejected by census — intended narrowing per precision bias; land-report audit (tolerant rule) still catches the doc. Accepted, logged here as the record.
  - M4 fixer report claimed a 2-line trim that does not exist in aa118fb (file 113→117; all changes are F3/F4) — report discrepancy only, no code impact. Logged.

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | | |
| 0.5 plan recorded    | | |
| 1 working-tree safety| | |
| 2 re-validation      | | |
| 2.5 reachability     | | |
| 3 quality gate       | | |
| 4 docs same-land     | | |
| 5 merge mechanics    | | |
| 6 distill + hygiene  | | |
- [x] (implementer rulings) structure-age: output-only mode cannot stamp — honest "no record" + state.md dated-line suggested; land-row audit NOT shipped (would flag all history vs forward-only) — backlog #13 with unblocking condition; orphan census scope trade stated in output
- [x] (dogfood) ohd itself: 5/5 false-OPEN (design signal: gated verdict row vs ungated status line), reference tier ABSENT, plans/specs 77% of doc mass — first cleanup campaign candidates
