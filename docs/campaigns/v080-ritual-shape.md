# campaign: v080-ritual-shape
- goal: v0.8.0 — checkup fail-open sweep (#33/#35/#36) + ritual shape (#38: fix-wave scope declaration, evidence-shaped attestation pass, revert-bar pattern, promotion bar) + runner-scope row (#34) + post-create hook (#37), per docs/superpowers/specs/2026-08-12-v0.8.0-ritual-shape-design.md
- status: LANDED (2026-08-12)
- validation gate: spec is the contract (deviations written back same wave); A1-A3 land as the review's combined-extractor sketch with ALL cross-issue fixtures asserted at once (RED first); B2 ships the evidence-shaped clause ONLY (reviewer enforces declaration, never truth — any "verify against the agent record" residue is a defect); r2c net ≤ +10 via the spec's routings; C1 silent on no-config/no-testpaths projects (fixture); C2 in-repo hook only (env-var residue is a defect), mirrored + 3 smoke legs; suites green plain+hermetic (the §RELEASING 5-leg gate); validator PASS + independent review (2b); r2c terminal per severity rule — this loop dogfoods B1/B2 (fix waves declare repairs/additional; terminal round runs the attestation checks); BEHAVIOR-CHANGE exactly 3
- result / verdict: LANDS — merged as PR #39 (fb559d3), tagged v0.8.0 == pushed HEAD, deployed 0.7.1→0.8.0 (cache verified)
- follow-on: minor-logged from the loop — hook retry-message clause (a failing hook is not re-run by `new`; message gap only), URL/glob pointer-token skip (`*://*` + glob metachars), table-row pointer gating (filled Route-map rows' pointers ungated — design question, backlog candidate with the reviewer's witness), extractor edges (backticked ` — ` separator, double-backtick span, indent-4 list items), `*`-bullet exemption/CI-row marker mismatch (one char + comment parity — next checkup touch), RS_TP in-band sentinel class (move to out-of-band RS_STATE if the set grows); fleet reload push (BC 누적 relay; first post-reload autonomous mandate = loop-wiring acceptance test, STILL pending); issue edit-history purge incl. #33-#38 (owner UI)
<!-- a finding made during REVIEW belongs on the follow-on line above: the
review log is not read at land time. Harness friction goes on a '- friction:'
line as it happens — reconstructing it at the end loses the small stuff. -->

## plan
<!-- living plan: certain stretch = task checkboxes; uncertain stretch = ONE
line (next probe + decision rule). Results edit this section, plus a one-line
reason. -->
- [x] A1-A3 checkup pointer/placeholder extractor rebuild (combined sketch = contract; cross-issue fixture battery RED first: scaffold table row, declaration-with-backticks, `uv run pytest`, live `path.py::test`, second-pointer-dead, `runs/…/`+`configs/*.yaml`+`../` unchanged, `v0.7.1` skipped, `#anchor` strip)
- [x] B1 r2c fix-wave declaration (one sentence + log-line token; composes with follow-on routing; NO campaign-land edit)
- [x] B2 evidence-shaped attestation pass — r2c reviewer half (re-run quoted gates / @sha existence+uniqueness / provenance-declaration completeness) + campaign-land input line (log + filled land-report rows into the terminal brief)
- [x] B3 revert-bar paragraph in r2c Scope guard (optional pattern) + scaffold comment line riding C2's diff
- [x] B4 way-of-working promotion-bar row
- [x] C1 runner-scope structure row (testpaths-only awk parser; pytest-collectible candidates only; no-config ⇒ SILENT fixture; MANUAL-CHECK on unparseable; census scope-note honest line)
- [x] C2 cmd_new post-create hook (in-repo tools/campaign-post-create only; loud fail, no rollback; mirrored to tools/; smoke legs present/absent/failing)
- [x] D1/D2 issue comments (#25 trigger note); D4 at release
- [x] version 0.8.0 + CHANGELOG (BEHAVIOR-CHANGE exactly 3: B1/B2/C2)
- [x] campaign.sh mirror parity + r2c cap count reported (verify at land)

## convergence log (r2c — this loop dogfoods B1/B2)
- round 1: 1× plugin-validator + 1× review subagent (spec-compliance + execution lens; both fresh agents, session model — the review subagent's FIRST instance died to a usage limit mid-run and was relaunched with no inheritance, partial output discarded) @83c89f9 → C0 I2 M7. Dispositions, itemized: I2 fixed as repairs (R1 testpaths literal comparison incl. glob→MANUAL-CHECK; R2 deep-solve format restatement → pure pointer); M7 = 3 fixed as the declared additionals (the two mutation-survivor gaps M1/M8 and the witnessless assertion = A+3/A+1/A+2) + 4 minor-logged per B1's default (hook retry-message clause, URL/glob token skip, table-row pointer gating, extractor edges) → follow-on/backlog at land.
- gate results quoted at round 1 (for the terminal round's B2 re-run): all five suites PASS plain and hermetic @31465f2; r2c numstat vs merge-base = 12 insertions 3 deletions (net +9, cap ≤ +10); parity OK; release greps clean over added lines.
- round 2 (terminal): 1× review subagent (fix-wave scope + B2 attestation lens; fresh agent, session model) @31465f2 (fix wave: repairs only [7409122] | +3 additional [31465f2], as declared above) → C0 I0 against the branch; every fix-wave claim reproduced by execution incl. both mutation controls and the pre-A+1 M8 survival. **B2 attestation, first live run: all 4 banked quotes re-ran CURRENT; @sha existence/uniqueness PASS; provenance declarations complete — zero stale, zero undeclared.** One Important found ON THIS LOG (minor-disposition accounting didn't close — fixed in this edit, the itemization above) + 3 log-format minors (H/L→I/M vocabulary, reviewer-count/lens, fix-wave token placement — all fixed in this edit; token placement resolved per the skill: the token rides the round AFTER the wave, as this line now demonstrates) + 3 code minors DISPOSED minor-logged: `*`-bullet exemption/CI-row marker mismatch (no field witness of a `*`-bulleted declaration; follow-on), RS_TP in-band sentinel class (backlog-shaped, fail-safe direction), deep-solve rewrap orphan (cosmetic). Terminal: C0 I0 on the branch, all residuals ruled on.

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
<!-- ohd:land-report-scaffold v0.7.0 -->
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | yes | campaign.sh new worktree; PR route (PR #39); Phase-0 checks branch 1 — ATTESTED SKIP, declaration quoted verbatim: `- ci: retired (2026-08-11 — owner directive; release gate is the local hermetic suite)`; ci-coherence CONSISTENT |
| 0.5 plan recorded    | yes | plan (10 items) from the converged spec before dispatch; all closed |
| 1 working-tree safety| yes | 11 code commits worktree-only; anchor docs-only (spec, plan, convergence log); no shared-tree incidents |
| 2 re-validation      | yes | full 5-leg gate green plain + hermetic @31465f2 (both rounds re-ran independently; the terminal round's B2 pass re-ran the banked quotes a third time — all CURRENT); plugin-validator PASS @83c89f9 |
| 2.5 reachability     | yes | plugin.json 0.8.0; deployed 0.7.1→0.8.0 cache verified; dogfood live: ritual-bypass row flagged THIS report at bare prompts (1 of 3) while being filled — the row works on its own campaign |
| 3 quality gate       | yes | r2c 2 rounds terminal C0 I0 on the branch (log above) — the loop dogfooded B1 (fix wave split on the repairs/additional boundary, per-item clauses) and B2 (first live attestation pass; its one Important was on the convergence log itself and was fixed there); simplifier: not needed — reviewer-driven waves, net growth within all caps (one-clause reason per contract) |
| 4 docs same-land     | yes | CHANGELOG (3 BEHAVIOR-CHANGE) + spec deviations recorded in-wave (C2 ×2, deep-solve Sizing) + issue-comment drafts in docs/superpowers/plans/; reference: nothing to graduate — the ritual-shape contracts live in their skills (the carrier by design), the spec carries the postmortems; verification: promoted to tests/ — cross-issue extractor battery, runner-scope fixtures incl. glob MANUAL-CHECK, hook smoke legs ×3, mutation controls M1/M8 |
| 5 merge mechanics    | yes | PR #39 merged fb559d3; tag v0.8.0 == pushed HEAD (`git describe --exact-match`); branch+worktree removed post-land |
| 6 distill + hygiene  | yes | sanity: delta-check — this release's reviews measured the touched contracts in-wave (rounds 1-2 quoted and re-ran the gate text); version==tag==HEAD, lock-step 3/3 (validator), no line-initial anchor; memory updated same land; #33-#38 closed with shipped maps, #25 commented with its standing trigger |
