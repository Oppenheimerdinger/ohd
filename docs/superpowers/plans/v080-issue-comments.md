# v0.8.0 issue comments — DRAFTS for the maintainer to post

These are texts, not actions. Nothing here has been posted; the implementation
deliberately does not comment on or close public issues. Post (or edit) them by
hand at release time.

`#33`–`#38` are the release's own source issues and get closing comments with a
shipped/deferred map — a deferral with no trigger written next to it is how a
recorded non-ship turns into a silent one. `#25` gets a standing-trigger note
and stays OPEN. `#7` is unchanged by this release and is listed to say so.

---

## D1 — #25, keep OPEN, restate the trigger

> Unchanged by v0.8.0, and recording that deliberately rather than letting the
> issue go quiet.
>
> The v0.7.0 comment left this open as a trigger record: the disposition-ledger
> half was cut in design review (one incident, on a fork), and what revives it
> is **a second re-derived triage after the land-time debt line shipped**. That
> trigger has not fired. No second re-derivation has been reported since, so
> the ledger stays deferred and this issue stays open holding the condition.
>
> Saying it out loud because "open and silent for a release" and "open because
> the condition has not been met" look identical from outside, and only one of
> them is a decision.

---

## D2 — #7, unchanged

No comment is owed. The v0.7.0 draft already states the disposition, and
`docs/backlog.md` #19 carries it in-repo. v0.8.0 touches nothing in the
`harness-changes` relay window or the `RETIRED-ROUTE` pass. If the maintainer
wants a line at all, it is only: *"v0.8.0 does not touch this; the v0.7.0
disposition stands."*

---

## D4 — closing comments for the release's source issues

### #33 — close, shipped

> Fixed in v0.8.0. The `(example)` test now runs BEFORE the list-item filter,
> so a placeholder is counted wherever it sits — the Route map table row you
> found included.
>
> One caveat worth stating, because it changes what the number means: the
> scaffold's own instruction PROSE also contains `(example)`, so it is counted
> too. A tier whose rows are all filled therefore still reads placeholders>0
> until the instruction line itself is deleted. That is correct — deleting the
> scaffold's instructions when you are done is the finish line — but it means
> the total is "placeholder tokens present", not "rows left to fill", and the
> report says so.
>
> The regression fixtures assert both directions: an `(example)` table row is
> counted, a FILLED table row is not.

### #34 — close, shipped narrowed (with the deferrals named)

> Shipped in v0.8.0 as a distinct `## runner scope` row in `structure` mode,
> along the direction you suggested: it compares the RUNNER's configured scope
> against tracked test files rather than widening the census's directory list.
> The census scope note now carries the honest cross-reference — a colocated
> dir the runner does not discover is invisible to it, and this row is why.
>
> Narrowed three ways, each deliberately:
>
> - **`testpaths` only.** `norecursedirs` is a different parser class and has
>   no field witness yet. Trigger to add it: a case where it is what hides the
>   tests.
> - **Candidates are pytest-COLLECTIBLE names only** (`test_*.py`,
>   `*_test.py`), never the census's verification-family regex — "this shell
>   check is outside pytest scope" is a nonsense finding.
> - **Parser is section-scoped awk** over `[pytest]` / `[tool:pytest]` ini and
>   `[tool.pytest.ini_options]` toml, including the simple multiline array
>   form. No `python3`: checkup has never had that dependency and does not
>   acquire one for a report row. A `testpaths` key present but not literally
>   extractable raises MANUAL-CHECK naming the file rather than guessing.
>
> **No pytest config, or a config with no `testpaths`, leaves the row SILENT** —
> pytest then collects rootdir-wide, everything is in scope, and there is
> nothing to say. Fresh and small projects see nothing new.
>
> Deferred with triggers: non-pytest runners beyond the MANUAL-CHECK path
> (trigger: a field case), and `norecursedirs` (trigger above).

### #35 — close, shipped (both halves)

> Fixed in v0.8.0, and both halves shipped rather than one — they are not
> redundant with each other.
>
> - The `- ci: retired (…)` line is exempt from pointer parsing. It is a
>   declaration, not an anchored claim.
> - Independently, only PATH-SHAPED tokens are treated as pointers at all:
>   contains `/`, or ends in an all-alpha dot-extension. That is the
>   generalization you suggested second, and it is what stops ordinary prose
>   ending in a backticked identifier from being read as a rotted path.
>
> The shape rule alone would not have covered you: a natural retirement reason
> names the deleted workflow FILE, which is path-shaped and nonexistent, so it
> would sail straight through the shape rule and land as a dead pointer. Hence
> both.
>
> The cost, stated: an extensionless bare name now goes unchecked. That is
> fail-open and accepted — it is the price of not reporting `uv run pytest` as
> a rotted doc pointer. A census over the shipped scaffold confirmed every
> pointer form the tier actually uses survives the rule.
>
> Your local workaround (declaration in CLAUDE.md, note in `conventions.md`)
> can be reverted; the tier is a legal home again.

### #36 — close, shipped (both causes, plus the recommended extra)

> Both fail-open directions are fixed in v0.8.0.
>
> - **Cause 1:** `::node-id` is stripped before the `:line` strip and before
>   the shape test, so `path.py::test_name` resolves on the file.
> - **Cause 2:** EVERY backticked path-shaped token in the pointer zone is
>   resolved, not just the first.
> - Plus the one you recommended: `#anchor` suffixes are stripped too.
>
> One pinned decision worth flagging, because it is narrower than "iterate the
> whole line": **the pointer zone is the tail after the FIRST ` — `**, not the
> whole line. Whole-line iteration false-flags claim-half tokens naming removed
> files — which is exactly what a gotcha line is for — and command names.
> Tail-scoping still reaches all 21 of the unchecked pointers in your
> measurement.
>
> Deferred with a trigger: `--collect-only` verification of the node-id half.
> Existence of the file is already the large improvement, and executing pytest
> inside checkup is a dependency class the script has never had. Trigger: a
> field case where a live file's DEAD node-id misleads someone.
>
> Your suggested regression test shipped as written — a live `path.py::test`
> pointer, and a line with two pointers where only the second is dead — inside
> a battery that asserts every rule in both directions.

### #37 — close, shipped with the env-var half CUT

> Shipped in v0.8.0. After `campaign.sh new` writes the state doc, if
> `tools/campaign-post-create` exists and is executable it is invoked with the
> doc's path. `new` never commits, so this necessarily runs before the first
> commit — registration and doc land together, which was your third property.
> Absent = zero behavior change, which was your first.
>
> Fail-loud, no rollback: a non-zero exit is reported loudly and the doc STAYS.
> The doc is your work; the hook's failure is the hook's news.
>
> **The `CAMPAIGN_POST_CREATE` env var is deliberately NOT shipped**, and the
> reason is security rather than scope. An env var is an out-of-repo channel —
> a poisoned `.envrc`, a CI environment, a shell profile — that would make a
> routine `campaign.sh new` execute an arbitrary binary. The in-repo hook is
> the same trust class as `campaign.sh` itself, so it adds no new authority.
> Trigger that would revive the override: a project that genuinely cannot
> commit its hook.
>
> Two smaller calls, stated so they are not surprises: a hook that exists but
> is NOT executable warns rather than skipping silently (a silent no-op is the
> failure this hook point exists to end), and `new` still exits 0 when the hook
> fails, because the worktree and branch already exist and a non-zero exit
> invites a retry that dies on "already exists".
>
> Recording your rejected alternative upstream as well: a blanket default-IGNORE
> glob over `docs/campaigns/*.md` converts a false-RED into a false-GREEN and is
> not adopted here either.

### #38 — close, all three gaps shipped (with the non-ships named)

> All three gaps are addressed in v0.8.0, in the smallest form each admits.
>
> **Gap 1 — hardening added during review.** `review-to-convergence` step 3
> now requires the fix wave to declare its scope, and the convergence-log
> format carries the token:
> `round N: … @<sha> (fix wave: repairs only | +N additional: <one-clause
> reason>)`. Additional work without a clause routes to the follow-on line
> instead. `campaign-land` needed no edit — it delegates the log format to
> r2c wholesale, so the token reaches every land report for free.
>
> **Gap 2 — nothing reviews the attestation layer.** The terminal round's
> INPUT now includes the convergence log (in a campaign, the filled
> land-report rows too), and that round re-runs every gate result quoted
> there, checks each `@<sha>` exists and that no two rounds share one, and
> checks each round line DECLARES its provenance.
>
> One deliberate change from your suggestion, and it is the important part of
> this reply. You proposed *"verify each named round against the agent log"*.
> A reviewer inside this harness cannot read transcripts, spawn timestamps or
> model IDs — so that check would be a paper one, and a paper check on an
> attestation layer is the exact defect the issue reports. **What ships
> enforces that provenance is DECLARED, never that it is true.** A continued
> agent says `continued rN agent`; a model differing from the session's is
> named; an undeclared line reads as "fresh, session model" and that reading
> stands as the AUTHOR's attestation, falsifiable later against the record.
>
> Against your three: the stale gate quote and the whole `@sha` class are
> caught outright; the "fresh" reviewer that was a continued agent and the
> undisclosed smaller model become lies in writing rather than omissions. That
> is the honest maximum of in-harness evidence, and it is stated as such rather
> than sold as detection.
>
> **Gap 3 — both halves.** The pre-registered revert bar is documented in
> r2c's Scope guard, including the part you identified as load-bearing: the
> reviewer reports the count EVEN WHEN IT IS ZERO. It ships as an OPTIONAL
> pattern, not a mandate — one field witness, however clean, is one. Trigger to
> mandate it: a second. And `way-of-working` gains a routing row: a review
> finding DEFAULTS to a backlog/follow-on line, and promoting it to a campaign
> requires naming why it cannot wait.
>
> Deliberately NOT shipped, each with its trigger: per-round attestation review
> (terminal-only — trigger: a false-attestation class the terminal pass
> structurally cannot catch); mandatory revert bars (trigger above); a
> hardening freeze during review (gap 1's declaration is the minimal form, and
> a freeze would forbid work that is sometimes correct).
>
> Noting your closing paragraph is honored: nothing here reduces review depth.
