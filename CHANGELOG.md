## v0.6.0 (2026-08-06)

BEHAVIOR-CHANGE: new projects are scaffolded with a reference tier — `docs/reference/{capabilities,conventions,state}.md` plus a `docs/archive/` stub — and every line in `capabilities.md` and `conventions.md` must point at executable truth (`<claim> — <file:line of a test, gate, or config>`), so orientation is a lookup a consumer can RE-RUN instead of an agent-scan of the tree.

BEHAVIOR-CHANGE: the scaffolded CLAUDE.md hot kernel carries two new always-loaded lines, "orientation: docs/reference/ first; tree archaeology only when it has no answer" and "writing: consult the router before creating any new doc", because the light-task session class that pays the largest marginal cost never loads a skill.

BEHAVIOR-CHANGE: `docs/reference/state.md` is the ONE state registry and the one file exempt from the executable-truth law; in exchange its pointer targets must exist and any `as of <date>` claim older than 14 days is flagged by checkup.

BEHAVIOR-CHANGE: a new root-level document now requires naming its home and why no existing home fits — the writing router in the scaffolded conventions file is consulted BEFORE any document is created, and a one-off analysis becomes a section of the requesting campaign's doc rather than a new root doc.

BEHAVIOR-CHANGE: solidation of settled docs into `docs/archive/` runs at checkup or milestone time and NEVER per land, and an archived or retracted claim keeps its literal search key in the live tier (`~~old claim~~ → archive/X`) because a search that comes back empty reads as "never investigated".

BEHAVIOR-CHANGE: the land report's Phase-4 evidence cell must now carry `reference:` by name — either the reference file this land updated or the attested `nothing to graduate — <reason>`.

BEHAVIOR-CHANGE: the land report's Phase-6 evidence cell must now carry `verification:` by name with one of three verdicts (`promoted to tests/ — <path>`, `one-shot — <reason>`, `deleted`), and verification living only in a session scratchpad is not a deliverable.

BEHAVIOR-CHANGE: the plugin now SHIPS the probe assets campaign-land has mandated by name — `assets/probes/engage_grep.sh`, `mutation_run.sh` and `provenance_block.sh` — so a campaign copies them instead of re-implementing them.

BEHAVIOR-CHANGE: a brief now points at `docs/reference/` FIRST, ahead of the campaign state doc and `file:line`, completing the pointer-narrowing v0.5.24 deliberately left home-agnostic (backlog #12).

- This release is the BODY of the "O(1) harness" design
  (`docs/superpowers/specs/2026-08-06-o1-harness-design.md`) — S1 (reference
  tier), S2 (mass budget and tier discipline), S3 (verification-code
  lifecycle) and the structure mode. v0.5.24 shipped its S4/S5 riders. The
  minor bump is the signal that ADOPTION ACTION exists: an existing project
  gets the tier by running `/ohd-checkup structure`, a new one is born with it.
- **Delivery classes**: everything here is skill-, checkup-, or asset-carried,
  so it reaches every project on plugin update. `assets/campaign.sh` and
  `tools/campaign.sh` bodies are UNTOUCHED (verified by diff), which is why a
  non-syncing fork of the lifecycle script is unaffected. The one cost of that
  constraint is named in backlog #13: the blank land-report table is a heredoc
  inside campaign.sh, so the two new rows are skill-carried prose until a
  release that touches that script.
- `/ohd-checkup`'s default run gains four rows: an always-loaded byte budget
  against a ~20KB hot target, reference-tier existence plus pointer resolution
  and dated-claim expiry, a campaign census reporting false-OPEN docs, and one
  non-action-proposing structure summary line.
- The always-loaded budget counts CLAUDE.md alone unless the file carries an
  explicit `<!-- ohd:always-loaded <path> -->` marker (repeat the marker for
  more paths), which is the only way a plan or ledger file every worker must
  read enters the count; without the marker the row says so rather than
  implying it audited more.
- `/ohd-checkup structure` is a new opt-in mode that GENERATES a corpus
  work-list (solidation candidates, orphan-verification census with a
  `.ohd-orphan-allowlist`, plans/specs corpus size, doc-size histogram,
  reference-tier adoption offer, baselines table) — the harness never
  bulk-moves a project's documents itself, so executing the list is ordinary
  project campaigns.
- Agent-facing failure is exit-code-shaped, not log-shaped: every shipped probe
  DIES on a mismatch and never warns-and-continues, because an agent consumer
  reads logs through tails and summarizers and a warning line is structurally
  unseen.
- **Why those four are bullets and not `BEHAVIOR-CHANGE:` lines.** The marker
  is a RELAY channel: a lagging project receives every line it has not yet been
  relayed AT ONCE (measured: 23 lines for a project last synced at v0.5.22),
  and volume trains dismissal — the failure that costs the marker its meaning
  for the lines that do matter. So §2c's bar is enforced strictly. Checkup's
  own output rows, its opt-in modes, and the design principle behind a shipped
  asset describe what THIS tool does; none of them is a gate, route, or
  requirement a project session must change its work to satisfy.
- New test suite `tests/probes-smoke.sh`, wired into CI. Every probe also
  carries `--self-test`, which runs its own failure path and exits non-zero if
  the probe is dead.
- Baselines banked for the ~1-month re-count (copied from the design of
  record; the S4 row's re-count is due **2026-09-06**):

  | item | baseline | command shape |
  |---|---|---|
  | S1/S2 wake mass | 139,144B CLAUDE.md (worst); ~340KB pre-first-token | `wc -c` on the always-loaded set |
  | S1 marginal question | 11 tool calls (band-plot trace) | replay the same request |
  | S2 false-OPEN | 71/331 | `grep -c 'status: OPEN'` |
  | S2 memory outlier | 33,926B (one file; 20-30× median) | `wc -c memory/*` |
  | S2 plans/specs corpus | 78 / 79 / 9 files per repo | `ls \| wc -l` |
  | S3 orphan verifiers | 29/62 | no-test AND no-inbound-ref census |
  | S3 probe re-implementation | 4 re-builds / 1 session; trap re-hit ×3 | grep campaign docs |
  | S4 coordinator shell share | 66% Bash call-share (1,436/2,170); Explore 4/218 | transcript tool-name census |
  | S5 cell overflow | 155 cells >400 chars, max 2,935 | awk length census |
  | S4 fan-out deaths | 20 session-limit deaths, burst of 6 | transcript census |
  | S4 brief mass | 216k tok / 218 dispatches | transcript census |
  | S5 owner corrections | 3 recorded classes | corrections-per-week |
  | S3 silent wrong-route runs | owner-reported; no pre-ship count possible (the failures are silent) | post-ship: provenance-block greps + assertion die-count |

  Success = the RECURRING terms move: marginal question ~3-4 calls, wake mass
  toward hot-kernel size, orphan inflow ~0, Bash call-share halved. Every
  number above is a COUNT or a byte size; nothing here estimates cost.
- **Deliberately NOT shipped, with reasons** (from the design of record):
  a fact/probe store as an artifact (its payoff is unmeasured; the
  executable-truth format law captures the defensible core); any
  production/rework instrumentation — **the single largest measured cost,
  document rework at 2.4M tokens on one task, ships with NO mechanism**, since
  the measurement scripts are hard-blocked and a prose passes-counter is a
  0%-survival class, so the re-count must be read as moving structural terms
  only; the symbol+pin citation standard; notification/mailbox overhead
  instrumentation (no honest measure exists yet); a deep memory-layer
  restructure (measure before rebuilding); per-doc size gates on campaign docs
  (census only); and disposal-residue and dormant-symbol enforcement (real
  accumulation terms, cheap census rows are the candidate next step).
  A CONFOUND is named now rather than after the fact: "orphan inflow ~0"
  presumes the upstream driver is fixed project-side — a structurally red test
  suite makes re-authoring RATIONAL, so a flat orphan count under a still-red
  suite is not S3 failing.

## v0.5.24 (2026-08-06)

BEHAVIOR-CHANGE: way-of-working's delegation table gains the row it was missing — shell/filesystem INVESTIGATION (enumerating, measuring, censusing, grepping across a tree) goes to a read-only sweep subagent with `Explore` as the named vehicle, and the model tier is an explicit lever rather than a default.

BEHAVIOR-CHANGE: a land-report evidence cell now carries the VERDICT plus a pointer (aim ≤~200 chars) with the supporting argument moved into a named section of the same state doc, and v0.5.23's named cells (the Phase-3 convergence log with `simplifier:`, the Phase-6 `sanity:`) keep their names and their required contents — except that when the convergence log runs past ~2 rounds the cell carries the terminal round line plus a pointer to the named section holding the full log.

BEHAVIOR-CHANGE: an autonomous loop's completion is judged by the independent evaluator's verdict and never by whether the stop hook fired or stopped firing, since a hook can miss a correct promise and hook silence is not a verdict.

BEHAVIOR-CHANGE: in the race where the verdict is banked verbatim but the stop hook keeps re-firing, an autonomous session re-emits the `<promise>` in the loop's exit format each iteration and does NO further mandate work, and if the race persists the user-owned cancel is the legitimate manual exit — legitimate because the banked verdict already decided completion.

- This release is the VANGUARD of the "O(1) harness" design
  (`docs/superpowers/specs/2026-08-06-o1-harness-design.md`) — its S4 and S5
  riders only, which are pure skill text needing no action inside an adopted
  project. The body of that design (the reference tier, the mass budget, the
  verification-code lifecycle, and a new checkup mode) follows as v0.6.0, where
  the minor bump is the signal that adoption action exists.
- Brief hygiene, riding the same delegation guidance: briefs carry POINTERS,
  not payloads — point at the project's durable docs first (its reference docs
  where they exist, the campaign state doc, `file:line`) and inline only what
  has no home; and a fan-out wider than the situational default needs ONE
  stated reason line in the dispatch message.
- Measured baselines for the delegation row, banked now for the re-count:
  coordinator Bash call-share **66% (1,436 of 2,170 tool calls)** and `Explore`
  usage **4 of 218 dispatches** in one measured session. Re-count method is a
  transcript tool-name census — COUNTS, not tokens. The escalation is
  pre-committed and NON-NEGOTIABLE: **if coordinator Bash call-share has not
  HALVED at the ~1-month re-count, the next release ships the PreToolUse
  counter-nudge hook.** It is worded with no adjective to renegotiate later,
  deliberately — the table row is the cheap carrier being tested, and the hook
  is what ships if the test fails.
- Owner corrections are TRIGGER FAILURES by definition: when the owner corrects
  how the session works rather than what it concluded, a trigger that should
  have fired didn't, so it gets a backlog entry naming that missing trigger
  (riding the existing backlog discipline; the metric is
  corrections-per-week, read per project).
- `claude-md-sanity` gains one check: a shared-infrastructure fact (a machine, a
  common service, a fleet-wide path) stated in MORE than one home — project
  CLAUDE.md, global config, memory — is compared across homes, and divergent
  statements of the same fact are BROKEN. Divergent means a VALUE conflict (a
  different address, count, path, or state); the SAME values at different
  detail, format, or verbosity is elaboration and is never flagged, and a case
  you can't tell apart goes to MANUAL-CHECK rather than BROKEN — a field probe
  across six real homes found zero value conflicts and universal format
  variance, so the false positive is the live risk here. The recommendation is
  "state it in one home, point at it from the others"; the skill audits only,
  and which home is the fleet's stays the user's call.

## v0.5.23 (2026-07-31)

BEHAVIOR-CHANGE: the land report's Phase 3 evidence cell now carries a CONVERGENCE LOG rather than just a final verdict — one line per round naming the reviewer and the SHA that round reviewed, ending in a round that came back clean or with every residual finding carrying an explicit ruling (r2c's recorded disposition — `rebutted-upheld` / `minor-logged`) in the state doc.

BEHAVIOR-CHANGE: the land report's Phase 6 evidence cell must contain `sanity:` BY NAME — either the `claude-md-sanity` findings and their disposition, or the skip quoting its named condition WITH the `git diff --name-only <base>..HEAD` artifact the rule already required.

BEHAVIOR-CHANGE: the autonomous-mandate skill no longer accepts work the coordinator did inline as having ADVANCED an iteration — advancing is a fresh dispatch or a backgrounded watch — and the loop prompt the skill writes at setup now carries that rule alongside the lane rule and the work-size micro-edit disqualifiers (writes a new test / needs a mutation or negative control / needs a gate run to judge it).

BEHAVIOR-CHANGE: a campaign-scale plan is now CONVERGED (`review-to-convergence`) BEFORE execution begins — before the user's approval gate, so the user approves an already-reviewed plan — and its items are then materialized into the session task list (TaskCreate / todos), with results written back to the state doc's `## plan` section as units complete.

BEHAVIOR-CHANGE: being INSIDE the superpowers flow is no longer an exemption from review-to-convergence — the spec and the plan are reviewed by their AUTHOR only, so each gets an independent r2c pass before execution begins, and SDD's own review loop, which terminates on ADJUDICATION rather than on a clean pass, now takes r2c's stopping rule: the last round comes back clean, or every residual carries an explicit ruling (r2c's recorded disposition — `rebutted-upheld` / `minor-logged`) in the state doc.

BEHAVIOR-CHANGE: the trunk pre-commit hook written by `assets/install-hooks.sh` now carries a version stamp (`# ohd-hook v2`) that /ohd-checkup compares DIRECTIONALLY — an older stamp reports `trunk-hook | STALE` with the re-install command instead of passing as INSTALLED, while a stamp NEWER than the running plugin's reports `trunk-hook | AHEAD` and points at the stale plugin cache rather than recommending a downgrade.

- Hook stamp, the one item in this release needing an action inside an adopted
  project: re-run the plugin's `assets/install-hooks.sh` (`CAMPAIGN_TRUNK` /
  `CAMPAIGN_TRUNK_ALLOW` still apply). Through v0.5.22 the check matched
  `docs-only` — a string every hook ohd ever wrote also carries — so any future
  hook change reported as already installed and reached no adopted project. The
  AHEAD direction exists because hooks live in the shared common git dir: a
  sibling worktree running a NEWER ohd leaves a stamp ahead of the one the local
  plugin ships, and "upgrading" that hook would downgrade it. A foreign
  pre-commit still reports `OTHER` and is never offered an overwrite.
- Convergence-log details, all Phase 3: a first round that finds nothing IS a
  complete log (one line — rounds exist because findings do); re-reviewing the
  SAME SHA is not a round, and round N+1's scope is the fix diff, not a fresh
  full pass; the rule does NOT scale with diff size, since the regression that
  motivated it was ONE finding on a small diff; and `simplifier: not needed` now
  requires a one-clause reason, a bare `not needed` being a self-attestation
  with nothing in it to disagree with. `review-to-convergence` owns the line
  format — campaign-land points at it rather than restating it, and deep-solve
  carries a synced copy that names its one deviation (no `@<sha>`: a brief is
  not a tree) — since independent restatement is how three slightly different
  formats got written in the first place.
- **Both evidence contracts apply FORWARD only.** Historical land reports are
  not retroactively audited — no script reads these cells — and are expected to
  fail the new wording.
- The Phase 6 contract came out of a field check over the three most recent
  lands, all the MAINTAINER'S OWN: three of three failed it. The sanity run was
  skipped in all three while their diffs touched docs and memory, and the skip
  condition applied to none of them; two wrote no `sanity:` row at all — one of
  those substituting the validator's lock-step check, which campaign-land
  forbids by name — and the third named the gap honestly but still did not run
  the audit.
- **Three of these surfaces are ONE intervention, not three independent
  changes**: the r2c description rewrite, the superpowers-flow exemption repair,
  and the Phase-3 convergence log all move the same metric —
  whether a review loop actually terminates on a clean pass. If a later release
  reads them as three data points and one of them appears to have "worked", that
  reading is wrong by construction; they were shipped together on purpose.
- Measured baselines for the post-ship re-count, over a corpus of 365 unique
  campaign state docs (four repos, de-duplicated across worktree checkouts and
  one stale clone): `"clean pass"` appears in **1** doc; docs naming
  `review-to-convergence` number **7**. Re-count both in a month — those two
  numbers are the honest test of this release. Reviewers are already reached
  constantly (`code-review` is named in 158 of the 365), so the failure being
  fixed is termination, not reach. Plan-section coverage (13 of 365 today) is
  NOT evidence either way: it rises on its own as pre-scaffold campaigns retire.
- `review-to-convergence`'s description is re-aimed at the ACT rather than the
  topic (75 words → 48, `wc -w`): it fires on being about to dispatch a reviewer, hand
  off, or call something done — especially right after fixing findings — and
  carries an explicit negative clause excluding conversations that merely
  discuss, read, or summarize reviews. The clause names summarizing rather than
  ROUTING on purpose: way-of-working is the routing layer whose rows route TO
  this skill, so excluding "routing" would have excluded the router. A
  topic-word trigger fires on every
  conversation *about* review, including this plugin's own maintenance sessions,
  where it was observed misfiring live. It also says "wraps code-review; never
  replaces it": in the corpus r2c DISPLACED the review instrument in 3 of ~15
  firings. The 3+ files / ~100+ lines escalation clause moved from the
  description into the skill body, where it is no longer competing for the
  ~50-word trigger budget.
- The delegation table's micro-edit row is re-cut from diff size to WORK size:
  not a micro-edit if it writes a new test, needs a mutation or negative
  control, or needs a gate run to judge it. Stated without illusions — the OLD
  rule was already correct and was quoted by the violating session *while* it
  was violating it, so the table row is not expected to carry the behavior. The
  same disqualifiers ride the loop prompt above, which is where they are
  expected to fire.
- Autonomous-mandate details: a micro-edit stays legitimate but is not an
  iteration's content, and a coordinator that did everything itself used to be
  in full compliance with the skill as written. The lane, advance and
  review-naming rules ride the loop PROMPT because the stop hook re-injects it
  verbatim every iteration while a skill body read at minute zero does not
  survive compaction — with the matching caveat that the prompt is written at
  setup and re-injected AS STORED, so a plugin upgrade does not refresh a loop
  already running; adopting new prompt text means cancelling the loop and
  setting it up again, which is the user's call. The termination evaluator's
  brief also gains two mandatory questions: which work units were delegated
  versus done by the coordinator, and does every deliverable claimed done name
  the review pass that cleared it.
- The superpowers-flow repair adds NO tool — the instrument stays SDD's own
  reviewer and only the termination condition changes — and it binds hardest
  under an unattended mandate, where SDD's "surface to your human partner" exit
  does not exist. On the author-only premise: writing-plans says it verbatim
  ("a checklist you run yourself — not a subagent dispatch"), while
  brainstorming's spec self-review is likewise author-run in different words
  ("look at it with fresh eyes… Fix any issues inline. No need to re-review").
  An earlier draft of this entry claimed both said it verbatim; only one does.
- On the plan-convergence row: the state doc's `## plan` section stays the
  durable artifact, the session task list is the in-session execution tracker.
- New routing row for LATE ENTRY into SDD/TDD: already implementing when you
  reach for the discipline, enter at the NEXT unit — work already verified gets
  reviewed, never reverted to RED. This is the only observed process failure
  with a negative payoff: a session destroyed bitwise-verified work to restore
  discipline, correctly applying TDD's iron law at the wrong moment.
- Deliberately NOT shipped, with reasons recorded so they are not re-proposed
  blind: a commit-time gate on an empty plan section (the state it fires on
  occurs zero times in the corpus; its input is stale or absent in all ten live
  worktrees measured, because the state doc is trunk-owned and edited at the
  anchor; and it would reach no existing project until the hook-version fix
  above lands); an edit-time PreToolUse hook (its unique capability — telling
  the coordinator from an implementer via the agent id present only in subagent
  payloads — pays off only when a plan EXISTS and the coordinator executes a
  plan step anyway, which was not observed); and a machine matcher for plan
  coverage (42 docs record plans under 20+ heading spellings). Also stated
  plainly: none of this recovers context already burned in an incident —
  prevention only.
- The mechanical round-SHA check the design floated for `campaign.sh clean` is
  NOT shipped. The land report's own contract says row CONTENT may be rewritten
  or translated freely — only the `## land report` heading and the
  `| phase | ran? | evidence |` header are load-bearing — so a parser over an
  evidence cell would contradict the document it reads, and the 25 filled
  Phase-3 rows that already record a second look do so in a dozen ad-hoc
  phrasings. The convergence log is the artifact; no gate pretends to verify it.
- No script logic changed in `campaign.sh` this release, so no `--sync` is
  needed to pick these up: the land-report contracts live in the campaign-land
  skill, which every land re-loads from the plugin. `checkup.sh` itself did
  change (the directional hook comparison), but it runs from the plugin, not
  from the project's copy — the plugin update delivers it.

## v0.5.22 (2026-07-31)

BEHAVIOR-CHANGE: /ohd-checkup's land-report audit was silently UNDER-COUNTING since v0.5.20 — a landed state doc whose verdict row carried any decoration (`- status: LANDED (PR #12 merged)`, `- **verdict**: LANDS`, `- [x] LANDED as PR #7`, a translated label key such as `- 결론: LANDS`) was skipped without an error, so a green `land-reports` row was not evidence of coverage; projects audited under v0.5.20/v0.5.21 pick the fix up with `checkup.sh <root> --sync` (report-mode checkup only prints a DRIFT row — the gate regexes live in the project-local `tools/campaign.sh`, which only `--sync` rewrites).

BEHAVIOR-CHANGE: `campaign.sh clean` now requires the state doc's SCAFFOLD row — the literal `- result / verdict:` line `campaign.sh new` writes — to carry content. Substitutes that used to satisfy it no longer do: `- **verdict**: LANDS`, `- 결론: LANDS`, `- [x] LANDED as PR #7`, `- status: LANDED (PR #12 merged)`, a bare `- LANDED as PR #7`. Those all still satisfy /ohd-checkup's land-report audit — the two consumers now use DIFFERENT rules on purpose (see below). Fill the scaffold row, or use `FORCE_CLEAN=1`. Apply with `checkup.sh <root> --sync`.

BEHAVIOR-CHANGE: `campaign.sh clean` and `abort` now FAIL (non-zero, `PARTIAL clean/abort of '<name>'`) instead of printing `cleaned`/`aborted` when the campaign's worktree survived on disk — a hand-moved worktree, or a `CAMPAIGN_WT_ROOT` that differs between `new` and `clean`. The message states what actually happened rather than assuming the worst: the remote branch is deleted in both cases (by `clean`, or `abort --purge` — a bare `abort` keeps it by design), but the LOCAL branch SURVIVES whenever that worktree still has it checked out (git refuses to delete a checked-out branch), which is exactly the hand-moved case — so the recovery is `git worktree remove` on the path the WARN names plus `git branch -D`, not hand-salvage. With an occupied slot the local branch is genuinely gone. Apply with `checkup.sh <root> --sync`.

BEHAVIOR-CHANGE: `campaign.sh` derives the per-project worktree root from the first `git worktree list` entry in EVERY layout — under `clone --separate-git-dir` sibling projects no longer collapse onto the shared gitdir parent (reintroduced issue #10's cross-project collision) and submodules no longer collapse onto their `modules/…` parent; a project path containing a SPACE is no longer truncated at the space. Under `clone --separate-git-dir` specifically, the MAIN checkout's slot is now the GIT DIR's name (`$HOME/wt/<gitdir>/`), not the checkout directory's — that is the only name a linked worktree of the same project can also see, and the two used to disagree; move any existing `$HOME/wt/<checkout-dir>/` campaigns to the gitdir-named slot. Apply with `checkup.sh <root> --sync`.

BEHAVIOR-CHANGE: the `land` gate, `land --report`'s duplicate-table detection, and checkup's audit exemption now match `| phase |` only at the START of a line instead of anywhere in it — a plan bullet that merely mentions the header no longer satisfies the land gate, no longer blocks `land --report` from scaffolding the real table, and no longer exempts a landed doc from the audit. Apply with `checkup.sh <root> --sync`.

- Both regressions were found by an independent round-2 convergence pass over
  v0.5.20 + v0.5.21, with live reproductions; the round-1 review had passed
  them. Verdict-grep anchoring (v0.5.20) and the `--git-common-dir` project
  root (v0.5.21) each fixed a real hole and opened another. A round-3 review
  then caught this release's own first attempt at the allowance (below).
- EXPECT MORE FLAGGED DOCS. Measured over 365 UNIQUE campaign docs (four
  repos, deduplicated), the `land-reports` row goes from 13 flagged under
  v0.5.21 to 58 under v0.5.22: 45 docs (~12%) flip from unflagged to flagged,
  and none stops being flagged. That count is PER UNIQUE CAMPAIGN DOC, not per
  file on disk — every campaign worktree is a full checkout carrying the whole
  `docs/campaigns/` tree, so grepping across live worktrees counts each doc
  once per worktree and will show a much larger number. The flips concentrate
  in the largest repo (38 of the 45; the remaining 7 are all in one other),
  where the row goes from single digits to
  dozens. This is BACKFILL OF A PRE-EXISTING BLIND SPOT, not new breakage:
  those lands really did happen without a land-report table, and the audit was
  simply unable to see them. Most are old already-landed campaigns that need no
  worktree action — annotate or backfill honestly. Measured by stripping the
  candidate rows and re-running the audit: rows written literally as
  `- status: LANDED …` alone account for 27 of the 45, and 33 once the
  emphasised variants of that same label (`- **status**: LANDED …`,
  `- status: **LANDED …**`) are counted with them.
- `clean`'s verdict gate and checkup's audit now use DIFFERENT rules, and that
  split is the point of this round. Three rounds of tightening one shared regex
  all failed on the same pair: `- **verdict**: LANDS` (a real verdict, must
  pass) and `- **VERDICT: nrxx-tiling genuinely reduces the peak.**` (a
  mid-campaign sub-conclusion in a doc whose campaign is OPEN, must not) are
  lexically near-identical. The two consumers do not have the same input, so
  they should not have had the same rule:
  - `clean` only ever runs on a campaign `new` opened, and `new` writes the
    literal `- result / verdict:` row, so `clean` anchors on THAT row carrying
    content. Position-free (25 of the 139 corpus docs with a verdict line keep
    it below a heading) and emphasis-tolerant (2 of the 84 corpus docs with the
    scaffold row decorate its label). No word counting, no label heuristics.
  - the audit reads LEGACY docs, only 84 of the 365 of which carry that row, so
    anchoring there would silently skip 77% of the corpus — the failure this
    release exists to remove. It keeps the tolerant structural rule: a REAL list
    marker (a space after `-`/`*`), a checkbox only when CHECKED, and between
    marker and verdict only decoration — emphasis and/or ONE space-free label
    key ending in `:`. A bold PARAGRAPH (`**Verdict: L2 is validated.**`) and an
    unchecked TODO (`- [ ] TODO: LANDED upstream?`) are still not verdicts.
  The audit's remaining over-report is deliberate: `- TODO: LANDED upstream?`
  with no checkbox IS reported, because separating it from
  `- status: LANDED (PR #12 merged)` needs a list of blessed label words. It
  costs a human a look; the opposite error was a silent skip. `clean` refuses
  both, because it destroys a worktree rather than printing a row.
  The earlier claim that these gaps were "bounded by `clean`'s merge check" was
  WRONG and is withdrawn: the merge check refuses UNMERGED campaigns, while this
  gate exists precisely for merged ones, and on the tip-empty idempotent path
  the merge check is skipped entirely. An open campaign whose branch was merged
  mid-flight reached the gate with the worktree still holding uncommitted work,
  and a bold sub-conclusion bullet was enough to destroy it — reproduced end to
  end before the fix.
- The label key carries no length bound. The previous `{1,16}` counted BYTES
  under `LC_ALL=C` (cron, systemd, `env -i`), so a Korean label past ~5
  characters silently stopped matching — the exact silent-skip failure this
  release exists to remove. Neither script pins a locale, so the bound had to
  go rather than the locale be assumed.
- v0.5.21's claim that "teardown now WARNs instead of claiming success when a
  worktree it cannot remove survives" was only half true: it WARNed on stderr
  and then printed `cleaned` and exited 0 anyway, and it only noticed a worktree
  sitting at the slot it computed — never one registered at a different path,
  which is exactly what the slot split produced. Both halves are fixed here.
- Fixture coverage added for every case above. Layout fixtures now cover: main
  worktree, linked worktree, sibling `--separate-git-dir` clones opening
  campaigns without collision, a linked worktree whose MAIN checkout used
  `--separate-git-dir` (git keeps no back-pointer there — `core.worktree` is
  unset and `git worktree list` reports the git dir from BOTH sides — so the git
  dir's own name, `.git` stripped, is the project name), the MAIN checkout of
  that same project resolving to the SAME slot (the checkout directory is named
  differently from the git dir on purpose; when the two names coincide the
  derivations agree by accident and a split stays invisible), a repo path
  containing a space, and a linked worktree of that space-path repo.
  `clean`-gate fixtures cover 9 accepted scaffold-row forms (including
  non-ASCII content under `LC_ALL=C`) and 12 rejected rows plus a doc carrying
  no scaffold row at all — among them the five substitutes this release stops
  honoring and the bold-bullet row that destroyed a live worktree. The
  audit's 15-row required-accept matrix moved to `tests/checkup-smoke.sh` and is
  now that consumer's own contract, alongside a fixture pinning the deliberate
  checkbox-free over-report. A fixture also asserts `clean` never prints
  `cleaned` when the worktree survives.

## v0.5.21 (2026-07-31)

BEHAVIOR-CHANGE: the campaign worktree default root is now per-project (`$HOME/wt/<repo-basename>/`) — `CAMPAIGN_WT_ROOT` still overrides, existing projects keep their config's explicit old value through sync, and teardown now WARNs instead of claiming success when a worktree it cannot remove survives.

BEHAVIOR-CHANGE: `checkup.sh --sync` now writes a pre-sync backup (`tools/campaign.sh.pre-sync.<date>`) and its SYNCED report states plainly that body-level customizations do not survive a sync (config keys do).

BEHAVIOR-CHANGE: /ohd-checkup step 7 no longer claims the docs-only trunk hook allows `tools/` paths (it never did — default ALLOW_RE is `^docs/|\.md$`): `tools/` repairs commit with `--no-verify` plus the reason, never by widening ALLOW_RE.

- All three fixes answer externally reported issues with reproductions
  (#10 flat worktree-root collision between sibling projects, #11 sync
  silently discarding body customizations without backup or warning,
  #12 checkup step-7's false hook claim steering agents toward weakening
  trunk protection). Thanks to the reporter for live repro cases,
  including the config-survives-while-its-body-dies corruption in #11.
- Migration note (#10): the per-project default is derived AFTER the
  config block, so a synced project whose config still pins the old flat
  root keeps it — open campaigns are unaffected; new instantiations get
  the namespaced root.
- Post-review fixes (code-review:code-review on the PR + the reporter's own
  issue-thread follow-up): the project name now derives from the MAIN
  worktree via `git rev-parse --git-common-dir` (from inside a linked
  worktree, `--show-toplevel` would have put the campaign name in the
  project slot — smoke fixture added); the pre-sync backup suffix carries a
  time component (a same-day re-sync clobbered the first backup —
  reproduced); the drop-in interview default, checkup step 5, and the
  checkup.sh header now state plainly that sync replaces the script body
  wholesale and what to do with the backup file.

## v0.5.20 (2026-07-31)

BEHAVIOR-CHANGE: campaign state docs now scaffold a `## plan` section (the living campaign plan: task checkboxes where the path is known, ONE line — next probe + decision rule — where it is not) and the land report gains a `0.5 plan recorded` row attesting it at land.

BEHAVIOR-CHANGE: the clean-gate and checkup verdict greps now match only bullet-initial verdict/result lines — a `result:` inside a plan section no longer satisfies `campaign.sh clean` or flips checkup's land-reports audit to GAPS.

BEHAVIOR-CHANGE: the micro-edit delegation license is scoped to STANDALONE fixes — inside an open campaign an edit belongs to the plan by default (no plan line yet = the signal to write one, not a license), and any step of a dispatched task goes to that task's implementer regardless of size.

- Planning-layers doctrine (way-of-working): research plans are layered by
  volatility — direction (roadmap doc) → campaign (the state doc's `## plan`
  section: living, TRUNK-owned, edited at the anchor) → task (frozen brief
  via writing-plans/SDD). Depth follows certainty; replanning is normal (edit
  the line + a one-line reason); a plan line that turns implementation-shaped
  gets a plan FILE cut by writing-plans and becomes a pointer to it — the
  plan section is never an SDD plan file (it lives on trunk, outside the
  worktree SDD runs in). Entering a gate that demands a plan you don't have
  means backfilling is the wrong move: stop and write the honest plan line.
- Design went through a 3-lens independent review (minimality / field
  efficacy / doctrine coherence) before implementation; the original
  new-section+table draft was cut ~80% on the minimality verdict, and the
  verdict-grep anchoring plus the license inversion came out of the review.
- Measured baseline for the efficacy claim: sessions spontaneously write a
  `## plan` section in 6% of campaign state docs (33/522 across four adopting
  projects); scaffold-field fill rates run ~38-76% and die-gated artifacts
  ~75%. Post-ship the rate is directly measurable per project:
  `grep -lc '^## plan' docs/campaigns/*.md`. Known residuals, accepted: no
  surface fires at the moment of drift itself (no hooks by design), and a
  bare plan bullet spelled exactly `- result: ...` still matches the verdict
  grep, as does a bullet BEGINNING with a verdict word (`- LANDED as PR #7` —
  that form is a legitimate free-form verdict; both are indistinguishable
  even to a human reader). The delegation-license inversion itself is
  prose-only — no artifact records who wrote an edit — its measurable proxy
  is the plan section the license now points at.
- Post-review fix (code-review:code-review on the PR, reproduced live): the
  verdict grep's bare-word branch (LANDS/LANDED/ABANDONED) was only
  line-anchored, so a plan bullet merely CONTAINING one of those words
  satisfied the clean gate with the verdict still empty — now anchored to
  the position right after the bullet marker, with smoke fixtures for the
  bare-word case in both suites.

## v0.5.19 (2026-07-30)

BEHAVIOR-CHANGE: under an autonomous mandate a session must never end a turn without a live agent or a just-issued dispatch — an iteration with nothing to do is a missing dispatch, not a reason to slow or stop the loop; padding turns with blocking waits is banned (it makes the session unreachable).

- v0.5.18 closed the kill path but left the pressure that motivated it: when
  every remaining done-condition is owned by a running agent, iterations
  become status checks. The session that deleted its own state file had
  first tried two workarounds, both of which failed in the field:
  short no-op turns (the loop re-fires in seconds; context is the binding
  resource, and the session can end before the work does) and padding turns
  with a blocking wait (frequency drops, but the session stops answering —
  the user had to background the running command by hand to speak to it).
  Neither failure was self-evident before it was measured, so step 6 records
  both as named dead ends rather than leaving the next session to rediscover
  them. The positive rule — a turn always ends with live work — reframes the
  empty iteration as the missing-dispatch symptom it is; the escape valve
  for a genuinely blocked critical path is a non-overlapping axis in a
  SEPARATE worktree (same-worktree agents contaminate each other's gates).
  Explicitly NOT licensed: manufacturing an artifact to justify a turn.

## v0.5.18 (2026-07-30)

BEHAVIOR-CHANGE: a looping session never cancels its own loop — deleting the ralph-loop state file is self-grading termination, same as an unverdicted promise; cancellation is user-owned (/cancel-ralph or shell). The only session-side exit is the independent evaluator's verdict.

- Field incident: a session under ralph-loop deleted its own state file at
  iteration 5, reasoning "remaining work is agent-owned; notifications will
  resume me" — then collected three counterexamples itself (agents idling
  with uncommitted fixes / missing deliverables / missing verdicts).
  idle_notification means "nothing to say", not "done" (idle != done — the
  twin of way-of-working's "Idle != dead"). Root cause was partly ours: the
  autonomous-mandate skill's cancellation line taught the session the kill
  path. Step 5 rewritten (cancellation ownership, the named rationalization,
  the evaluator-only exit); way-of-working's verdict-artifact rule gains the
  state-file clause. A mechanical file-deletion block was considered and
  REJECTED: porous against full-Bash sessions (mv/truncate/python bypasses)
  — a leaky gate is worse than a named rule.

## v0.5.17 (2026-07-30)

BEHAVIOR-CHANGE: saying "자율진행"/"run this autonomously" (session-scope, unattended) now auto-fires the new ohd:autonomous-mandate skill — loop setup becomes the first action; deep-solve's per-run "자율적으로 진행" waiver explicitly does NOT trigger it.

- NEW skill autonomous-mandate: description-triggered (the fleet's measured
  always-loaded activation surface) so the v0.5.15 mandate->loop rule fires
  on the mandate wording itself. Procedure: contract (done-condition, cap,
  completion phrase) -> launch official ralph-loop via its setup script
  (slash command is user-facing only; path from installed_plugins.json,
  cache glob fallback; session binding verified) -> completion phrase only
  in <promise> tags after quoting the independent evaluator's verdict ->
  mandate persisted to the state doc. Fallback tiers: OMC ralph -> built-in
  /loop (never bare). Validated per 2b: plugin-validator CLEAN (facts
  checked against installed ralph-loop 1.0.0); independent review 5 findings
  fixed (deep-solve waiver collision carve-out BOTH sides, authoritative
  path source, unattended plugin-absent dead-end, promise-tag exit format,
  description budget).

## v0.5.16 (2026-07-30)

- /ohd-setup gains **ralph-loop** (official marketplace, name verified
  against the marketplace manifest) — the v0.5.15 mandate->loop-first rule
  now has an installable vehicle instead of an "if installed" shrug; README's
  "loop plugins are a personal choice" stance (v0.5.3) narrowed accordingly:
  still true for ordinary work, no longer for autonomous mandates.
  /ohd-checkup's dependency pass follows automatically (reads setup §1).

## v0.5.15 (2026-07-30)

BEHAVIOR-CHANGE: an autonomous (unattended-completion) mandate now requires setting up a persistence loop as the session's FIRST action — a bare session under an autonomous mandate is non-compliant (way-of-working, persistence loops).

- Third field occurrence of the promise-ending-turn stall, this time under an
  autonomous mandate with no loop. Research (community + first-party):
  the standard fix is state-based stop-blocking (ralph-style loops with
  completion conditions; Anthropic now ships an official ralph-loop plugin),
  NOT phrase heuristics — and plugin-shipped Stop hooks currently cannot
  force continuation (upstream #10412), ruling out an ohd hook regardless.
  Shipped the zero-build fix: the mandate→loop-first rule, verifiable at a
  glance by the user who granted autonomy. Promise-guard hook recorded as
  backlog #9 with its blocking conditions.

## v0.5.14 (2026-07-30)

(maintainer amendments at merge, from the 5-lens review: 3b gains an
explicit unresolvable-store MANUAL row — silent zero-rows was the same
blindness the pass closes; step 5 gains a NO-BASELINE repair bullet — every
raw-copy install starts unstamped, so the motivating project class had zero
3b coverage; the status-set enumeration was dropped per the command's own
DRY rule. Follow-up in backlog: release-time `RETIRES:` sub-marker.)

BEHAVIOR-CHANGE: /ohd-checkup gains a `RETIRED-ROUTE` row — a project CLAUDE.md (or memory store) still naming a mechanism a relayed BEHAVIOR-CHANGE retired is now reported, where before it passed green as "present, mere wording".

- Field defect: a project session kept re-deriving a review route that a
  BEHAVIOR-CHANGE had made agent-invalid ~15 versions earlier, because the
  route was still written into that project's own CLAUDE.md (5 sites) and into
  its auto-memory as a standing rule. Every session read it and complied; the
  user had "fixed it in the harness" and the harness WAS current. Repeated
  /ohd-checkup runs reported green.
- Root cause was a genuine blind spot between pass 3's two cases, not a stale
  install: the wiring pass checks item PRESENCE and is explicitly told to
  "never flag mere wording differences". A retired ROUTE is neither — the rule
  is present and load-bearing, only the mechanism it names has expired — so
  neither case fires, and the drift table certifies the fossil indefinitely.
  The narrower the retired thing, the longer it survives.
- Fix (pass 3b, semantic, BOUNDED): cross-check the project's CLAUDE.md AND its
  memory store against the retired routes named in the `harness-changes` rows
  the script already relays. Bounded on purpose — no general prose policing,
  and the command does not re-derive project impact from CHANGELOG prose
  (that judgment happens at release time, per §RELEASING 2c; the script's
  relay stays mechanical). Runs ONLY when `harness-changes` reports `REVIEW`
  (an inversion of the script's status set, not an enumerated skip list, so
  it can't drift out of sync when the script adds a new no-relay status).
- Also: the memory store was read by NO checkup pass, though a standing rule
  there re-derives as reliably as CLAUDE.md — 3b now greps it, and pass 6's
  claude-md-sanity trigger fires when a repair touched it. Both stores are
  in scope: the repo-relative `MEMORY.md` + `memory/*.md` (if the project
  keeps one) AND the **out-of-repo auto-memory store** — the store the
  original defect actually lived in, which a repo-relative grep never
  reaches. 3b resolves its location the same way `claude-md-sanity`'s Check 3
  does, at runtime, rather than inlining a path (found by internal review
  before ship: the first draft named only the repo-relative paths, which
  don't exist on most projects — the out-of-repo store is where the standing
  rule from the field defect actually sat, ~168 files deep). A `RETIRED-ROUTE`
  repair landing in that out-of-repo store never shows up in `git diff`,
  so step 7 now calls that out separately.

## v0.5.13 (2026-07-30)

BEHAVIOR-CHANGE: the land gate now also accepts the scaffold's `## land report` heading — translate/rename table row content freely, but the heading and `| phase |` header lines are load-bearing; the refusal message says so.
BEHAVIOR-CHANGE: the state doc is TRUNK-owned — `land` WARNS when the campaign branch tracks it (add/add at merge); `new` says so at creation.
BEHAVIOR-CHANGE: fork-kept tools/campaign.sh copies can hand-add a `# synced-from ohd vX.Y.Z (manual)` line to receive BEHAVIOR-CHANGE relays (checkup's NO-BASELINE message explains).

- Three field defects from a project session (self-diagnosed via the STALE
  row — the machinery worked):
  - Land gate matched only the literal `| phase |` header, refusing a
    legitimate report whose table header had been translated → gate accepts
    the `## land report` heading too; the load-bearing lines are named in
    campaign-land and in the refusal message.
  - State-doc dual-home (trunk copy + branch copy) caused recurring add/add
    merge conflicts → ownership defined (trunk-only), mechanical WARN at
    land, UNION-resolution pointer.
  - Fork projects (legitimately SYNC-REFUSED) had no version baseline, so
    the v0.5.12 BEHAVIOR-CHANGE relay would stay silent for them forever →
    the manual-stamp path reuses the existing mechanism, no new machinery.
  - campaign-land route 2 sharpened: "user-run" counts only unprompted —
    asking the user to run /code-review is not a route (field fossil from a
    pre-0.4.19 session). Platform note, verified against docs: Claude Code
    has NO per-command disable setting (a subagent's claimed
    disabledSlashCommands key does not exist; disableBundledSkills would
    also kill /loop and schedule) — so this stays a skill-layer rule.

## v0.5.12 (2026-07-29)

BEHAVIOR-CHANGE: campaign-land Phase 6 sanity gains a named skip condition — a land touching no docs/CLAUDE.md/memory may skip it; the skip row's evidence cell must carry the `git diff --name-only` artifact (attested, not gated).
BEHAVIOR-CHANGE: /ohd-checkup now reports `harness-changes` — line-initial BEHAVIOR-CHANGE markers between your synced-from stamp and the installed version are relayed verbatim on every run.

- Two-part release (both 2-lens design-reviewed; user field evidence:
  long-lived worktrees/sessions drift, landing works as a reset):
  - **Campaign sizing** (way-of-working): a campaign is ONE coherent
    increment — size at intake (one sub-plan from brainstorming/
    writing-plans scope checks = one campaign = one land), land signal is
    state not calendar (stacking the next increment on validated work =
    land now), small lands run lean via the named skip conditions, dragged
    campaigns partial-land (Phase 0) + fresh session.
  - **Patch visibility** (checkup): §RELEASING 2c — project-facing changes
    get a line-initial `BEHAVIOR-CHANGE:` marker at authoring time; checkup
    relays exactly those (sort -V ranges, explicit NO-BASELINE / UNKNOWN /
    NO-CHANGELOG / ANOMALY branches); 4 markers backfilled (v0.4.14/16/17/19);
    smoke pins the relay range semantics and the CHANGELOG header format.
  - Verified per 2b: plugin-validator CLEAN; independent review found 5
    (PLUGVER=unknown silent, CHANGELOG-absent silent, an INVENTED skip
    condition in way-of-working, an unqualified cost claim, skip-condition
    enforcement honesty) — all fixed and behaviorally re-verified 5/5.

## v0.5.11 (2026-07-29)

- Review-wiring design round (user-directed; 3-lens independent design review
  — systems / research-realism / red-team — killed the original heavier
  design: a pre-experiment checkpoint with prose-gated Phase-3 downgrade,
  RISK_PATHS gate machinery, size-based triggers. Unanimous verdicts: prose
  checkpoints have a 0% survival record in this fleet; self-reported rows
  must not weaken die-gated review depth; LOC is anti-correlated with
  numerics risk). Shipped the minimal survivor, way-of-working only:
  - Routing row "RISKY coding just completed": the session MAY choose the
    heavy route on its own judgment (push branch, draft PR,
    code-review:code-review once per PR + independently-dispatched
    mutation/numerics reviewer, loop to clean per r2c; announce in one line;
    land Phase 3 stays the backstop). Opportunity, not a gate.
  - SDD final whole-branch review model: risk-scaled like every other review
    — top model reserved for risky/complex branches ("mid-tier on a routine
    branch is not a corner cut").
  Residual risk (declared): both are prose — actual firing rate is a probe
  item for the planned activation measurement. Validated per RELEASING 2b.

## v0.5.10 (2026-07-28)

- review-to-convergence: the deliverable table's "code" row had not followed
  v0.4.19's three-route doctrine — a session invoking r2c directly on code
  never reached the code-review plugin. Row split: code being BUILT stays
  with superpowers SDD's own loop; a FINISHED diff uses
  `Skill(code-review:code-review, <PR#>)` as the loop's reviewer when a PR
  exists and the plugin is installed, else a review subagent (route named).
  Drift-class fix (stale cross-reference), not a new rule — the v0.5.9
  freeze on rule additions stands. Validated per RELEASING 2b.

## v0.5.9 (2026-07-28)

- Stall + main-session-does-everything field diagnosis, encoded:
  - way-of-working: NEW "Who does the work — the delegation boundary" section
    (context physics rationale; 6-row table: micro-edit stays inline,
    multi-file implementation -> SDD, bulk writing -> writer/executor
    subagents (OMC roster when installed), hard reasoning -> brief+agent /
    deep-solve, must-complete -> loop/ralph, parallel -> 
    superpowers:dispatching-parallel-agents; unified cost heuristic).
  - way-of-working collaboration discipline: "the coordinator seat does not
    solve inline" + "end turns on evidence or a question, never on a promise"
    (promise-ending turns stall unattended sessions; the silent-stall class
    is a confirmed upstream bug, correctly out of scope).
  - CLAUDE.md.template: one-clause coordinator rule on the activation
    surface; mechanics delegated to way-of-working (v0.5.7 dedup preserved).
  - Verified per RELEASING 2b: plugin-validator CLEAN (template token
    machinery byte-intact) + review-to-convergence, 3 rounds:
    round 1: 1x consistency/fact -> 2 findings -> fixed (template exposition
    dedup; persistence-loop overclaim qualified)
    round 2: 1x fresh table review -> 2 findings -> fixed (heuristic
    re-anchored to the cost criterion; parallel row vehicle resolved)
    round 3: verification + final scan -> 0 findings (clean pass)

## v0.5.8 (2026-07-28)

- /ohd-checkup wiring pass: presence-only checking left one class invisible —
  a project whose CLAUDE.md block EXISTS but predates a load-bearing rule the
  template later gained (e.g. the v0.5.6 one-writer lane) passed forever.
  Step 3 now adds an OPTIONAL-REFRESH row naming the missing clause (rules
  only, never phrasing; never auto-applied — step 5's per-item gate applies).
  Validated per RELEASING 2b (plugin-validator: CLEAN).

## v0.5.7 (2026-07-28)

- Retroactive verification of v0.5.6 (validator: CLEAN; independent diff
  review: 2 findings, both fixed here):
  - CLAUDE.md.template's anchor block no longer inlines the multi-session
    doctrine verbatim (it duplicated way-of-working three lines above its own
    "working discipline lives in the plugin" pointer — scaffolds would freeze
    a private copy that drifts). Now: the facts + the one-lane rule in two
    sentences, mechanics delegated to way-of-working.
  - claude-md-sanity --fix: index repair split into its two real actions —
    REMOVE a line whose target is gone (nothing to rebuild from), REBUILD a
    line for an unindexed file from its frontmatter.
- §RELEASING gains a MECHANICAL verification tier (rule 2b): skills/commands/
  assets diffs → plugin-validator; ≳30 instruction lines or script logic →
  also independent review. "Micro release" is explicitly not an exemption —
  that rationalization shipped five unreviewed releases today.
- Backlog #7: FS=shared scaffold promises safety rules it never injects
  (pre-existing, surfaced by this review).

## v0.5.6 (2026-07-28)

- Multi-session shared-state doctrine (design review of the anchor-everything
  model — the model itself is kept: auto-memory is keyed by the session's
  opening directory, so a single anchor is what makes project memory coherent;
  worktree-anchored sessions would fragment and orphan it):
  - **Anchor = one write lane**: concurrent sessions at the anchor are normal,
    but trunk writes (docs commits, merges, resets) belong to the coordinator
    session only — git staging is shared, so a second writer's commit/reset
    can sweep or wipe the first's work. Encoded in way-of-working
    (collaboration discipline) and the scaffolded CLAUDE.md template.
  - **Two tiers**: memory = machine-local session-continuity buffer; git
    (CLAUDE.md/docs/state docs) = durable tier. A fact another machine,
    person, or agent needs is misplaced the moment it lands only in memory;
    land-time distill (Phase 6) is the graduation path.
  - **MEMORY.md index demoted to a regenerable cache**: memory files carry
    their own frontmatter, so a parallel-write clobber is a rebuildable
    accident — claude-md-sanity's --fix now rebuilds missing index lines from
    frontmatter instead of hand-merging.
  - **Re-read before load-bearing use**: parallel sessions age each other's
    session-start copies — re-read MEMORY.md from disk before adding an index
    line (one-line edit, never full rewrite) and re-read a memory file before
    basing a decision on it.

## v0.5.5 (2026-07-28)

- plugin-validator follow-up: /ohd-checkup step 1 no longer enumerates the
  script's report items (the list had gone stale at four of six — the exact
  restated-content failure the file's own DRY invariant forbids; now it just
  points at the script). claude-md-sanity's repair path names
  revise-claude-md as a command, claude-md-improver as a skill (was: both
  "skills").

## v0.5.4 (2026-07-28)

- Wire two harness components that lost their references during campaign-land
  generalization: **code-simplifier** joins Phase 3 as the simplification
  instrument (dispatch on over-complexity findings, output re-enters the
  fix->re-check loop, evidence recorded in the report row);
  **claude-md-management** becomes claude-md-sanity's named repair path
  (sanity audits, revise-claude-md/claude-md-improver rewrite, then re-audit
  -- the writer never grades its own rewrite). Both added to /ohd-setup §1
  (checkup's dependency pass follows automatically) and README Requirements.

## v0.5.3 (2026-07-28)

- /ohd-setup: oh-my-claudecode dropped from the checklist — it is a personal
  persistence-loop choice, not an ohd dependency (way-of-working routes to
  built-in /loop and schedule first, and already warns ralph is heavy with a
  misfire history; recommending its install from setup contradicted that).
  README Requirements reworded the same way. /ohd-checkup's dependency pass
  follows automatically (it reads ohd-setup §1 at runtime).

## v0.5.2 (2026-07-28)

- Activation-surface staleness sweep (descriptions are the 1-hop surface the
  v0.5.1 cross-ref audit could not catch — it checked that references
  RESOLVE, and the bare `/code-review` built-in resolves while misleading):
  way-of-working's description no longer names bare `/code-review` (now "the
  code-review plugin or a review subagent"); /ohd-checkup's description now
  enumerates its v0.5.1 checks (plugin dependencies, land-report gaps, stale
  plugin cache). Historical specs/plans left as-is (point-in-time records).

## v0.5.1 (2026-07-28)

Five-axis audit hardening (scope over-reading / artifact-less rituals /
silent dependency degradation / version-transition hazards / cross-reference
drift) — 18 fixes from a field postmortem where a green /ohd-checkup was
over-read as "the review harness is intact":

- Scope lines on every verdict surface: checkup report footer (+ relay step),
  campaign-status "MERGED = git/PR fact only" footer, r2c convergence log
  carries lens+reviewer count, land-report scaffold carries a scope header,
  claude-md-sanity "declared promises only" line, deep-solve grades never
  travel without their mode inline.
- Behavioral artifacts: checkup.sh audits landed state docs lacking a
  land-report table (`land-reports | GAPS`); loop-termination verdicts are
  appended to the loop's state file; r2c logs ride inside committed-file
  deliverables; deep-solve Phase-1 keeps a printed convergence log and the
  autonomous waiver writes brief/banner/result to a file; land-time sanity
  findings not fixed in the land go to the project's backlog doc.
- Dependencies/versions: checkup command gains a dependency pass (delegates
  to ohd-setup §1 at runtime); campaign-land Phase 3 checks the code-review
  plugin at USE time and names the degradation; checkup.sh detects a
  session pinned to an older cache (`plugin-cache | STALE`); way-of-working
  gains the canonical "updated? reload → checkup" row + a campaign-status
  routing row; README and USAGE-ko document the code-review dependency.
- Drift: USAGE-ko deep-solve defaults corrected to fable/high (stale since
  v0.4.12); CLAUDE.md header modernized (self-hosting is fact, not pending);
  lock-step rule narrowed to its greppable phrase; release-gate policy
  clarifies public-by-necessity strings (marketplace name, archived-repo
  links) vs internal names.

## v0.5.0 (2026-07-28)

- NEW `/ohd-checkup` — harness doctor for existing projects (and the adoption
  path, absorbing backlog #6 /ohd-adopt). DRY by construction: what the
  harness should look like lives ONLY in assets/ (campaign.sh template,
  CLAUDE.md.template, install-hooks.sh) + the dropin guide; the command and
  its mechanical helper compare against those at runtime and restate nothing.
  - assets/checkup.sh: `item | status | detail` report (campaign.sh template
    diff with the config block excluded, trunk hook, state dir, CLAUDE.md
    presence); `--sync` rewrites tools/campaign.sh from the template with a
    KEY-BASED config merge (project values win, template supplies new vars,
    project-only custom vars survive) + `# synced-from ohd v<ver>` stamp.
    Bootstraps a fresh copy in repos that never had the harness.
  - command: mechanical pass → semantic CLAUDE.md wiring pass (vs the
    template) → single drift table → per-item AskUserQuestion repair →
    delegates content hygiene to claude-md-sanity.
  - way-of-working routing row, dropin §Adopting now points at the command,
    README/USAGE-ko entries, checkup smoke in CI.

## v0.4.19 (2026-07-28)

BEHAVIOR-CHANGE: campaign-land Phase 3's default agent review route is `Skill(code-review:code-review, <PR#>)` on the land PR — the bare /code-review built-in is user-only.

- campaign-land Phase 3 (merged PR #3 + maintainer amendments): the old text
  required `/code-review`, which agents cannot invoke (built-in,
  `disable-model-invocation`) — an agent-led land could never legally satisfy
  the report gate. Phase 3 now names three routes in preference order:
  the official code-review plugin invoked as `Skill(code-review:code-review)`
  on the land PR (agent-invocable — verified live by running it on PR #3
  itself), user-run `/code-review`, or a review subagent fallback. The report
  row names the route AND carries normal evidence. Mutation-review guidance
  (from PR #3, field-proven: tautological tests, no-op fixes, 1/3-delivered
  checked boxes) now records its results in the report row — not prose-only.
- way-of-working: code-diff row teaches the namespaced plugin invocation;
  /ohd-setup checks/installs code-review@claude-plugins-official.

## v0.4.18 (2026-07-27)

- campaign-dropin: daily-lifecycle section teaches the v0.4.17 land gate
  (`land --report` scaffold step, refusal semantics, bypass).

## v0.4.17 (2026-07-27)

BEHAVIOR-CHANGE: campaign.sh `land` refuses to push without a land-report in the state doc (`land <name> --report` scaffolds the table; LAND_GUARD=0 bypass).

- campaign.sh `land`: the advisory echo became a die-gate (field postmortem:
  two land-ritual skips in one project; every die-gate held, every prose
  reminder was ignored). `land` now refuses to push+PR unless the state doc
  carries the land-report artifact (`| phase |` table or a `land-report:`
  line); `land <n> --report` scaffolds the blank table into the state doc;
  `LAND_GUARD=0` bypasses. Existence-only check — content honesty stays with
  the campaign-land skill.
- campaign-land: the land report LIVES IN THE STATE DOC now, not chat (a
  chat-printed table gated nothing, twice); re-load the skill from file on
  EVERY land — re-enacting phases from memory is itself a violation.
- way-of-working: routing row for landing/merging a campaign branch.
- Smoke: gate refusal (no push occurs), --report scaffold→land proceeds,
  LAND_GUARD=0 bypass.

## v0.4.16 (2026-07-27)

BEHAVIOR-CHANGE: `clean`/`status` judge squash merges by branch TIP + PR headRefOid — head-auto-deleted branches clean correctly; a stale same-name merged PR no longer green-lights teardown.

- campaign.sh (assets + tools): merge-verdict hardening in `clean`/`status`,
  from a field report on a sibling project's milestone tool (an independent
  review reproduced both edge cases against throwaway repos):
  - **Squash + auto-deleted head branch**: `clean` now judges the branch TIP
    (the pushed `origin/<n>` if present, else the local branch) and consults the
    PR API for that tip. Previously, when GitHub auto-deleted the head branch on
    a squash merge, the absent-remote path checked only local ancestry and
    refused already-merged work as "never pushed" — reviving the `abort --purge`
    workaround the PR-API check was meant to remove.
  - **Reused branch name (destructive path)**: the merged-PR check now requires
    the PR's `headRefOid` to equal the tip (new `pr_merged_tip` helper). A stale
    same-name MERGED PR no longer green-lights `clean`'s teardown of genuinely
    unmerged work; `status` reports such a tip as `UNMERGED?` instead of MERGED.
- Smoke: mock-gh section covering squash+head-deleted (allow), reused-name
  (refuse; worktree + remote branch survive), and status tip-match (MERGED via
  PR for a matching tip vs UNMERGED? for a stale-tip PR).

## v0.4.15 (2026-07-21)

- CI smoke hardening for the v0.4.14 submodule test (no functional change):
  file-protocol allowance must travel via GIT_CONFIG_* env (repo config does
  not reach the submodule's inner clone), and the bare fixture's default
  branch is pinned with `init -b main` (git-2.54 runners init a different
  HEAD → "branch yet to be born" on submodule add). v0.4.14's tag points at a
  red-CI commit; this tag is the green one.

## v0.4.14 (2026-07-21)

BEHAVIOR-CHANGE: campaign.sh `new` auto-inits git submodules in fresh worktrees (CAMPAIGN_INIT_SUBMODULES=0 skips); `clean` refuses without a filled verdict/result line in the state doc (FORCE_CLEAN=1 bypass).

- campaign.sh (assets + tools, from a real two-campaign field report;
  spec docs/superpowers/specs/2026-07-21-worktree-submodule-venv-land-gates.md):
  - `new` initializes git submodules in the fresh worktree (`git worktree add`
    leaves them empty — uninitialized submodules masquerade as pre-existing
    test failures). `CAMPAIGN_INIT_SUBMODULES=0` skips; no-op without
    `.gitmodules`; non-fatal on failure.
  - `new` prints `WORKTREE_HINT` (`{wt}` substituted) when set — tells the
    operator/subagent how to run tests in a venv-less worktree.
  - `clean` refuses (before teardown, after merge verification) when the state
    doc's verdict/result line is unfilled — the Phase-4 on-disk artifact now
    has a mechanical gate at the point of no return. `FORCE_CLEAN=1` bypasses.
    (The spec's suggested pattern was hardened: the scaffold always contains
    the literal word "verdict", so the gate requires content after the colon.)
- Smoke: submodule fixture (populated worktree + =0 skip), hint substitution,
  verdict-gate refusal→fill→success. plugin-validator: CLEAN.

## v0.4.13 (2026-07-20)

- /deep-solve argument-hint: `--model opus` (fable is now the default) +
  `--effort` tier listed.

## v0.4.12 (2026-07-20)

- deep-solve: defaults changed to `model: "fable"`, `effort: "high"` (was
  opus/max). The old "fable only on explicit request" rule is retired; opus is
  now the explicit override (`--model opus`). Banner hint now advertises
  deeper effort tiers instead of fable.

## v0.4.11 (2026-07-16)

- Anti-rationalization audit across all skills (follow-up to v0.4.10's
  land-report gate). Two gaps closed:
  - review-to-convergence: finding-closure rule (author never closes a finding
    by fiat — fix+re-review, or rebuttal adjudicated by the NEXT reviewer;
    severity is the reviewer's call) + mandatory per-round convergence log as
    the hand-off artifact.
  - way-of-working: loop termination requires the independent evaluator's
    verdict QUOTED verbatim ("the evaluator would agree" = self-grading);
    completion claims must name their review pass or be treated as unreviewed.
  - Audited clean: campaign-status, claude-md-sanity, deep-solve (verdict
    table / findings / user-gate+script are already artifact- or
    mechanically-enforced).

## v0.4.10 (2026-07-16)

- campaign-land: mandatory land-report table (phase | ran? | evidence) gates
  Phase 7 cleanup. Counters the observed skip-by-rationalization failure
  ("earlier review covers Phase 3", "low risk") — substitution rationales are
  declared invalid; skip rows must quote a skill-named condition; empty
  evidence = the phase did not happen. Silent omission becomes explicit
  misstatement, which does not survive.

## v0.4.9 (2026-07-16)

- Security/privacy: scrubbed internal project, company, and machine names
  from the tracked design docs (docs/superpowers/specs+plans) — replaced with
  neutral placeholders. Release-gate policy hardened: those directories are no
  longer whitelisted; internal NAMES (not just secrets/IPs) are gate failures.

## v0.4.8 (2026-07-16)

- /ohd-new-project: objective-options principle — populate options from
  detection (Q0 offers scanned sibling projects as choices and skips the shape
  question on a match; data paths and gate slots offer detected candidates;
  gate verdict itself is an AskUserQuestion). Q1 anchor rephrased to
  steady-state ("once up and running") — the "a year ahead" phrasing is gone.

## v0.4.7 (2026-07-16)

- /ohd-new-project interview redesigned (fable-designed question set):
  AskUserQuestion tool mandatory (no plain-text interviews); 11 questions cut
  to 5-6 in 2-3 batched calls (conventions auto-decided, flippable at the
  gate); NEW structure elicitation via the growth-axis question ("what piles
  up in the repo?") with 4 shape skeletons + umbrella derived from the
  external-code answer; similar-project accelerator (name an existing project,
  its layout is read and adapted); annotated tree proposal approved at the
  gate and committed as a second `layout:` commit. new-project.sh unchanged.

## v0.4.6 (2026-07-16)

- deep-solve: new `effort` arg (low|medium|high|xhigh|max, default max) — sets
  the solver/confirmation reasoning tier; reviewers keep their `high` ceiling
  but never outspend the solver. Override via "--effort high" / "effort high로".

## v0.4.5 (2026-07-15)

- campaign-land: restored the reachability/graduation gate (Phase 2.5) that
  was dropped during generalization — "merged is not enabled": gated work
  graduates to default-ON as part of the land (gate becomes a kill-switch),
  and the new path's engagement is positively asserted post-merge/post-pull.

## v0.4.4 (2026-07-15)

- Drop-in guide: new "Adopting an EXISTING project" section — full harness
  wiring for existing repos (session anchor, machine×env matrix, pointers,
  facts), merged into the existing CLAUDE.md and audited by claude-md-sanity.
  /ohd-adopt automation added to the backlog.

## v0.4.3 (2026-07-14)

- Session-anchor guidance in four places (scaffolded CLAUDE.md "How we work"
  header, new-project next-steps, USAGE-ko, README): open Claude Code sessions
  at the trunk-checkout root, never inside a campaign worktree; drive worktree
  work from the anchor. Smoke asserts the scaffolded guidance.

## v0.4.2 (2026-07-14)

- new-project: `--env name:none` — scaffolds no files, records "managed
  manually" in the CLAUDE.md matrix (non-Python / manually-managed setups;
  makes the harness genuinely field-agnostic). Interview Q9 updated; smoke
  assert added.

## v0.4.1 (2026-07-14)

Activation-wiring fixes, driven by a 5-probe live simulation of a fresh
colleague session (3 FIRED / 2 PARTIAL / 0 MISSED) plus a wiring audit:

- deep-solve description: the "mention /deep-solve when stuck" fallback is now
  affirmative (was "at most briefly mention" — measured not to fire).
- review-to-convergence description: carries the multi-reviewer workflow
  escalation rule (3+ files / ~100+ lines) — moved to where activation
  actually happens (was 2 hops deep inside way-of-working's body).
- way-of-working: completed implementation is explicitly a deliverable
  (outside subagent-driven flows it gets an explicit review-to-convergence
  pass); **loop termination is judged by an independent evaluator agent,
  never by the looping session itself**.

## v0.4.0 (2026-07-14)

- **Plugin renamed: `oppenheimerdinger` → `ohd`** (repo:
  https://github.com/Oppenheimerdinger/ohd — old URLs redirect). Migrate an
  existing install:

      claude plugin uninstall oppenheimerdinger@dipark
      claude plugin marketplace remove dipark
      claude plugin marketplace add Oppenheimerdinger/ohd
      claude plugin install ohd@dipark

- No functional changes; skill ids now `ohd:<skill>`.

# Changelog

## v0.3.1 (2026-07-14)

- fix: new-project preflight hardening (trunk ref-format, env/node name
  validation, host-repo whitespace, github format, repo-local-identity probe
  gap), portable sed (macOS), CLAUDE.md template-comment residue, gh
  partial-failure guidance, post-mkdir failure hint; backlog carries v0.3
  exclusions.

## v0.3.0 (2026-07-14)

- New: `/ohd-new-project` — interview-driven research-project scaffolder
  (deterministic `assets/new-project.sh`; campaign lifecycle instantiation,
  protected trunk, machine×env matrix CLAUDE.md, external-code hosts
  machinery with adopt-safe setup.sh, data symlink, gh repo creation).
- New: 3-profile network-free smoke in CI.
- way-of-working routing table gains the new-project row.

## v0.2.2 (2026-07-14)

- fix: clean refuses never-pushed campaigns (data-loss guard, new smoke
  assertion); clean/status stacked-PR verification tightened (per-PR base
  matching); pin robustness (PIN= guard, portable sed, pathspec commit); list
  handles spaced paths; CI guards assets↔tools drift; doc polish.

## v0.2.1 (2026-07-14)

- fix: campaign.sh status treats a FAILING gh call as UNVERIFIED (was:
  silently treated as no-PRs → false UNMERGED on non-GitHub remotes / auth
  failures; caught by CI)

## v0.2.0 (2026-07-14)

- New skills: `way-of-working` (quality routing, delegation/review
  force-multipliers, lightest-first persistence loops, collaboration
  discipline), `campaign-land` (generalized land ritual), `campaign-status`
  (squash-safe merge verdicts).
- New: parameterized `assets/campaign.sh` worktree lifecycle template +
  `assets/install-hooks.sh` + interview-driven drop-in guide
  (`docs/campaign-dropin.md`), smoke-tested in CI.
- Self-hosted: this repo now uses `tools/campaign.sh` (hook skipped —
  intentional trunk-direct development).

## v0.1.1 (2026-07-14)

- Release-gate hygiene: untrack the local ops note
  (`docs/migration-checklist.md`) so it no longer trips the repo's own
  release gates; it stays on disk, now gitignored.
- Rollback recipe fix: the pin-old-version recipe in README now removes the
  `dipark` marketplace before adding the clone's (same-named) marketplace,
  avoiding a conflict, and explains how to return to the live version.
- README fallback wording: the Requirements section now says deep-solve's
  isolated mode falls back to a manual Agent-tool loop when the Workflow
  tool is absent (grounded mode is unaffected).
- Lock-step rule now names all three label locations
  (`commands/ohd-setup.md`, `README.md`, and the future way-of-working
  skill) instead of two.
- RELEASING tag discipline clarified: commit everything, then tag on the
  final commit, push with tag; noted that v0.1.0's tag trails main by one
  docs commit (known, do not force-move the published tag).
- docs/USAGE-ko.md heading nesting: deep-solve-specific sections (언제
  쓰나 / 실행 흐름 / 두 가지 모드 / 옵션 / 결과 읽는 법 / 팁) are now
  demoted to `###` so they nest under `## deep-solve 사용법`.

## v0.1.0 (2026-07-14)

- Initial public release. Absorbs deep-solve v0.2.2 verbatim (formerly the
  standalone `deep-solve@dipark` plugin).
- Promotes `claude-md-sanity` (anonymized) and `review-to-convergence`
  (+ scope guard) to this harness.
- Adds `/ohd-setup` — environment checkup with approved-install flow.
- Completes migration from the standalone deep-solve plugin.
