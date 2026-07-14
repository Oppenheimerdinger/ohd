---
name: claude-md-sanity
description: >-
  Audit a repository's CLAUDE.md (+ MEMORY.md / memory/ / auto-memory) for drift —
  verifying that the self-maintaining promises the file makes about itself still
  hold against the actual code, git history, and memory store. It checks declared
  invariants and reports drift; it does NOT rewrite or improve prose (that's a
  rewriting/improver tool, if you have one). Use this whenever the user asks to
  "check / audit / sanity / 정리 / 점검" a CLAUDE.md or project memory, before
  landing/merging work that touched docs or workflow, when onboarding to a repo
  whose CLAUDE.md you don't trust is current, or periodically on a long-lived
  research repo to catch stale dated anchors, broken or dangling memory
  pointers, gotchas that point at deleted code, lock-step rules that have been
  half-landed, and bootstrap/TODO notes that were satisfied. Trigger even
  if the user says "is my CLAUDE.md still accurate?" or "the docs feel out of
  date" — this is the skill for keeping a self-maintaining doc honest.
---

# CLAUDE.md / memory sanity audit

A good CLAUDE.md is a set of **promises a project makes to its future sessions**:
"current as of date X", "if you change A also update B (두 곳!)", "read memory
`project_foo` before working here", "the ingest worker caps retries at three
attempts".
Those promises rot silently — code moves, files get renamed, a memory gets
distilled and its slug dangles, a lock-step half-lands, a date passes. The human
stops trusting the file, and the self-maintaining loop dies.

This skill **audits a CLAUDE.md against reality**: not a fixed checklist, but a
verifier of the file's *own* declared invariants. Read what the file promises, then
check each promise against the actual tree + git history + memory store, and report
what no longer holds. Do **not** silently rewrite the file — drift is information
the user needs (a stale gotcha often means a real bug already shipped). Report
first; fix only what the user approves, or only mechanically-unambiguous items on
`--fix`. Pairs with the bundled review-to-convergence skill (this is the
convergence check for a self-maintaining doc).

## Two rules that override everything below

1. **The greps are seed patterns, not the audit.** Research CLAUDE.md files are
   often **bilingual (e.g. English + Korean)** and reference memory by bare slug,
   sibling repos, and version gates — an English keyword grep misses the most
   important promises (it will sail right past a version string that must change
   in two places, an "update BOTH places! / 두 곳!" style rule). After running
   the seed greps, **read the Gotchas / Conventions /
   release / memory sections directly** for move-together, does-not-exist-yet, and
   read-this-memory phrasing the patterns miss.
2. **Never report a dimension "Clean" that you did not actually check.** A silent
   "clean" is the worst outcome — it grants false confidence on exactly the
   rot-prone pointers. If a promise can't be machine-verified (slug you can't
   resolve, cross-repo file, semantic invariant), route it to **MANUAL-CHECK**
   explicitly. "I couldn't verify X" is a finding, not a pass.

## Scope

Default target: the CLAUDE.md at the **repo root the session is anchored at**. Then
enumerate nested docs and audit each (umbrella repos may carry nested docs, e.g.
`hosts/<name>/CLAUDE.md`):
```bash
find . -name CLAUDE.md -not -path '*/.git/*'; ls MEMORY.md memory/ 2>/dev/null
```
If the user names a specific file, audit that. Don't wander outside the repo —
references that point *out* of it are their own finding type (Check 4).

**No git history?** (not a repo, or a shallow clone with no tags) — the dated-anchor
and tag-based lock-step checks can't run; degrade those to MANUAL-CHECK and say so,
rather than silently passing them.

## Severity

- **BROKEN** — a promise now false: a pointer to a file/symbol/path/slug that
  doesn't exist, an invariant the tree violates (VERSION ≠ tag ≠ header), a memory
  index line whose target is gone. These actively mislead — rank first.
- **STALE** — true but aging: a *vouching* stamp past its freshness window, a
  satisfied bootstrap/TODO note. (NOT historical lesson dates — see Check 1.)
- **WATCH** — correct *today only because a paired qualifier holds elsewhere*: a
  present-tense claim ("`origin` on every machine") rescued by a bootstrap footer,
  a "fixed in v1.4.0+" gotcha. Not false (so not BROKEN), not aging (so not STALE),
  but it silently rots into BROKEN the moment its paired qualifier is removed
  without updating it. Name **both** halves that must move together.
- **MANUAL-CHECK** — a real promise you can't verify mechanically (a semantic
  invariant like "OFF path stays byte-identical", an unresolvable slug, a
  cross-repo file). Hand the human the exact thing to confirm.

## Checks

Run each; collect findings; present one report at the end. Prefer running the
command and reporting evidence over eyeballing. For an invariant whose **governed
set is empty** (no kernels, no tags yet), report it as **Clean (verified-empty)** —
state you checked and found nothing to violate, don't silently omit it.

### 1. Dated-anchor freshness — vouching stamps ONLY

Only stamps that *vouch for currency* are freshness anchors:
`current as of`, `Verdicts current as of`, `as of <SHA>`, `이 파일 … 기준`,
`현재 … 기준`. Extract and compare against the git history of what they cover
(`git log -1 --format=%cs -- <path>` + today's date from the environment); flag
`STALE` when the stamp is well behind the last real change to that area, weighed
against how fast it moves. When you genuinely can't tell whether a stamp is behind,
prefer MANUAL-CHECK over STALE — a false STALE on an accurate stamp is exactly the
noise that gets an audit muted.
```bash
grep -nE '([Cc]urrent as of|[Vv]erdicts current as of|as of [0-9a-f]{7,}|기준)' CLAUDE.md
```
**Do NOT treat as freshness anchors** (these are *historical annotations* —
permanent records of when a lesson was learned, **never STALE**): parenthetical
lesson dates like `(2026-06-15: <past event>)`, gotcha-log entries, and a bare date
inside prose. Also ignore dates that are part of a **filename** (e.g.
`2026-06-30-design.md`). When in doubt whether a date vouches or records, it
records → leave it.

**Version-gated claims** (`(v1.4.0+)`, `fixed in v1.4.0`) age like dates without a
calendar date — Check 1's grep won't see them. If you spot one, it's a
MANUAL-CHECK: "does this still hold at the current version?"

### 2. Lock-step invariant verification (bilingual)

The strongest self-maintaining device is a "these move together" rule. Seed grep,
then **read the release/conventions sections directly** (the real rule is often
Korean — `두 곳!` = "two places!", `함께`/`같이`/`동시에` = "together"):
```bash
grep -niE 'lock.?step|same (PR|commit)|must (equal|agree|match)|in lock|1:1|두 ?곳|함께|같이|동시에|반드시.*(맞|일치)' CLAUDE.md
```
For each rule, verify the invariant **on the tree** as far as it's mechanical:
- "two version strings must agree" / "VERSION == tag == header" → read each string
  (e.g. `pyproject.toml` version **and** `__init__.py __version__`), `git tag --list`,
  grep the header; assert they match. Mismatch = `BROKEN`.
- "every X has a catalog/README row" → list the X's, grep the table; orphan rows
  and missing rows = `BROKEN`.
- "every source file carries a provenance header" → grep each file's head.
- **Empty governed set** (no X's / no tags yet) → Clean (verified-empty).
Semantic remainders (e.g. "OFF path stays byte-identical", "re-run the parity deck
if it touches the same path") can't be machine-checked → `MANUAL-CHECK` naming the
recent change that should have triggered it.

### 3. Memory-pointer liveness (files AND bare slugs)

Project memory comes in two forms — verify both, and never report this dimension
clean if you only checked one form:
- **File/dir pointers:** `MEMORY.md`, `memory/<slug>.md`, `[[wiki-links]]`,
  `(+ memory/)` bare-dir refs. `test -e` each; dead pointer = `BROKEN`. Bidirectional
  MEMORY.md sync: index line whose file is gone = `BROKEN`; `memory/*.md` with no
  index line = `STALE` (un-indexed memory is invisible).
- **Auto-memory slugs:** referenced by bare name, often in Korean —
  `메모리 \`project_foo\``, `auto-memory \`bar.md\``, `Memory: baz-discipline`.
  These are the MOST rot-prone (a memory gets distilled/renamed and the reference
  dangles), and a file-only grep finds NONE of them → silent false "clean".
```bash
grep -noE '(memory/[A-Za-z0-9_-]+\.md|MEMORY\.md|\[\[[a-z0-9-]+\]\]|(메모리|auto-memory|Memory:) *`?[A-Za-z0-9_-]+)' CLAUDE.md MEMORY.md 2>/dev/null
```
(This line-based grep misses a slug wrapped across a newline — `auto-memory` ending
one line, the backticked slug starting the next — so the direct section read of
rule 1 is the real backstop here.) Try to resolve each slug against the harness
memory store (search the project's
memory dir — see the global CLAUDE.md for where it lives — for `<slug>.md`). If you
**cannot** resolve a slug mechanically, route it to MANUAL-CHECK ("confirm memory
`<slug>` still exists"); do not call Check 3 clean while slugs went unresolved.

### 4. Gotcha → code liveness (in-tree only)

Gotchas name concrete files/symbols/scripts (`tools/fetch.py`, `_codegen.py`,
`ENABLE_FAST_PATH`). A gotcha pointing at code that's *gone* implies a safeguard
that vanished = `BROKEN`. But two carve-outs prevent false alarms:
- **Out-of-tree references** — qualified by `<fork>/`, `hosts/<name>/`, another repo
  name, or another machine's path (`/usr/local/...`, a remote GPU box's path): the file is
  supposed to live elsewhere → `MANUAL-CHECK`, never BROKEN. (some repos are half
  cross-repo by design.)
- **Bootstrap-absent, not deleted** — if a missing target is covered by a still-valid
  "does not exist yet" note (Check 6), it's expected absence, not BROKEN.
- **In-tree-shaped path that's absent** — before excusing it ("probably on a GPU
  node"), run `git log --all -- <path>`: a removal/relocation commit upgrades the
  absence to a **definitive BROKEN** (the subsystem/safeguard is gone — e.g. a
  CLAUDE.md section describing `src/legacy_parser/` after that code was relocated
  to another repo). Only a path with no local history *and* a bootstrap note is
  expected-absence.
Only grep for references with a verifiable **path/symbol shape** (`tools/`, `*.py`,
`*.sh`, `*.cu`, `*.md`, an ALL_CAPS env var); skip backticked prose, commands
(`gh pr merge`), values (`1 Ry/Bohr²`), and tokens containing spaces or `=`.

### 5. Session-anchor / topology consistency

If CLAUDE.md declares an anchor + memory location ("always open at this repo root",
"memory at <path>"), confirm they match the audited root and the stated paths exist.
A CLAUDE.md that anchors sessions where the repo isn't, or reads memory from a moved
path, sends every future session wrong = `BROKEN`. A path that's merely *pending*
(bootstrap-noted) = `WATCH`, not BROKEN.

### 6. Bootstrap / TODO residue (bilingual, condition-checked)

`BOOTSTRAP`, `does not exist yet`, `TBD`, `TODO`, "until X ships", and Korean
`아직 없`/`미구현`/`예정`/`존재하지 않` are promises about *absence*. The grep only
*finds* them — the audit is **checking whether the condition is now met**. A naive
keyword-only flag produces pure false positives on a healthy bootstrap repo, so for
each hit, actually `test -e` / `git remote -v` / `git tag` the thing it waved off:
```bash
grep -niE 'BOOTSTRAP|does not exist yet|not (yet )?(implemented|present)|TBD|TODO|until .*(ships|lands)|아직 ?(없|미구현)|예정|존재하지 ?않' CLAUDE.md README.md
```
- Condition now met → `STALE` ("remove this note / drop the qualifier").
- Condition still unmet → no finding (the note is doing its job).
- **Compound note** (one block gated on several conditions, e.g. a repo's bootstrap
  note gating on four separate conditions) → removable only when **ALL** are
  verified met. On partial satisfaction, `STALE` proposal listing which
  sub-conditions are now true — never an auto-remove.
- Ignore freshness-stamp uses of the word ("current as of … (trunk bootstrap)").

### 7. Project-specific living docs (only if present)

Audit only if they exist — don't invent docs: a `capability-matrix.md` (spot-check
3–5 cells — those whose code changed most recently — vs code/test status; stale cell
→ MANUAL-CHECK unless trivially checkable),
`docs/campaigns/` (open campaign with no status update in its own stated cadence →
STALE), `docs/INVARIANTS.md`. Skip entirely for lightweight repos.

## Report format

One report, most-actionable first. Audit each CLAUDE.md found (root + nested)
under its own heading.

```
# CLAUDE.md sanity — <repo>  (<today>, trunk <sha>)

BROKEN (N)        ← fix before trusting the file
- CLAUDE.md:LL — <promise> → <what's actually true> → <fix>
STALE (N)         ← refresh when convenient
- <file:LL> — <stamp/note> → <why aging> → <fix>
WATCH (N)         ← correct only while a paired qualifier holds
- <file:LL> — <claim> ⟂ <the qualifier propping it up> → <the pair that must move together>
MANUAL-CHECK (N)  ← needs your eyes (couldn't verify mechanically)
- <file:LL> — <the promise> → <the exact thing to confirm>

Clean: <dimensions actually verified — e.g. "memory pointers (3 slugs resolved),
        version lock-step (verified-empty), anchor topology">
```

Always say what passed AND how you verified it — "memory pointers all live (resolved
4 slugs)", "lock-step verified-empty (no tags/kernels yet)". Listing *how* is what
distinguishes a real pass from an unchecked one (rule 2).

## Fixing

Default to **report-only** — drift is diagnostic (a stale gotcha can mean a real
regression shipped; the user should see it before it's papered over). On `--fix`,
apply only **mechanically unambiguous** items: remove a *fully*-satisfied bootstrap
note (all conditions met — never a partially-satisfied compound one), sync a
MEMORY.md index line to an existing file, correct a version string to match its tag.
Leave judgment calls (rewording a gotcha, deciding a date is "fine", a WATCH pair)
as proposals. Never edit code to satisfy a doc — if doc and code disagree, the
report is the point.
