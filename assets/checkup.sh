#!/usr/bin/env bash
# checkup.sh — harness drift doctor for projects using the ohd campaign lifecycle.
#
#   checkup.sh [project-root] [--sync]
#
# Report mode (default) prints one `item | status | detail` line per check and
# always exits 0. --sync rewrites tools/campaign.sh from the plugin's template,
# PRESERVING the project's config-block values (key-based merge: project value
# wins per variable; template supplies new variables; project-only custom
# variables are kept), REPLACING the body wholesale (body-level customizations
# do not survive — a pre-sync backup is written), and stamping
# `# synced-from ohd v<version>`.
#
# DRY: this script restates NO harness content. The template next to it IS the
# single source of truth; the script only compares and splices.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd -P)"
TPL="$HERE/campaign.sh"
PLUGVER="$(grep -o '"version": *"[^"]*"' "$HERE/../.claude-plugin/plugin.json" 2>/dev/null | head -1 | sed 's/.*"\([0-9][^"]*\)"$/\1/' || true)"
[ -n "$PLUGVER" ] || PLUGVER=unknown

ROOT="."; SYNC=0; STRUCT=0
for a in "$@"; do
  case "$a" in
    --sync) SYNC=1 ;;
    --structure) STRUCT=1 ;;
    *) ROOT="$a" ;;
  esac
done
cd "$ROOT" || { echo "checkup.sh: bad project root '$ROOT'" >&2; exit 2; }
DST="tools/campaign.sh"

# config block line numbers: first '# ──' line (contains 'config') .. next '# ──' line
cfg_range() {  # $1=file → echoes "start end" (1-based, inclusive markers); empty if absent
  local s e
  s="$(grep -n '^# ── config' "$1" | head -1 | cut -d: -f1)" || true
  [ -n "${s:-}" ] || { echo ""; return; }
  e="$(tail -n +"$((s + 1))" "$1" | grep -n '^# ──────' | head -1 | cut -d: -f1)" || true
  [ -n "${e:-}" ] || { echo ""; return; }
  echo "$s $((s + e))"
}

normalize() {  # strip config block + provenance lines → comparison view
  local f="$1" r
  r="$(cfg_range "$f")"
  if [ -n "$r" ]; then
    sed "$(echo "$r" | cut -d' ' -f1),$(echo "$r" | cut -d' ' -f2)d" "$f"
  else
    cat "$f"
  fi | grep -v '^# instantiated' | grep -v '^# synced-from'
}

report() { printf '%s | %s | %s\n' "$1" "$2" "$3"; }

# Version comparison, used by every check that reads a version stamp. Both
# consumers (trunk hook, harness-changes relay) need the DIRECTION, not just
# inequality: a stamp NEWER than this plugin's means the plugin is behind, and
# the "upgrade" advice would be a downgrade.
ver_gt() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]; }

cfg_keys() {  # $1=file → its config-block variable names, one per line
  local r; r="$(cfg_range "$1")"
  [ -n "$r" ] || return 0
  sed -n "$((${r%% *} + 1)),$((${r##* } - 1))p" "$1" | grep -o '^[A-Z_][A-Z_0-9]*=' | tr -d '=' || true
}

# ---- campaign.sh ----
NEW_KEYS=""
[ -f "$DST" ] && NEW_KEYS="$(comm -23 <(cfg_keys "$TPL" | sort) <(cfg_keys "$DST" | sort) | tr '\n' ' ')"
if [ ! -f "$DST" ]; then
  CS_STATUS=MISSING; CS_DETAIL="no $DST — --sync instantiates the template (all defaults)"
elif [ -n "${NEW_KEYS// /}" ]; then
  # a body-identical copy can still lack config vars the template gained —
  # the block is excluded from the body diff, so check its KEYS explicitly
  CS_STATUS=DRIFT; CS_DETAIL="template has new config var(s) your copy lacks: ${NEW_KEYS}— --sync adds them (your values kept)"
elif diff -q <(normalize "$TPL") <(normalize "$DST") >/dev/null 2>&1; then
  CS_STATUS=IN-SYNC; CS_DETAIL="matches template (config block excluded); $(grep -m1 '^# synced-from' "$DST" 2>/dev/null || echo 'no synced-from stamp')"
else
  CS_STATUS=DRIFT
  CS_DETAIL="$({ diff <(normalize "$TPL") <(normalize "$DST") || true; } | grep -c '^[<>]' || true) differing line(s) vs template v$PLUGVER — --sync updates while keeping your config"
fi
report "campaign.sh" "$CS_STATUS" "$CS_DETAIL"

if [ "$SYNC" = 1 ] && [ "$CS_STATUS" != "IN-SYNC" ] \
   && [ -f "$DST" ] && [ -z "$(cfg_range "$DST")" ]; then
  # markerless project copy: a blind splice would silently revert its config
  # values and drop custom vars — refuse instead of corrupting
  report "campaign.sh" "SYNC-REFUSED" "$DST has no '# ── config' markers — merge manually against the template ($TPL), then re-run"
elif [ "$SYNC" = 1 ] && [ "$CS_STATUS" != "IN-SYNC" ]; then
  mkdir -p "$(dirname "$DST")"
  TR="$(cfg_range "$TPL")"; TS="${TR%% *}"; TE="${TR##* }"
  NEW="$(mktemp)"
  {
    head -n "$((TS - 1))" "$TPL"
    [ -f "$DST" ] && grep '^# instantiated' "$DST" || true
    echo "# synced-from ohd v$PLUGVER ($(date +%F))"
    sed -n "${TS}p" "$TPL"
    # key-based merge of config inner lines
    PROJ_INNER="$(mktemp)"
    if [ -f "$DST" ]; then
      PR="$(cfg_range "$DST")"
      [ -n "$PR" ] && sed -n "$((${PR%% *} + 1)),$((${PR##* } - 1))p" "$DST" > "$PROJ_INNER"
    fi
    sed -n "$((TS + 1)),$((TE - 1))p" "$TPL" | while IFS= read -r tline; do
      if [[ "$tline" =~ ^([A-Z_][A-Z_0-9]*)= ]]; then
        pline="$(grep -m1 "^${BASH_REMATCH[1]}=" "$PROJ_INNER" || true)"
        printf '%s\n' "${pline:-$tline}"
      else
        printf '%s\n' "$tline"
      fi
    done
    # project-only custom variables survive the sync
    while IFS= read -r pline; do
      if [[ "$pline" =~ ^([A-Z_][A-Z_0-9]*)= ]] && ! grep -q "^${BASH_REMATCH[1]}=" <(sed -n "$((TS + 1)),$((TE - 1))p" "$TPL"); then
        printf '%s\n' "$pline"
      fi
    done < "$PROJ_INNER"
    rm -f "$PROJ_INNER"
    sed -n "${TE}p" "$TPL"
    tail -n +"$((TE + 1))" "$TPL"
  } > "$NEW"
  if [ -f "$DST" ]; then
    BAK="$DST.pre-sync.$(date +%F-%H%M%S)"
    cp -p "$DST" "$BAK"
  else
    BAK=""
  fi
  mv "$NEW" "$DST"; chmod +x "$DST"
  report "campaign.sh" "SYNCED" "body reset to template v$PLUGVER — body-level customizations do NOT survive sync (config keys did)${BAK:+; pre-sync copy: $BAK}; review with 'git diff $DST'"
fi

# ---- trunk hook ----
# VERSION-detected, not presence-detected: the stamp line install-hooks.sh
# writes is the contract, read from that script (DRY — no restated hook content
# here). Matching 'docs-only' alone, as this did through v0.5.22, matched every
# hook ohd ever wrote, so a CHANGED hook reported as already installed and was
# never offered to an adopted project.
# The comparison is DIRECTIONAL. Hooks live in the shared common git dir, so a
# sibling worktree running a NEWER ohd leaves a stamp ahead of the one this
# plugin ships; string inequality alone called that STALE and offered a
# re-install, which downgrades the hook.
HOOK_WANT="$(grep -m1 '^# ohd-hook v' "$HERE/install-hooks.sh" 2>/dev/null || true)"
hook_ver() { printf '%s' "${1:-}" | sed -n 's/.*ohd-hook v\([0-9][0-9.]*\).*/\1/p'; }
if HOOKS="$(git rev-parse --git-common-dir 2>/dev/null)/hooks" && [ -f "$HOOKS/pre-commit" ]; then
  HOOK_HAVE="$(grep -m1 '^# ohd-hook v' "$HOOKS/pre-commit" 2>/dev/null || true)"
  HOOK_SHOW="${HOOK_HAVE#\# }"; HOOK_SHOW="${HOOK_SHOW:-unstamped (pre-v0.5.23)}"
  if ! grep -q 'docs-only' "$HOOKS/pre-commit" 2>/dev/null; then
    report "trunk-hook" "OTHER" "a pre-commit exists but is not ohd's docs-only hook — inspect before overwriting"
  elif [ -z "$HOOK_WANT" ] || [ "$HOOK_HAVE" = "$HOOK_WANT" ]; then
    # no shipped stamp to compare against = partial install; report as before
    report "trunk-hook" "INSTALLED" "$HOOKS/pre-commit${HOOK_WANT:+ (${HOOK_WANT#\# })}"
  elif ver_gt "$(hook_ver "$HOOK_HAVE")" "$(hook_ver "$HOOK_WANT")"; then
    report "trunk-hook" "AHEAD" "installed hook $HOOK_SHOW is NEWER than this plugin's ${HOOK_WANT#\# } — a sibling worktree ran a newer ohd (hooks are shared per git common dir), so this plugin cache is likely stale: /reload-plugins or update the plugin, then re-run checkup. Do NOT reinstall the hook — that downgrades it"
  else
    report "trunk-hook" "STALE" "ohd's docs-only hook, but $HOOK_SHOW != shipped ${HOOK_WANT#\# } — re-run the plugin's assets/install-hooks.sh to pick up hook changes (it overwrites $HOOKS/pre-commit; CAMPAIGN_TRUNK / CAMPAIGN_TRUNK_ALLOW still apply)"
  fi
else
  report "trunk-hook" "MISSING" "optional; install via the plugin's assets/install-hooks.sh (skip for trunk-dev repos)"
fi

# ---- state dir ----
SD="docs/campaigns"
[ -f "$DST" ] && SD="$(grep -m1 '^STATE_DIR=' "$DST" | sed 's/.*:-\([^}]*\)}.*/\1/' || echo docs/campaigns)"
if [ -d "$SD" ]; then
  report "state-dir" "PRESENT" "$SD"
else
  report "state-dir" "MISSING" "mkdir -p $SD && touch $SD/.gitkeep (track it — campaign state docs live here)"
fi

# ---- CLAUDE.md (existence only — wiring semantics are the command's job) ----
if [ -f CLAUDE.md ]; then
  report "CLAUDE.md" "PRESENT" "wiring check (anchor/matrix/pointer/facts) is semantic — done by /ohd-checkup against the plugin's template"
else
  report "CLAUDE.md" "MISSING" "no project CLAUDE.md — /ohd-checkup drafts one from the plugin's template"
fi

# ---- always-loaded byte budget (the mass EVERY actor-wake pays, before its
#      first useful token) --------------------------------------------------
# SCOPE IS STATED IN THE ROW, deliberately: CLAUDE.md alone, PLUS any path
# named by an explicit `<!-- ohd:always-loaded <path>... -->` marker inside it.
# The marker is a MECHANICAL convention because the file that actually breaks a
# CLAUDE.md-only budget is the all-workers-must-read plan/ledger (measured at
# 168KB in one project), and detecting it by matching prose like "every worker
# must read X" is the heuristic class this harness does not ship. No marker =
# the row says so rather than implying it audited more than it did.
HOT_TARGET=20480
if [ -f CLAUDE.md ]; then
  AL_MARK="$(grep -o '<!-- *ohd:always-loaded[^>]*-->' CLAUDE.md 2>/dev/null | head -1 || true)"
  AL_B="$(wc -c < CLAUDE.md)"; AL_N=1; AL_MISS=""
  if [ -n "$AL_MARK" ]; then
    for p in $(printf '%s' "$AL_MARK" | sed 's/<!-- *ohd:always-loaded//; s/-->//'); do
      if [ -f "$p" ]; then
        AL_B=$((AL_B + $(wc -c < "$p"))); AL_N=$((AL_N + 1))
      else
        AL_MISS="$AL_MISS$p "
      fi
    done
    AL_SCOPE="across $AL_N file(s) (CLAUDE.md + the always-loaded marker list)"
  else
    AL_SCOPE="CLAUDE.md only — no \`<!-- ohd:always-loaded <path>... -->\` marker, so a plan/ledger file every worker must read is NOT in this count; add one to budget it"
  fi
  [ -z "$AL_MISS" ] || AL_SCOPE="$AL_SCOPE; marker names path(s) that do not exist: $AL_MISS"
  if [ "$AL_B" -gt "$HOT_TARGET" ]; then
    report "always-loaded" "OVER" "${AL_B}B $AL_SCOPE vs ~20KB hot target"
  else
    report "always-loaded" "OK" "${AL_B}B $AL_SCOPE vs ~20KB hot target"
  fi
else
  report "always-loaded" "NONE" "no CLAUDE.md — nothing is always-loaded, so there is no wake mass to budget (see the CLAUDE.md row)"
fi

# ---- reference tier: existence + pointer resolution + dated-claim expiry ----
# A rotted catalog MISDIRECTS, which is worse than no catalog — these two gates
# are what make the tier safe to trust, so they are constitutive, not advisory.
# Only backticked pointers in the format law's position (after the LAST ' — ')
# are resolved; a prose bullet with no pointer is left alone rather than
# guessed at, and `(example)` scaffold lines are counted, never gated.
REFD="docs/reference"
if [ ! -d "$REFD" ]; then
  report "reference" "MISSING" "no $REFD/ — the orientation tier (capabilities+gotchas / conventions+invariants+routes / state registry) is where settled facts live so sessions look them up instead of re-deriving; \`/ohd-checkup structure\` offers the scaffold"
else
  REF_CUT="$(date -d '14 days ago' +%F 2>/dev/null || date -v-14d +%F 2>/dev/null || true)"
  REF_N=0; REF_PH=0; REF_DEAD=""; REF_OLD=""
  for f in "$REFD"/*.md; do
    [ -f "$f" ] || continue
    REF_N=$((REF_N + 1))
    IS_STATE=0; [ "$(basename "$f")" = state.md ] && IS_STATE=1
    while IFS= read -r line; do
      case "$line" in
        [-*]" "*|"  "[-*]" "*) : ;;
        *) continue ;;
      esac
      case "$line" in *'(example)'*) REF_PH=$((REF_PH + 1)); continue ;; esac
      case "$line" in
        *' — '*)
          ptr="${line##* — }"
          case "$ptr" in
            *'`'*)
              p="${ptr#*\`}"; p="${p%%\`*}"; p="${p%%:[0-9]*}"
              [ -z "$p" ] || [ -e "$p" ] || REF_DEAD="$REF_DEAD$p "
              ;;
          esac ;;
      esac
      if [ "$IS_STATE" = 1 ] && [ -n "$REF_CUT" ]; then
        for d in $(printf '%s' "$line" | grep -o 'as of [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' | sed 's/as of //' || true); do
          [ "$d" \< "$REF_CUT" ] && REF_OLD="$REF_OLD$d "
        done
      fi
    done < "$f"
  done
  REF_PH_TXT="$REF_PH placeholder line(s) still to replace"
  if [ -n "$REF_DEAD$REF_OLD" ]; then
    D=""
    [ -z "$REF_DEAD" ] || D="dead pointer(s): $REF_DEAD"
    [ -z "$REF_OLD" ] || D="${D}${D:+; }state.md dated claim(s) older than 14 days: $REF_OLD"
    report "reference" "STALE" "$D — refresh the line or delete it; a reference line nobody can re-run is the misdirection this tier exists to prevent ($REF_N file(s), $REF_PH_TXT)"
  else
    NOTE=""; [ -n "$REF_CUT" ] || NOTE=" (date arithmetic unavailable — dated-claim expiry NOT checked)"
    report "reference" "OK" "$REF_N file(s), pointers resolve, no state.md claim older than 14 days, $REF_PH_TXT$NOTE"
  fi
fi

# ---- campaign census: OPEN status vs filled verdict (the false-OPEN term) ---
if [ -d "$SD" ]; then
  C_TOT=0; C_OPEN=0; C_FALSE=0
  for d in "$SD"/*.md; do
    [ -f "$d" ] || continue
    C_TOT=$((C_TOT + 1))
    grep -qiE '^[[:space:]]*[-*][[:space:]]+[*_`]*status[*_`]*:[[:space:]]*[*_`]*OPEN' "$d" 2>/dev/null || continue
    C_OPEN=$((C_OPEN + 1))
    grep -qiE '^[[:space:]]*[-*][[:space:]]+[*_`]*result / verdict[*_`]*:[[:space:]]*[^[:space:]]' "$d" 2>/dev/null \
      && C_FALSE=$((C_FALSE + 1))
  done
  report "campaigns" "$C_OPEN open/$C_TOT total, $C_FALSE false-OPEN" "false-OPEN = the doc still says \`status: OPEN\` while its \`- result / verdict:\` row is filled; grep archaeology reads those as in-flight work"
fi

# ---- structure: ONE summary line. A count is a POINTER, not an audit — the
#      default run never nags a project into structural work. -----------------
ST_CAND=0
if [ -d "$SD" ]; then
  for d in "$SD"/*.md; do
    [ -f "$d" ] || continue
    case "$d" in docs/archive/*) continue ;; esac
    grep -qiE '^[[:space:]]*[-*][[:space:]]+[*_`]*result / verdict[*_`]*:[[:space:]]*[^[:space:]]' "$d" 2>/dev/null \
      && ST_CAND=$((ST_CAND + 1))
  done
fi
[ -d "$REFD" ] || ST_CAND=$((ST_CAND + 1))
report "structure" "$ST_CAND candidates" "last full audit: no record (the structure report is output-only, so nothing here is stamped) — run /ohd-checkup structure for the work-list"

# ---- land-report audit (behavioral fossils: landed without the ritual?) ----
if [ -d "$SD" ]; then
  GAPS=""
  for d in "$SD"/*.md; do
    [ -f "$d" ] || continue
    # DELIBERATELY NOT the same rule as campaign.sh's clean gate. Their inputs
    # differ: 'clean' only sees campaigns 'campaign.sh new' opened, so it can
    # anchor on the literal '- result / verdict:' scaffold row that 'new'
    # writes, and it does. This audit reads LEGACY docs, of which only 84 of 365
    # carry that row, so anchoring on it would silently skip the other 77% —
    # the failure this audit exists to remove. It stays TOLERANT instead:
    # a REAL list marker (space after '[-*]', so a bold PARAGRAPH of
    # sub-conclusions is not a verdict row), a checkbox only when CHECKED (an
    # unchecked box is a TODO), and between marker and verdict only decoration:
    # emphasis and/or ONE space-free label key ending in ':' (no length bound —
    # a character count becomes a BYTE count under LC_ALL=C and drops non-ASCII
    # labels). Bold, backticked, translated and 'status:'-labelled verdict rows
    # are therefore AUDITED rather than skipped.
    # The cost is over-reporting: '- TODO: LANDED upstream?' with no checkbox is
    # a plan bullet, and it is reported. That is the accepted trade — this row's
    # output is a prompt to go look ("backfill honestly or annotate"), whereas
    # clean DESTROYS a worktree, which is why clean takes the strict anchor and
    # this does not. Separating those two rows needs a list of blessed label
    # words; that is the game v0.5.20 and v0.5.21 each lost.
    # The abandon exclusion below repeats the positive test's marker/checkbox
    # shape so the two stay symmetric. The hazard runs one way only: the
    # exclusion SUBTRACTS, so making it STRICTER than the positive test excludes
    # fewer docs and an ABANDONED doc starts being reported as a land-report gap.
    # (Measured over the 365-doc corpus both directions are inert — 58 flagged
    # either way — because only ONE corpus doc is excluded by this rule at all,
    # and its row uses neither a checkbox nor pre-label emphasis. Symmetry is
    # kept for the shape, not for a witness.) The table check is line-anchored
    # for its own reason: a bullet mentioning '| phase |' is prose.
    if grep -qiE '^[[:space:]]*[-*][[:space:]]+(\[[xX]\][[:space:]]*)?([*_`]*(verdict|result)[^:]*:[[:space:]]*[^[:space:]]|([^[:space:]:]+:[[:space:]]*)?[*_`]*\b(LANDS|LANDED)\b)' "$d" 2>/dev/null \
       && ! grep -qiE '^[[:space:]]*[-*][[:space:]]+(\[[xX]\][[:space:]]*)?[*_`]*(verdict|result|status)[^:]*:.*(abandon|abort)' "$d" 2>/dev/null \
       && ! grep -qiE '^[[:space:]]*\|[[:space:]]*phase[[:space:]]*\|' "$d" 2>/dev/null; then
      GAPS="$GAPS$(basename "$d") "
    fi
  done
  if [ -n "$GAPS" ]; then
    report "land-reports" "GAPS" "landed state doc(s) without a land-report table: ${GAPS}— lands that predate or skipped the ritual; backfill honestly or annotate (see campaign-land)"
  else
    report "land-reports" "OK" "every landed state doc carries its land-report table"
  fi
fi

# ---- plugin-cache staleness (session pinned to an older installed version?) ----
# Only meaningful when running from a versioned plugin cache (.../ohd/<ver>/assets);
# a dev checkout has no sibling version dirs and skips silently.
CACHE_PARENT="$(dirname "$(dirname "$HERE")")"
if [ "$PLUGVER" != unknown ] && [ "$(basename "$(dirname "$HERE")")" = "$PLUGVER" ] && [ -d "$CACHE_PARENT" ]; then
  LATEST="$(for e in "$CACHE_PARENT"/*/; do basename "$e"; done 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1 || true)"
  if [ -n "$LATEST" ] && [ "$LATEST" != "$PLUGVER" ]; then
    report "plugin-cache" "STALE" "session bound to v$PLUGVER but v$LATEST is installed — /reload-plugins (or restart the session), then re-run checkup"
  fi
fi

# ---- harness-changes (what changed since this project's last sync) ----
# Relays ONLY `BEHAVIOR-CHANGE:` marker lines from the shipped CHANGELOG.
# The judgment of what is project-facing happens at release time (authoring,
# see the plugin repo's §RELEASING) — never reconstructed here from prose.
CHLOG="$HERE/../CHANGELOG.md"
STAMP_VER=""
[ -f "$DST" ] && STAMP_VER="$(grep -m1 '^# synced-from ohd v' "$DST" 2>/dev/null | sed 's/.*ohd v\([0-9][0-9.]*\).*/\1/' || true)"
if [ -f "$DST" ] && [ ! -f "$CHLOG" ]; then
  report "harness-changes" "NO-CHANGELOG" "plugin CHANGELOG.md missing next to assets/ — partial install? change relay unavailable"
elif [ -f "$DST" ] && [ -z "$STAMP_VER" ]; then
  report "harness-changes" "NO-BASELINE" "$DST carries no synced-from stamp — one --sync establishes it; a FORK-kept copy may hand-add \`# synced-from ohd v$PLUGVER (manual)\` — NOTE: that stamps baseline=now, waiving relay of all PAST behavior changes; review the plugin CHANGELOG.md by hand once, or stamp your actual divergence version if known"
elif [ -n "$STAMP_VER" ] && [ "$PLUGVER" = unknown ]; then
  report "harness-changes" "UNKNOWN" "installed plugin version unreadable (plugin.json) — change relay skipped"
elif [ -n "$STAMP_VER" ] && [ "$STAMP_VER" != "$PLUGVER" ]; then
  if ver_gt "$STAMP_VER" "$PLUGVER"; then
    report "harness-changes" "ANOMALY" "stamp v$STAMP_VER is NEWER than this checkup's v$PLUGVER — stale session cache?; relay skipped"
  else
    BC_LINES=""; BC_N=0; CUR=""
    while IFS= read -r line; do
      case "$line" in
        "## v"*) CUR="$(printf '%s' "$line" | sed 's/^## v\([0-9][0-9.]*\).*/\1/')" ;;
        BEHAVIOR-CHANGE:*)
          if [ -n "$CUR" ] && ver_gt "$CUR" "$STAMP_VER" && ! ver_gt "$CUR" "$PLUGVER"; then
            BC_LINES="${BC_LINES}  [v$CUR] $(printf '%s' "$line" | sed 's/^BEHAVIOR-CHANGE:[[:space:]]*//')
"
            BC_N=$((BC_N + 1))
          fi ;;
      esac
    done < "$CHLOG"
    if [ "$BC_N" -gt 0 ]; then
      report "harness-changes" "REVIEW" "v$STAMP_VER -> v$PLUGVER: $BC_N behavior change(s) affect projects — read before relying on the new gates:"
      printf '%s' "$BC_LINES"
    else
      report "harness-changes" "INFO" "v$STAMP_VER -> v$PLUGVER since last sync — no flagged behavior changes (full detail: the plugin's CHANGELOG.md)"
    fi
  fi
fi

# ---- STRUCTURE MODE — the opt-in work-list generator -----------------------
# GENERATES only. Execution is ordinary project campaigns driven by this list;
# the harness never bulk-moves a project's documents itself. R22 binds every
# number here: counts and byte sizes, never estimated cost.
if [ "$STRUCT" = 1 ]; then
  echo ""
  echo "=== structure work-list (generated — the harness executes none of it) ==="
  echo "Execution is ordinary project campaigns driven by this list. Cleanup runs"
  echo "under the new rules, so the verification it touches takes the disposition"
  echo "row and the facts it excavates take the graduation row — the retrofit IS"
  echo "the reference tier's first fill."
  echo "These rules apply to the ohd HARNESS REPO ITSELF: run this mode there too."
  echo ""

  # 1. solidation candidates -------------------------------------------------
  SOL=""; SOL_N=0
  if [ -d "$SD" ]; then
    for d in "$SD"/*.md; do
      [ -f "$d" ] || continue
      case "$d" in docs/archive/*) continue ;; esac
      grep -qiE '^[[:space:]]*[-*][[:space:]]+[*_`]*result / verdict[*_`]*:[[:space:]]*[^[:space:]]' "$d" 2>/dev/null || continue
      SOL_N=$((SOL_N + 1)); SOL="$SOL  $d ($(wc -c < "$d" | tr -d ' ')B)
"
    done
  fi
  echo "## solidation — $SOL_N candidate(s): verdict filled, not yet under docs/archive/"
  [ -z "$SOL" ] || printf '%s' "$SOL"
  echo "   Move at CHECKUP or MILESTONE time, NEVER per land (the fixed-tax rule)."
  echo "   Leave the literal search key behind: \`~~old claim~~ → archive/<file>.md\`."
  echo ""

  # 2. orphan-verification census -------------------------------------------
  TF="$(mktemp)"; git ls-files -z > "$TF" 2>/dev/null || : > "$TF"
  ALLOWF=".ohd-orphan-allowlist"
  VER_RE='(^|/)((test|check|verify|probe|bench|assert|validate|sanity|smoke|measure|audit)[-_.][^/]*|[^/]*[-_](test|check|verify|probe|bench|assert|validate|sanity|smoke))\.(sh|bash|py|mjs|js)$'
  ORPH=""; ORPH_N=0; ALLOW_N=0; CAND_N=0
  while IFS= read -r -d '' f; do
    case "$f" in bench/*|tools/*|scripts/*) : ;; *) continue ;; esac
    printf '%s' "$f" | grep -qE "$VER_RE" || continue
    CAND_N=$((CAND_N + 1))
    if [ -f "$ALLOWF" ] && grep -qxF "$f" "$ALLOWF" 2>/dev/null; then
      ALLOW_N=$((ALLOW_N + 1)); continue
    fi
    base="${f##*/}"
    hit="$(xargs -0 grep -lF -- "$base" < "$TF" 2>/dev/null | grep -vxF "$f" | head -1 || true)"
    [ -n "$hit" ] && continue
    ORPH_N=$((ORPH_N + 1)); ORPH="$ORPH  $f ($(wc -c < "$f" | tr -d ' ')B)
"
  done < "$TF"
  rm -f "$TF"
  echo "## orphan verification — $ORPH_N orphan(s) of $CAND_N candidate(s), $ALLOW_N allowlisted"
  [ -z "$ORPH" ] || printf '%s' "$ORPH"
  echo "   Scope: TRACKED files under bench/ tools/ scripts/ whose NAME is in a"
  echo "   verification family (test/check/verify/probe/bench/assert/validate/"
  echo "   sanity/smoke/measure/audit). Orphan = no OTHER tracked file names it,"
  echo "   which subsumes \"no test exercises it\" — verification with no failure"
  echo "   path is where a FIXED bug stays alive in an untested duplicate."
  echo "   Disposition per file: promote to tests/, or delete. Deliberate keeps go"
  echo "   in $ALLOWF (one path per line) so the count stays honest."
  echo "   A test DIRECTORY a runner discovers by convention is out of scope: every"
  echo "   file in it has an implicit inbound reference, so scanning it would report"
  echo "   false orphans. A suite the CI config must NAME is in scope only if it"
  echo "   lives in the three directories above."
  echo ""

  # 3. plans/specs corpus + doc-size histogram ------------------------------
  TRACKED_DOCS="$(git ls-files 2>/dev/null | grep -E '^docs/.*\.md$' || true)"
  echo "## plans/specs corpus (the fastest-growing doc class measured in the field)"
  for p in docs/superpowers/plans docs/superpowers/specs docs/plans docs/specs; do
    [ -d "$p" ] || continue
    n="$(printf '%s\n' "$TRACKED_DOCS" | grep -c "^$p/" || true)"
    b=0
    for g in "$p"/*.md; do [ -f "$g" ] && b=$((b + $(wc -c < "$g"))); done
    echo "  $p: $n file(s), ${b}B"
  done
  echo "   An executed plan archives WITH its campaign."
  echo ""
  H1=0; H2=0; H3=0; H4=0; BIG=""
  if [ -n "$TRACKED_DOCS" ]; then
    while IFS= read -r g; do
      [ -f "$g" ] || continue
      s="$(wc -c < "$g" | tr -d ' ')"
      if   [ "$s" -lt 4096 ];  then H1=$((H1 + 1))
      elif [ "$s" -lt 16384 ]; then H2=$((H2 + 1))
      elif [ "$s" -lt 65536 ]; then H3=$((H3 + 1))
      else H4=$((H4 + 1)); BIG="$BIG  $g (${s}B)
"
      fi
    done <<< "$TRACKED_DOCS"
  fi
  echo "## doc-size histogram (tracked docs/**/*.md, count buckets)"
  echo "  <4KB: $H1 | 4-16KB: $H2 | 16-64KB: $H3 | >=64KB: $H4"
  [ -z "$BIG" ] || { echo "  at/over 64KB:"; printf '%s' "$BIG"; }
  echo ""

  # 4. reference tier: adoption offer ---------------------------------------
  echo "## reference tier"
  if [ -d "$REFD" ]; then
    echo "  present — $REF_N file(s). Keep the cap at 3-4 files; a fifth file is a"
    echo "  sign a fact belongs in one of the existing three."
  else
    echo "  ABSENT — adoption offer: scaffold docs/reference/ (capabilities+gotchas,"
    echo "  conventions+invariants+route map+writing router, state registry) and"
    echo "  docs/archive/ from the plugin's assets/home-set/. This is the first fill"
    echo "  target for everything listed above; without it graduated facts overflow"
    echo "  into CLAUDE.md, which every actor-wake pays for."
  fi
  echo ""

  # 5. baselines for the re-count -------------------------------------------
  echo "## baselines (this run) — paste into the cleanup campaign's state doc"
  echo "  | item | count / bytes |"
  echo "  |---|---|"
  echo "  | always-loaded set | ${AL_B:-n/a}B |"
  echo "  | solidation candidates | $SOL_N |"
  echo "  | orphan verifiers | $ORPH_N of $CAND_N candidate(s) |"
  echo "  | docs corpus (tracked .md) | $((H1 + H2 + H3 + H4)) file(s) |"
  echo "  | docs at/over 64KB | $H4 |"
  echo "  Counts and byte sizes only, by construction — re-run this mode to compare."
  echo ""
fi

printf -- '— scope: state alignment + land-report presence only (this script). Plugin presence is /ohd-checkup'"'"'s dependency pass (list owned by /ohd-setup §1); per-land ritual compliance is enforced per-land by the land gates (campaign-land). A green table attests none of: code correctness, discipline compliance.\n'
