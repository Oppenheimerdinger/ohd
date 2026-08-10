# Conventions, invariants, routes

How this project is built and what must stay true. Same **format law — every
line points at executable truth** — as `capabilities.md`: a line is
`<claim> — <file:line of a test, gate, or config>`, so a doubtful reader
re-runs the pointer instead of re-deriving.
A convention nobody can check is a preference; write it as a gate or leave it
out.

Replace the `(example)` lines as real entries arrive.

## Conventions

- (example) every public entry point takes an explicit device argument — `tests/test_api.py:31`
- (example) generated files are written atomically via a temp + rename — `src/io.py:64`
- (example) a helper with more than one caller carries `VALID FOR:` / `NOT VALID FOR:` in its docstring — the regime it was derived under, and the ones where it silently returns a wrong number — `src/physics/screening.py:12`
- (example) that docstring also carries `DERIVATION: <doc#anchor>`, so the next caller reads the derivation instead of inferring the regime from a call site — `tests/test_screening.py:44`

## Invariants

- (example) output rows are sorted by key before writing — `tests/test_writer.py:57`
- (example) the config schema rejects unknown keys — `tests/test_config.py:19`

## Route map

The same computation usually has SEVERAL execution routes, and a silent
wrong-route run is near-invisible: agents read logs through tails and
summarizers, so a warning line is structurally unseen. One row per multi-route
computation. The assertion is what PROVES engagement, and must be
exit-code-shaped: **die non-zero** on a mismatch, never warn and continue.

| computation | routes | canonical | assertion that proves engagement |
|---|---|---|---|
| (example) matmul | fused kernel / reference loop | fused kernel | `probes/engage_grep.sh --must 'kernel=fused' --must-not 'fallback' --anchor 'run complete' run.log` |

`engage_grep.sh`, `mutation_run.sh` and `provenance_block.sh` ship with the ohd
plugin (`assets/probes/`) — copy them in rather than re-implementing a grep per
campaign.

## The writing router

Consult this table BEFORE creating any document. Without it the flat-corpus
habit reproduces itself one "just this one file" at a time.

| you are about to write... | it goes to | form |
|---|---|---|
| campaign narrative / results | the campaign's state doc (append) | existing scaffold |
| a present-tense fact, interface, gotcha, route | `docs/reference/` | one line + executable-truth pointer |
| what is running / in flight | `docs/reference/state.md` | dated line, 14-day expiry |
| a lesson / decision / failure | land-time distill (memory / `docs/backlog.md`) | existing Phase-6 rules |
| a plan / spec | `docs/superpowers/` | archives when executed |
| a one-off analysis | a SECTION of the requesting campaign's doc | never a new root doc |

**Rule: a NEW root-level document requires naming its home and why no existing
home fits** — the same attested-skip shape as every other gate in this harness.
