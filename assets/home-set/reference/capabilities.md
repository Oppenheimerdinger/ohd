# Capabilities & gotchas

What this project can already DO, and the traps that bite — present tense only.
Read this before any tree archaeology: orientation is a lookup, not a
re-derivation. History lives in `docs/campaigns/` and `docs/archive/`, plans in
`docs/superpowers/`, what is in flight in `state.md`.

**Format law — every line points at executable truth.** A line is
`<claim> — <file:line of a test, gate, or config>`. A reader who doubts the
claim RE-RUNS the pointer: independent evidence at tool cost, instead of
trusting a cached result or re-deriving by agent-scan. A claim with no runnable
anchor does not belong here (`state.md` is the one exception, and it says why).

Replace the `(example)` lines below as real entries arrive — `/ohd-checkup`
counts them so an untouched scaffold stays visible.

## Capabilities

- (example) the end-to-end pipeline runs on the default path — `tests/test_pipeline.py:14`
- (example) batch size 64 fits the default device — `configs/default.yaml:22`

## Gotchas

- (example) the loader silently drops rows whose key is null — `tests/test_loader.py:88`
- (example) `--fast` skips the checksum, so a corrupt cache survives it — `src/cache.py:210`
