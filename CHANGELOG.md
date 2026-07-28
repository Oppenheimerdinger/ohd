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
