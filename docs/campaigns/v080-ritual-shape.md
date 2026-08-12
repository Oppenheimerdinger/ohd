# campaign: v080-ritual-shape
- goal: v0.8.0 — checkup fail-open sweep (#33/#35/#36) + ritual shape (#38: fix-wave scope declaration, evidence-shaped attestation pass, revert-bar pattern, promotion bar) + runner-scope row (#34) + post-create hook (#37), per docs/superpowers/specs/2026-08-12-v0.8.0-ritual-shape-design.md
- status: OPEN (2026-08-12)
- validation gate: spec is the contract (deviations written back same wave); A1-A3 land as the review's combined-extractor sketch with ALL cross-issue fixtures asserted at once (RED first); B2 ships the evidence-shaped clause ONLY (reviewer enforces declaration, never truth — any "verify against the agent record" residue is a defect); r2c net ≤ +10 via the spec's routings; C1 silent on no-config/no-testpaths projects (fixture); C2 in-repo hook only (env-var residue is a defect), mirrored + 3 smoke legs; suites green plain+hermetic (the §RELEASING 5-leg gate); validator PASS + independent review (2b); r2c terminal per severity rule — this loop dogfoods B1/B2 (fix waves declare repairs/additional; terminal round runs the attestation checks); BEHAVIOR-CHANGE exactly 3
- result / verdict:
- follow-on:
<!-- a finding made during REVIEW belongs on the follow-on line above: the
review log is not read at land time. Harness friction goes on a '- friction:'
line as it happens — reconstructing it at the end loses the small stuff. -->

## plan
<!-- living plan: certain stretch = task checkboxes; uncertain stretch = ONE
line (next probe + decision rule). Results edit this section, plus a one-line
reason. -->
- [ ] A1-A3 checkup pointer/placeholder extractor rebuild (combined sketch = contract; cross-issue fixture battery RED first: scaffold table row, declaration-with-backticks, `uv run pytest`, live `path.py::test`, second-pointer-dead, `runs/…/`+`configs/*.yaml`+`../` unchanged, `v0.7.1` skipped, `#anchor` strip)
- [ ] B1 r2c fix-wave declaration (one sentence + log-line token; composes with follow-on routing; NO campaign-land edit)
- [ ] B2 evidence-shaped attestation pass — r2c reviewer half (re-run quoted gates / @sha existence+uniqueness / provenance-declaration completeness) + campaign-land input line (log + filled land-report rows into the terminal brief)
- [ ] B3 revert-bar paragraph in r2c Scope guard (optional pattern) + scaffold comment line riding C2's diff
- [ ] B4 way-of-working promotion-bar row
- [ ] C1 runner-scope structure row (testpaths-only awk parser; pytest-collectible candidates only; no-config ⇒ SILENT fixture; MANUAL-CHECK on unparseable; census scope-note honest line)
- [ ] C2 cmd_new post-create hook (in-repo tools/campaign-post-create only; loud fail, no rollback; mirrored to tools/; smoke legs present/absent/failing)
- [ ] D1/D2 issue comments (#25 trigger note); D4 at release
- [ ] version 0.8.0 + CHANGELOG (BEHAVIOR-CHANGE exactly 3: B1/B2/C2)
- [ ] campaign.sh mirror parity + r2c cap count reported (verify at land)
