---
description: Interview-driven scaffolder for a new research project — campaign lifecycle, protected trunk, machine×env matrix CLAUDE.md, project-shaped directory layout, optional external-code hosts machinery
argument-hint: [project-name]
---

Run ohd's new-project interview, then scaffold. The target user may be
research-strong but dev-weak: jargon-free wording, exactly ONE recommendation
per question, all convention decisions made FOR them (flippable at the gate).

**Every question goes through the AskUserQuestion tool** — never plain-text
questions. Batch independent questions in one call (≤4 per call). Present in
the conversation's language (Korean UI text for a Korean conversation). If
$ARGUMENTS contains a project name, that answers the name (never ask it;
`--dir` default `~/projects/<name>`, or the user's known convention).

**Objective-options principle**: everywhere a value is needed, prefer
CONCRETE plausible options over open-ended asks — use the full 4-option
budget, populate options from what you can detect (sibling projects, existing
paths, installed env managers). "Other" free text is the escape hatch, never
the designed path.

## Interview — ≤6 questions in 2–3 calls

### Call 1 — anchor + external code (batch Q0+Q2)

**Q0 SIMILAR** (header "Similar project"; ONLY if scanning the user's project
roots — the parent of `--dir`, plus any known projects directory — finds
existing projects): "Is this project shaped like one you already have?"
Options: up to 3 detected project names most likely to be relevant (label =
name; description = one line read from its top-level layout or CLAUDE.md), plus
**"No — new shape (Recommended)"**. If a project is picked: read its top two
directory levels + CLAUDE.md, infer which shape 1–4 it is, SKIP Q1, and adapt
its layout (see accelerator below). If no projects are found, skip Q0.

**Q2 EXTERNAL** — asked here (see below).

### Call 2 — shape (Q1, ONLY if Q0 skipped or answered "No"; batch with Q2b
when applicable)

**Q1 STRUCT** (header "Project shape"): "Once this project is up and running,
what will mostly pile up inside the repo? Answer for what accumulates over
time — not what exists this week."

1. **One growing program** — a single tool/library gaining features; most work
   improves that one codebase. → `src/<pkg>/`, `tests/`, optional `bench/`.
2. **Many independent pieces** — separate kernels/scripts/small models, each
   standing alone with its own tests. → one dir per piece
   (`<piece>/{code,test,bench}`) + `common/`; a single `src/` tree here would
   force false coupling.
3. **Experiment runs and results (Recommended)** — the code exists to run
   experiments (training, simulations, sweeps); what piles up is configs, run
   records, analyses. → `configs/`, thin `src/<pkg>/`,
   `experiments/<NNN-slug>/`, `analysis/`; heavy outputs go to large storage.
4. **A model plus its validation** — you build something AND systematically
   check it against reference/experimental data, study by study. → dual
   skeleton: `src/<pkg>/` grows AND `validation/<NNN-slug>/` grows.

Why #3 recommended: modal shape for computational researchers, and it degrades
gracefully (a run ledger can crystallize into a library later; retrofitting a
run ledger onto a code-only layout is the migration that never happens).
Deliberately NOT options: "umbrella around external code" (derived from Q2/Q2b,
not self-diagnosable) and "paper" (papers are outputs of shapes 1–4).

**Q2 EXTERNAL** (in Call 1; header "External code"): "Does this project build on someone
else's SOURCE code? Libraries you just install with pip/conda do NOT count —
only source you'll keep a copy of and change."

1. **No — starts fresh (Recommended)** — all code is ours; installed packages
   don't count. → no hosts machinery.
2. **Yes — I'll modify it** — real changes inside their code, you keep the
   changed copy. → fork-type host (`--host-vehicle fork`, needs
   `--host-name --host-repo --host-trunk`).
3. **Yes — small fixes only** — used as-is, occasional small patch. →
   patch-type host (`--host-vehicle patches`, needs `--host-name --host-repo`).

### Q2b — ONLY if Q2 = 2 or 3 (batch into Call 2, or its own call if Q1 was skipped)

**Q2b UMBRELLA** (header "Where edits land"): "Where will most of your
day-to-day changes actually happen?"

1. **Inside their code** — most edits land in the external project; this repo
   stays small (notes, scripts, a pin of their code). → umbrella layout: Q1's
   skeleton shrinks to a stub; repo = docs/tools/manifests + hosts.
2. **In my own code here** — the external project is a component; the real
   work is in this repo. → standard Q1 layout + hosts attached on the side.

Recommendation is dynamic: #1 when Q2 was "I'll modify it", #2 when "small
fixes only".

### Final call — logistics (batch Q3+Q4+Q5)

**Q3 COLLAB+GITHUB** (header "Who works here"): "Who will work on this repo?"

1. **Just me (Recommended)** — a private online copy is still created under
   the detected `gh` account (invisible to others) for backup + multi-machine
   sync. → `--github <owner>/<name>`, `--merge-model coordinator`, `--hook`.
2. **Me and colleagues** — others will actually EDIT, not just read. → shared
   private repo (name the shared owner via Other if not the detected one),
   `--merge-model review-gate`, `--hook`.
3. **Just me, no online copy** — local only; you lose off-machine backup and
   multi-machine sync — only if policy forbids an online copy. → `--github
   none` (warn again at the gate).

**Q4 TOPOLOGY** (header "Where it runs"): "Where will this code actually run?
Test for a shared disk: if two machines see the same files without copying,
that's a shared disk."

1. **Only this machine** → single-row machine matrix, no sync docs.
2. **Other machines too — code moves via the online repo (Recommended)** —
   separate disks; save-here, fetch-there. → `--fs separate`,
   `--node name:role[:ssh]` per remote (collect names/roles here, details at
   the gate). Conflicts with Q3=3 — flag it at the gate.
3. **Other machines too — same files visible everywhere** → `--fs shared` +
   shared-tree safety rules in CLAUDE.md (this setup has destroyed uncommitted
   work before). If you can cheaply detect a network mount, bias the
   recommendation to #3 — the dangerous error is treating a shared tree as
   separate, not the reverse.

**Q5 DATA** (header "Big data"): "Will this project use big data files — say
over ~50 MB per file or gigabytes total? Reference data you only read counts."

1. **No big files** (Recommended when Q1 ∈ {1,2}) → no data link.
2. **Yes — they live on a shared disk** (Recommended when Q1 ∈ {3,4}) —
   datasets, checkpoints, or reference data; exact path confirmed at the gate.
   → `--data-dir <path>` — at the gate, offer DETECTED candidate paths as
   options (existing large-storage dirs matching house conventions), not an
   open-ended "type the path".
3. **Yes — but no home for them yet** → create `<shared-storage>/<proj>/`,
   then `--data-dir` it; document in CLAUDE.md.

Execution-environment DETAILS (env names, conda/uv/module, per-machine) are
NOT interviewed — draft the machine×env matrix from Q4's answers plus what you
can detect on this machine, and let the user fill/fix it at the gate
(`--env name:uv|conda|module|none[@machine]`, first = primary, uv primary-only).

## Similar-project accelerator (when Q0 picks a project, or Other names one)

1. Resolve the path (user's known project roots), read its top two directory
   levels + its CLAUDE.md if present.
2. Classify each top-level entry: PATTERN (growth-axis dirs, tests/, bench/,
   tools/) vs project-specific residue (one-offs, dead experiments).
3. Propose the adapted tree with a provenance line — "Adapted from X: kept
   `src/ + bench/ + tests/`, dropped `legacy_v1/` (project-specific)".
4. Still infer and state which shape 1–4 the named project is.

## Tree proposal (before the gate)

Synthesize exactly ONE proposed tree: Q1 base skeleton, overlaid with
Q2/Q2b hosts-or-umbrella, Q5 `data/` link, Q4 matrix. Hard rules: ≤12
top-level entries; every directory gets a one-line plain-language "what goes
here" annotation; NO empty placeholder dirs "for later"; state one thing
deliberately left out and why ("no docs/ — README + CLAUDE.md is enough until
it isn't"); state the language guess ("assuming Python — flip below if not").

## Summary gate (one approval screen, loop until go)

Show: the annotated ASCII tree, then the flag list, then the auto-decisions
table — trunk=main, campaign naming (numbered), hook, merge model,
deploy=none, GitHub owner, language guess, drafted machine×env matrix. Then
ask for the verdict via AskUserQuestion: **launch as-is (Recommended)** /
edit the tree / flip an auto-decision / cancel — with any slot still needing
a value (data path, env manager per machine) offered as detected-candidate
options in the same call. Loop until an explicit go, then run:

    bash "${CLAUDE_PLUGIN_ROOT}/assets/new-project.sh" <flags...>

If the script dies at preflight, nothing was created — fix that answer and
rerun. After the script's single scaffold commit succeeds, create the APPROVED
tree (dirs + one-line README stubs where annotation warrants; never empty
placeholder dirs beyond the approved tree) and commit it as a second commit:
`layout: <shape> skeleton`.

Relay the script's output — especially the next-steps block and any manual
gh/origin commands — verbatim to the user.
