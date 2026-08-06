#!/usr/bin/env bash
# provenance_block.sh — record WHICH ROUTE actually ran, as a compact artifact.
#
# "Which backend/kernel/device did this run use" should be a recorded fact next
# to the result, not archaeology performed weeks later against a rotated log.
set -uo pipefail
SELF="$(basename "$0")"

usage() {
  cat <<EOF
$SELF — compact route proof for a run artifact

  $SELF [--field <k>=<v>]... [--cmd <k>=<command>]... [--env-prefix <P>]...
        [--require <k>]... [--out <file>]

  --field       a value you already know (backend=fused, kernel=v3).
  --cmd         a value to resolve by running a command; the first line of its
                stdout becomes the value. A command that fails is recorded as
                \`<k>=unavailable(<exit>)\` — RECORDED, never silently dropped.
  --env-prefix  emit every active environment variable with this prefix (the
                flags that actually select a route). The prefix is echoed even
                when nothing matches, so an empty result is not mistaken for
                "no flags were set".
  --require     die if this key is missing or unavailable — the exit-code-shaped
                form, for a runner that must refuse to proceed on a blind route.
  --out         also write the block to this file (stdout always gets it).
  --self-test   run this probe's own failure path; non-zero if it is dead.

exit: 0 block emitted | 1 a --require key is missing/unavailable | 2 usage
EOF
}
die() { local c="$1"; shift; echo "$SELF: $*" >&2; exit "$c"; }
# Validate in the MAIN shell — inside "$(...)" this exit kills the subshell only,
# the missing value never shifts, and the parse loop spins on the same flag.
need() { [ -n "$2" ] || die 2 "$1 needs a value"; }

_case() { local want="$1"; shift; local got=0; "$0" "$@" >/dev/null 2>&1 || got=$?
  [ "$got" = "$want" ] || { echo "$SELF self-test: expected exit $want, got $got — $*" >&2; return 1; }; }
self_test() {
  local rc=0
  _case 0 --field backend=fused --require backend                  || rc=1
  _case 1 --field backend=fused --require kernel                   || rc=1
  _case 1 --cmd gpu='exit 7' --require gpu                         || rc=1
  _case 2 --field bogus                                            || rc=1
  "$0" --cmd gpu='exit 7' 2>/dev/null | grep -q 'gpu=unavailable' \
    || { echo "$SELF self-test: an unresolvable field was dropped instead of recorded" >&2; rc=1; }
  [ "$rc" = 0 ] && echo "$SELF self-test: OK — block emits; a missing or unavailable --require key DIES; unresolvable values are recorded, not dropped"
  return "$rc"
}

BODY=""; PREFIXES=(); REQUIRE=(); OUT=""
add() { BODY="$BODY$1=$2
"; }
while [ $# -gt 0 ]; do
  case "$1" in
    --field)      need "$1" "${2:-}"; kv="$2"; case "$kv" in *=*) : ;; *) die 2 "--field wants <k>=<v>, got '$kv'";; esac
                  add "${kv%%=*}" "${kv#*=}"; shift 2 ;;
    --cmd)        need "$1" "${2:-}"; kv="$2"; case "$kv" in *=*) : ;; *) die 2 "--cmd wants <k>=<command>, got '$kv'";; esac
                  k="${kv%%=*}"; c=0; v="$(sh -c "${kv#*=}" 2>/dev/null | head -1)" || c=$?
                  [ "$c" = 0 ] && [ -n "$v" ] || v="unavailable($c)"
                  add "$k" "$v"; shift 2 ;;
    --env-prefix) need "$1" "${2:-}"; PREFIXES+=("$2"); shift 2 ;;
    --require)    need "$1" "${2:-}"; REQUIRE+=("$2"); shift 2 ;;
    --out)        need "$1" "${2:-}"; OUT="$2"; shift 2 ;;
    --self-test)  self_test; exit $? ;;
    -h|--help)    usage; exit 0 ;;
    *)            usage >&2; die 2 "unknown argument: $1" ;;
  esac
done

[ "${#PREFIXES[@]}" -eq 0 ] || for p in "${PREFIXES[@]}"; do
  n="$(env | grep -c "^$p" || true)"
  add "env-prefix" "$p ($n match(es))"
  [ "$n" = 0 ] || BODY="$BODY$(env | grep "^$p" | sed 's/^/env./' | sort)
"
done

GIT="$(git rev-parse --short HEAD 2>/dev/null || echo n/a)"
# `git diff --quiet` exits 129 outside a work tree, which a bare `||` reads as
# "dirty" — the n/a guard keeps an unknown revision from growing a fabricated flag
[ "$GIT" = n/a ] || git diff --quiet 2>/dev/null || GIT="$GIT-dirty"
BLOCK="--- ohd provenance ---
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
host=$(hostname 2>/dev/null || echo n/a)
git=$GIT
${BODY}--- end provenance ---"

printf '%s\n' "$BLOCK"
[ -z "$OUT" ] || printf '%s\n' "$BLOCK" > "$OUT"

[ "${#REQUIRE[@]}" -eq 0 ] || for k in "${REQUIRE[@]}"; do
  v="$(printf '%s' "$BODY" | grep -m1 "^$k=" | cut -d= -f2- || true)"
  [ -n "$v" ] || die 1 "--require $k: no such field in the block — the route is unproven"
  case "$v" in unavailable*) die 1 "--require $k: $v — the route could not be resolved, refusing to proceed blind" ;; esac
done
