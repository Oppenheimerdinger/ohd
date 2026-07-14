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
