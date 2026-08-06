#!/usr/bin/env bash
# mutation_run.sh — prove the checks CAN fail.
#
# A passing suite says nothing about whether its tests are able to fail. Each
# arm mutates the tree, re-runs the check, and requires it to GO RED; the
# controls are what make that evidence mean something.
#
# Arms run SERIALLY by construction: they mutate a shared tree, so there is no
# parallel mode — concurrent arms would corrupt each other's evidence.
set -uo pipefail
SELF="$(basename "$0")"

usage() {
  cat <<EOF
$SELF — mutation testing with controls (dies on an unfalsifiable check)

  $SELF --check <cmd> --arm '<name>|<mutate>|<restore>' [--arm ...]
        [--untouched <cmd>]

  --check      the check under test. MUST pass on the clean tree (baseline).
  --arm        pipe-separated: a name, the command that injects the fault, and
               the command that undoes it. Repeatable; arms run SERIALLY.
  --untouched  a check on a phase the mutations do NOT touch. It must stay
               GREEN while an arm is applied — if a mutation breaks a phase it
               never touched, "caught" is not evidence of a sharp test.
  --self-test  run this probe's own failure path; non-zero if it is dead.

Controls run automatically: a green BASELINE (a red one makes every later
result meaningless) and a NO-OP control (the same check, unmutated, must still
pass — a check that is not repeatable cannot attribute a failure to an arm).
Inside a git work tree the porcelain status is also compared before and after:
a restore that undoes the mutation but LEAKS a file is invisible to the check.

exit: 0 every arm caught | 1 assertion/control failed | 2 usage/setup
EOF
}
die() { local c="$1"; shift; echo "$SELF: $*" >&2; exit "$c"; }
# Validate in the MAIN shell — inside "$(...)" this exit kills the subshell only,
# the missing value never shifts, and the parse loop spins on the same flag.
need() { [ -n "$2" ] || die 2 "$1 needs a value"; }
run() { sh -c "$1" >/dev/null 2>&1; }

_case() { local want="$1"; shift; local got=0; "$0" "$@" >/dev/null 2>&1 || got=$?
  [ "$got" = "$want" ] || { echo "$SELF self-test: expected exit $want, got $got — $*" >&2; return 1; }; }
self_test() {
  local d rc=0 arm; d="$(mktemp -d)"; echo GOOD > "$d/impl"
  arm="flip|sed -i s/GOOD/BAD/ $d/impl|sed -i s/BAD/GOOD/ $d/impl"
  _case 0 --check "grep -q GOOD $d/impl" --arm "$arm"                                   || rc=1
  _case 1 --check true --arm "$arm"                                                     || rc=1
  _case 1 --check false --arm "$arm"                                                    || rc=1
  _case 1 --check "grep -q GOOD $d/impl" --arm "$arm" --untouched "grep -q GOOD $d/impl" || rc=1
  # every failure above restores the tree; only a caller's non-restoring arm
  # cannot be undone, so it is checked LAST and its damage is expected
  grep -q GOOD "$d/impl" || { echo "$SELF self-test: a failing arm left the tree mutated" >&2; rc=1; }
  _case 1 --check "grep -q GOOD $d/impl" --arm "noundo|sed -i s/GOOD/BAD/ $d/impl|true"  || rc=1
  rm -rf "$d"
  [ "$rc" = 0 ] && echo "$SELF self-test: OK — caught arm passes; unfalsifiable check, red baseline, broken untouched control and non-restoring arm each DIE; tree restored"
  return "$rc"
}

CHECK=""; UNTOUCHED=""; ARMS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check)     need "$1" "${2:-}"; CHECK="$2";     shift 2 ;;
    --arm)       need "$1" "${2:-}"; ARMS+=("$2");   shift 2 ;;
    --untouched) need "$1" "${2:-}"; UNTOUCHED="$2"; shift 2 ;;
    --self-test) self_test; exit $? ;;
    -h|--help)   usage; exit 0 ;;
    *)           usage >&2; die 2 "unknown flag: $1 (arms run SERIALLY by construction — there is no parallel mode)" ;;
  esac
done
[ -n "$CHECK" ]          || die 2 "--check is required"
[ "${#ARMS[@]}" -gt 0 ]  || die 2 "at least one --arm is required"

run "$CHECK" || die 1 "BASELINE is red — the check fails on the clean tree, so no arm result would mean anything"
run "$CHECK" || die 1 "NO-OP control failed — the same check on the same clean tree gave two answers; nothing can be attributed to an arm"
[ -z "$UNTOUCHED" ] || run "$UNTOUCHED" || die 1 "the --untouched control is already red on the clean tree"

# Every restore gate below is CHECK-SCOPED: a restore that undoes the mutation
# but leaves an extra file behind keeps the check green, so a leak reports as
# full success. Inside a git work tree the porcelain status is the wider
# contract; outside one it cannot be read, and the summary says so rather than
# implying this ran.
GITWT=0; TREE0=""
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && { GITWT=1; TREE0="$(git status --porcelain 2>/dev/null)"; }

CAUGHT=0
for a in "${ARMS[@]}"; do
  name="${a%%|*}"; rest="${a#*|}"; mut="${rest%%|*}"; res="${rest#*|}"
  [ -n "$name" ] && [ -n "$mut" ] && [ -n "$res" ] && [ "$rest" != "$mut" ] \
    || die 2 "malformed --arm '$a' (want '<name>|<mutate>|<restore>')"
  run "$mut" || die 2 "arm '$name': the mutate command failed — nothing was injected"
  chk=0; run "$CHECK" || chk=$?
  unt=0; [ -z "$UNTOUCHED" ] || run "$UNTOUCHED" || unt=$?
  run "$res" || die 2 "arm '$name': the restore command FAILED — the tree is left mutated, fix it by hand"
  run "$CHECK" || die 1 "arm '$name': the check is still red AFTER restore — the restore command did not undo the mutation; the tree is left mutated, fix it by hand"
  [ "$chk" != 0 ] || die 1 "arm '$name' was NOT caught: the check passed with the fault injected, so it cannot fail"
  [ "$unt" = 0 ]  || die 1 "arm '$name' broke the --untouched control — the mutation is not localized, so 'caught' is not evidence"
  CAUGHT=$((CAUGHT + 1))
done

if [ "$GITWT" = 1 ]; then
  LEFT="$(printf '%s\n' "$(git status --porcelain 2>/dev/null)" | while IFS= read -r l; do
    [ -n "$l" ] || continue
    printf '%s\n' "$TREE0" | grep -qxF -- "$l" || printf '%s ' "${l#???}"
  done)"
  [ -z "$LEFT" ] || die 1 "the tree is DIRTIER than before the arms ran — a restore leaked OUTSIDE the --check scope, which every gate above is blind to: $LEFT(fix it by hand)"
fi

printf 'mutation_run: %d tried / %d caught / no-op control ok' "${#ARMS[@]}" "$CAUGHT"
[ -z "$UNTOUCHED" ] && printf ' / untouched control not given' || printf ' / untouched control ok'
[ "$GITWT" = 1 ] && printf ' / tree unchanged\n' || printf '\n'
[ "$GITWT" = 1 ] || echo "mutation_run: NOTE — not a git work tree, so a restore that leaks files OUTSIDE the --check scope is UNVERIFIED"
