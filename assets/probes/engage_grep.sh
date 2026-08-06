#!/usr/bin/env bash
# engage_grep.sh — assert which execution route ACTUALLY ran, from a run's log.
#
# Agents read logs through tails and summarizers, so a warning line is
# structurally unseen. This probe DIES; it never warns. The exit code is the
# only channel that survives an agent consumer.
set -uo pipefail
SELF="$(basename "$0")"

usage() {
  cat <<EOF
$SELF — route-engagement assertion over run logs (dies on mismatch, never warns)

  $SELF --must <str> [--must <str>]... [--must-not <str>]...
        (--anchor <str> | --no-anchor <reason>) [--regex] <file>...

  --must        a line that MUST appear (the route marker). Repeatable.
  --must-not    a line that must NOT appear (the fallback marker). Repeatable.
  --anchor      positive-state marker proving the run REACHED the end; without
                it a crashed run satisfies every --must-not vacuously.
  --no-anchor   attested skip — give the reason; it is printed in the proof.
  --regex       match as ERE. Default is FIXED-STRING: a hand-rolled regex that
                can never match is the measured failure this default prevents.
  --self-test   run this probe's own failure path; non-zero if it is dead.

Matching has NO line context: a marker in a comment, in a usage string or in an
echoed config counts exactly like the state line you meant. Choose markers only
an actual state line can carry.

exit: 0 route proven engaged | 1 assertion failed | 2 usage/setup
EOF
}
die() { local c="$1"; shift; echo "$SELF: $*" >&2; exit "$c"; }
# Validate in the MAIN shell. Called from inside "$(...)" this exit kills the
# subshell only, the missing value never shifts, and the parse loop below reads
# the same flag forever — a hang where an exit code was the entire contract.
need() { [ -n "$2" ] || die 2 "$1 needs a value"; }

_case() {  # _case <expected-exit> <args...> — the probe run against itself
  local want="$1"; shift; local got=0
  "$0" "$@" >/dev/null 2>&1 || got=$?
  [ "$got" = "$want" ] || { echo "$SELF self-test: expected exit $want, got $got — $*" >&2; return 1; }
}
self_test() {
  local d rc=0; d="$(mktemp -d)"
  printf 'start\nbackend=fast\nrun complete\n' > "$d/ok.log"
  printf 'start\nbackend=fast\n'               > "$d/crashed.log"
  _case 0 --must backend=fast --must-not fallback --anchor 'run complete' "$d/ok.log" || rc=1
  _case 1 --must backend=slow --anchor 'run complete' "$d/ok.log"                     || rc=1
  _case 1 --must backend=fast --must-not 'backend=' --anchor 'run complete' "$d/ok.log" || rc=1
  _case 1 --must backend=fast --anchor 'run complete' "$d/crashed.log"                || rc=1
  _case 2 --must backend=fast "$d/ok.log"                                             || rc=1
  _case 2 --must backend=fast --anchor x "$d/absent.log"                              || rc=1
  rm -rf "$d"
  [ "$rc" = 0 ] && echo "$SELF self-test: OK — pass; missing marker, forbidden marker and missing anchor each DIE; unattested anchor skip and missing file refused"
  return "$rc"
}

MUST=(); NOT=(); FILES=(); ANCHOR=""; SKIP=""; MODE=-F
while [ $# -gt 0 ]; do
  case "$1" in
    --must)      need "$1" "${2:-}"; MUST+=("$2"); shift 2 ;;
    --must-not)  need "$1" "${2:-}"; NOT+=("$2");  shift 2 ;;
    --anchor)    need "$1" "${2:-}"; ANCHOR="$2";  shift 2 ;;
    --no-anchor) need "$1" "${2:-}"; SKIP="$2";    shift 2 ;;
    --regex)     MODE=-E; shift ;;
    --self-test) self_test; exit $? ;;
    -h|--help)   usage; exit 0 ;;
    -*)          usage >&2; die 2 "unknown flag: $1" ;;
    *)           FILES+=("$1"); shift ;;
  esac
done

[ "${#MUST[@]}" -gt 0 ]  || die 2 "at least one --must is required (there is no assertion without it)"
[ "${#FILES[@]}" -gt 0 ] || die 2 "no log file given"
[ -n "$ANCHOR" ] || [ -n "$SKIP" ] \
  || die 2 "--anchor is required, or skip it explicitly with --no-anchor <reason>: without a positive-state anchor a run that CRASHED early passes every --must-not vacuously"
for f in "${FILES[@]}"; do [ -f "$f" ] || die 2 "log file not found: $f (a missing log is not a passing assertion)"; done

hit() { grep -q "$MODE" -e "$1" -- "${FILES[@]}" 2>/dev/null; }

for m in "${MUST[@]}"; do
  hit "$m" || die 1 "route marker NOT found: '$m' — the expected route did not run (or never logged it)"
done
[ "${#NOT[@]}" -eq 0 ] || for m in "${NOT[@]}"; do
  ! hit "$m" || die 1 "forbidden marker present: '$m' — a fallback/wrong route engaged"
done
[ -z "$ANCHOR" ] || hit "$ANCHOR" \
  || die 1 "positive-state anchor missing: '$ANCHOR' — the run did not reach the end, so every assertion above is vacuous"

printf 'engage_grep: OK — %d must' "${#MUST[@]}"
[ "${#NOT[@]}" -eq 0 ] || printf ', %d must-not' "${#NOT[@]}"
if [ -n "$ANCHOR" ]; then printf ", anchor '%s'" "$ANCHOR"; else printf ', anchor SKIPPED (attested: %s)' "$SKIP"; fi
printf ' [%s] over %d file(s)\n' "$([ "$MODE" = -F ] && echo fixed-string || echo regex)" "${#FILES[@]}"
