---
name: review-to-convergence
description: Use when about to dispatch a reviewer, hand off or finalize a deliverable, or call something done — right after fixing review findings, or once a plan/spec/handoff is written ("plan 다 썼다", "이제 리뷰 돌리자"). Wraps code-review; never replaces it. NOT for merely discussing, reading, or summarizing reviews.
---

# Review to Convergence

A substantive deliverable is **not done when you think it is done**. It is done when an *independent* reviewer pass finds nothing that must be fixed.

Independent review repeatedly catches the *author's own* wrong assumptions — mistakes invisible to the person who made them. The more novel the work, the more this holds. **Your confidence is not evidence.**

## When to use
At the ACT, not the topic — you are about to dispatch a reviewer, about to
finalize or hand off (a math problem statement, a handoff, a design/plan/ADR, an
experiment analysis, a research-informed decision, non-trivial code), or you
have just FIXED review findings: the fixed artifact still needs the next pass,
and that is where this loop is abandoned most often. Creative/structural work
spanning 3+ files or ~100+ lines of new logic escalates to a multi-reviewer
workflow pass (way-of-working) instead of a single reviewer.

Genuinely trivial / throwaway / one-line work is exempt. **Anything non-trivial requires the loop.**

## The loop
1. Produce it (test-first for code).
2. Dispatch an **independent** reviewer (fresh context; reviewer ≠ author).
3. Fix Critical/Important; log Minor. A false claim is fixed by sweeping every restatement of it, not the one line the reviewer happened to cite. **The fix wave declares its scope** — the next round's log line names what entered beyond the findings' repairs, and anything additional either carries its one-clause justification there or goes to the follow-on line instead: review-prompted hardening is new code written under fatigue that reviews itself worst (a field run spent rounds 3–7 finding defects exclusively in it, and ended by deleting 81 of its lines).
4. Re-review → step 2.
5. A round returning **zero Critical and zero Important**, every residual disposed ⟹ done — or, when the loop restarted on a replaced artifact, that round plus the one sanctioned confirmation round on the frozen hash (below). Not before.

**Violating the letter of this rule violates the spirit.** Do not stop at one pass; the last round must come back C0 I0 with every residual disposed.

**Finding closure — the author never closes a finding by fiat.** A finding
closes exactly two ways: (a) fix it, and the NEXT review pass sees the fixed
artifact; or (b) you believe the finding is wrong — write the rebuttal INTO
the next reviewer's input and let that reviewer close the finding or uphold it against your rebuttal. Severity
(Critical/Important/Minor) is the reviewer's classification; downgrading a
finding yourself to avoid a fix is closure by fiat. "The reviewer
misunderstood" is itself a finding — against your artifact's clarity.

**Every finding ends in a DISPOSITION, and those dispositions ARE the
"rulings" other skills cite.** Step 5 tests severity, not count: counts do not
converge — an adversarial reviewer returns items against an artifact two prior
reviewers called correct — severity does. A residual survives the terminal
round only as a logged disposition carrying its reason — `rebutted-upheld` or
`minor-logged` (triaged, naming what was deferred) — recorded in that round's
log line and, inside a campaign, in the state doc. **Only a Minor can be a
residual**; a Critical or Important closes by fix or `rebutted-upheld`, never
by riding out the terminal round. A residual with none recorded means NOT
converged: closure by fiat with a log line drawn around it.

**Convergence log (artifact, hand-off blocker):** when declaring done, print
one line per round — `round N: <reviewers>× <lens> @<sha> (fix wave: repairs
only | +N additional: <one-clause reason>) → X findings →
fixed/rebutted-upheld/minor-logged`, the terminal round ending `→ C0 I0` (zero Critical, zero Important) plus each residual's disposition. The fix-wave
token is step 3's declaration, and it is owed from round 2 on (round 1 fixed nothing yet).
**This is the one format**; other skills point here rather than restate it.
The lens and reviewer count are part of the log: `C0 I0` from one design-lens
pass must not relay as the multi-reviewer rigor it wasn't. A fixed-pipeline
INSTRUMENT counts as one under its own name, and that name stands as the lens
(`1× code-review:code-review` — the plugin's set of review lenses is fixed and
documented); an ad-hoc reviewer names its lens itself (`1× review subagent
(bugs lens)`). `@<sha>` is the tree that round reviewed — re-reviewing the same
SHA is not a new round, with ONE exception: after the Scope guard's
moving-target stop fires, the replaced artifact's first terminal-candidate
round gets one confirmation round on the frozen hash, fresh reviewer mandatory.
A non-tree deliverable (a plan, a problem statement) fills the slot with a CONTENT hash — `sha256sum | cut -c1-7`, named so two agents produce comparable slots — rather than dropping it. No log line for a terminal round = not converged; go run it.
**When the deliverable is a committed
file** (design doc, ADR, analysis), the log goes INTO it (a short `## Review
log` footer) or its commit message — the file outlives the chat that
reviewed it.

## Scope guard

Use this loop only on a FIXED deliverable. If review findings start driving a
redesign of the deliverable itself (a moving target), STOP the loop and go
back to the design conversation — reviewing a mutating artifact does not
converge. A fixed deliverable normally converges in 1–3 passes; there is no
hard iteration cap (the main session sees every review and can judge), but an
unusually long run is a signal to suspect the deliverable, not to keep
looping.

## Reviewer focus by deliverable
| Deliverable | Reviewer checks |
|---|---|
| math problem | self-contained (every symbol defined, no external ref) + faithful (vs the *actual* system/code) + solvable |
| handoff | accuracy (cross-check every commit SHA / number / fact) + completeness + actionability |
| experiment analysis | self-consistent (numbers agree) + conditional-vs-unconditional (no selection blind-spot) + confidence/fidelity labelled |
| design / plan | faithful to the real system + assumptions verified |
| code (being built) | superpowers:subagent-driven-development carries the loop (task + whole-branch reviewers); each fix gets a regression test |
| code (finished diff) | PR exists AND the code-review plugin is installed → `Skill(code-review:code-review, args: <PR#>)` as this loop's reviewer (the bare `/code-review` built-in is user-only); else → a fresh review subagent on the diff, saying which route and why |
| gate / check | ask the whole ladder at once, or it arrives one rung per round: is the VERDICT correct + does each test test what its NAME says (mutation only finds this) + what do ALL fixtures hold CONSTANT + WHICH artifact is under test (hook body? CI shell? the instrument itself?) + does the verdict BIND + what is it ABOUT (one change vs one base) + how would someone EVADE it + is every CLAIM about it true + has it run in a SECOND environment |

**Across every row: a verification NAMES the parameter it varies, and that parameter is the one the claim quantifies over.** A check that holds fixed the quantity the claim ranges over is not evidence, however often it passes. An instrument whose output will be committed asserts the precondition it depends on and runs once in a deliberately degraded mode where it MUST answer differently; a summary count may not include rows that cannot fail.

**Reviewer briefs carry the tree rules** — read-only, never mutate the reviewed tree; isolate with `git clone --no-local`, never `cp -a` (the worktree gitfile makes the copy write to the ORIGINAL, which is how a reviewer once committed to the branch under review); report `git status --porcelain` before finishing; an extracted reproduction keeps the original's shell flags and runs from inside a checkout.

## Red flags — STOP, you are about to skip the loop
- "ready to hand off as-is" / "I'm confident it's clean"
- "it's a simple / three-line / obvious thing"
- "a competent reader will catch any issue"
- "no time — just ship it"
- you made a judgment call and did **not** surface it for review

**Every one of these means: dispatch the independent reviewer first.**

## Rationalizations
| Excuse | Reality |
|---|---|
| "It's simple/obvious" | The simple-looking things are exactly where subtle bugs hide. |
| "I'm confident it's ready" | Author confidence is the failure signal, not the all-clear. |
| "Reviewing is overkill" | One review is cheaper than the next session inheriting a wrong handoff. |
| "Under time pressure" | Pressure is when the loop matters most; shipping wrong costs more time. |
| "I'll review if problems show" | On novel work the problem *is* the silent wrong output — review before. |

## Why
Independent review repeatedly catches the *author's own* wrong assumptions — misread results, off-by-one / alignment bugs, data-coverage gaps, and problem statements that need several passes before they are even solvable. None of these are visible to the author (that is what makes them the author's assumptions). "Nobody has done this before" is exactly the reason to loop, not skip.

## Not
Author self-review ≠ independent review (it is a supplement). Don't loop forever on Minors (log + triage at the end). Don't invoke for genuinely trivial work.
