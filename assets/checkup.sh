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
# A '# synced-from ohd vX.Y.Z (fork)' stamp is VERSION-PINNED ACCEPTANCE of a
# deliberately divergent copy. It suppresses the line-diff nag and NOTHING
# else: the config-key check below and the BEHAVIOR-CHANGE relay further down
# both keep firing, because a fork still needs to hear about new knobs and
# changed contracts. The version in the stamp is what makes it expire — once
# the running plugin moves past it, the row asks for a review and a restamp
# rather than going quiet forever.
FORK_VER=""
[ -f "$DST" ] && FORK_VER="$(grep -m1 '^# synced-from ohd v.*(fork)' "$DST" 2>/dev/null | sed 's/.*ohd v\([0-9][0-9.]*\).*/\1/' || true)"
if [ ! -f "$DST" ]; then
  CS_STATUS=MISSING; CS_DETAIL="no $DST — --sync instantiates the template (all defaults)"
elif [ -n "${NEW_KEYS// /}" ]; then
  # a body-identical copy can still lack config vars the template gained —
  # the block is excluded from the body diff, so check its KEYS explicitly
  CS_STATUS=DRIFT; CS_DETAIL="template has new config var(s) your copy lacks: ${NEW_KEYS}— --sync adds them (your values kept)"
elif diff -q <(normalize "$TPL") <(normalize "$DST") >/dev/null 2>&1; then
  CS_STATUS=IN-SYNC; CS_DETAIL="matches template (config block excluded); $(grep -m1 '^# synced-from' "$DST" 2>/dev/null || echo 'no synced-from stamp')"
elif [ -n "$FORK_VER" ]; then
  CS_STATUS=FORK
  if ver_gt "$PLUGVER" "$FORK_VER"; then
    CS_DETAIL="accepted fork, upstream v$FORK_VER→v$PLUGVER — review and restamp \`# synced-from ohd v$PLUGVER (fork)\` once you have; line diff suppressed, config-key drift and BEHAVIOR-CHANGE relay still report"
  else
    CS_DETAIL="accepted fork stamped at v$FORK_VER — line diff suppressed; config-key drift and BEHAVIOR-CHANGE relay still report"
  fi
else
  CS_STATUS=DRIFT
  CS_DETAIL="$({ diff <(normalize "$TPL") <(normalize "$DST") || true; } | grep -c '^[<>]' || true) differing line(s) vs template v$PLUGVER — --sync updates while keeping your config"
fi
report "campaign.sh" "$CS_STATUS" "$CS_DETAIL"

if [ "$SYNC" = 1 ] && [ -n "$FORK_VER" ] && [ "$CS_STATUS" != "IN-SYNC" ]; then
  # Without this, the fork stamp arms a one-command fork-destroyer: --sync
  # resets the body to the template AND drops the marker recording that the
  # divergence was deliberate, leaving no trace of either.
  report "campaign.sh" "FORK-REFUSED" "$DST carries a '(fork)' stamp — --sync would overwrite the fork's body and drop the stamp that records it. Merge by hand against $TPL, then restamp \`# synced-from ohd v$PLUGVER (fork)\`"
elif [ "$SYNC" = 1 ] && [ "$CS_STATUS" != "IN-SYNC" ]; then
  if [ -f "$DST" ] && [ -z "$(cfg_range "$DST")" ]; then
    # markerless project copy: a blind splice would silently revert its config
    # values and drop custom vars — refuse instead of corrupting
    report "campaign.sh" "SYNC-REFUSED" "$DST has no '# ── config' markers — merge manually against the template ($TPL), then re-run"
  else
    mkdir -p "$(dirname "$DST")"
    TR="$(cfg_range "$TPL")"; TS="${TR%% *}"; TE="${TR##* }"
    # the template's config INNER lines, cut once: both the merge loop below and
    # its per-project-line "is this key ours?" test read the same slice
    TPL_INNER="$(mktemp)"
    sed -n "$((TS + 1)),$((TE - 1))p" "$TPL" > "$TPL_INNER"
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
      while IFS= read -r tline; do
        if [[ "$tline" =~ ^([A-Z_][A-Z_0-9]*)= ]]; then
          pline="$(grep -m1 "^${BASH_REMATCH[1]}=" "$PROJ_INNER" || true)"
          printf '%s\n' "${pline:-$tline}"
        else
          printf '%s\n' "$tline"
        fi
      done < "$TPL_INNER"
      # project-only custom variables survive the sync
      while IFS= read -r pline; do
        if [[ "$pline" =~ ^([A-Z_][A-Z_0-9]*)= ]] && ! grep -q "^${BASH_REMATCH[1]}=" "$TPL_INNER"; then
          printf '%s\n' "$pline"
        fi
      done < "$PROJ_INNER"
      rm -f "$PROJ_INNER"
      sed -n "${TE}p" "$TPL"
      tail -n +"$((TE + 1))" "$TPL"
    } > "$NEW"
    rm -f "$TPL_INNER"
    if [ -f "$DST" ]; then
      BAK="$DST.pre-sync.$(date +%F-%H%M%S)"
      cp -p "$DST" "$BAK"
    else
      BAK=""
    fi
    mv "$NEW" "$DST"; chmod +x "$DST"
    report "campaign.sh" "SYNCED" "body reset to template v$PLUGVER — body-level customizations do NOT survive sync (config keys did)${BAK:+; pre-sync copy: $BAK}; review with 'git diff $DST'"
  fi
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

# ---- CI coherence (issue #31) — the ONLY network call this script makes ----
# REPORT-ONLY, and guarded on both ends. It fires only when the project has
# something to BE coherent about (a retirement declaration, or a workflows
# directory); on a project with neither there is no row at all, rather than a
# row saying nothing. Every network failure mode — no gh, dead auth, non-GitHub
# origin, a 403 on the protection half — degrades to MANUAL-CHECK and the
# script still exits 0, because an offline laptop must not turn a doctor into a
# failure. State changes (disable, unbind) are OWNER actions: this row hands
# over the #31 checklist and stops.
#
# THREE signals, because two of them lie on their own. A declaration says what
# the project INTENDS; `gh workflow list` says what still RUNS; and required
# checks say what still BLOCKS. The field case (issue #31) was exactly the
# disagreement: workflows retired, a required check left bound, every land
# bypassing with --admin. Reading only the first two would have called that
# repo consistent.
#
# The rulesets endpoint is not redundant with branch protection. Checks bound
# via a RULESET are invisible to `branches/<b>/protection`, and — measured —
# `rules/branches/<b>` stays readable with a plain token where the protection
# endpoint can 403. It is the call that cannot 403 — but it can still FAIL
# (timeout, network, a non-200 answer), so it carries its own blind flag; see
# CI_RULES_BLIND below. Neither half is trusted to be readable: a 403 on the
# protection half degrades only that half, and either half going blind
# degrades the row to MANUAL-CHECK rather than to a verdict.
CI_DECL="$(grep -hE '^[[:space:]]*-[[:space:]]*ci:[[:space:]]*retired' CLAUDE.md docs/reference/conventions.md 2>/dev/null | head -1 || true)"
if [ -n "$CI_DECL" ] || [ -d .github/workflows ]; then
  CI_TO="$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || true)"
  CI_SECS="${OHD_CI_TIMEOUT:-8}"
  # short-timeout wrapper; stock macOS ships no `timeout`, so its absence must
  # degrade to a bare call rather than to a broken row
  ci_gh() { if [ -n "$CI_TO" ]; then "$CI_TO" "$CI_SECS" gh "$@"; else gh "$@"; fi; }
  CI_ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
  CI_FIX="remedy (#31 retirement checklist): \`gh workflow disable <name-or-id>\` per active workflow; UNBIND the leftover required check(s) from branch protection AND/OR rulesets; then sweep the docs that still assume CI. All three are owner actions — this row reports only"
  CI_DECL_TXT="declaration: $(printf '%s' "$CI_DECL" | sed 's/^[[:space:]]*//')"
  if ! command -v gh >/dev/null 2>&1; then
    report "ci-coherence" "MANUAL-CHECK" "gh CLI not installed, so neither the workflow half nor the required-check half could be read — check both by hand before trusting a \`ci: retired\` declaration${CI_DECL:+ (${CI_DECL_TXT})}"
  elif ! printf '%s' "$CI_ORIGIN" | grep -qi 'github\.com'; then
    report "ci-coherence" "MANUAL-CHECK" "origin is not a GitHub remote (${CI_ORIGIN:-no origin}) — this row only knows how to read GitHub; a non-GitHub CI's coherence is yours to check"
  elif ! CI_REPO="$(ci_gh repo view --json nameWithOwner,defaultBranchRef -q '.nameWithOwner + " " + .defaultBranchRef.name' 2>/dev/null)" || [ -z "$CI_REPO" ]; then
    report "ci-coherence" "MANUAL-CHECK" "gh could not read this repository (expired auth, no network, or no access) — \`gh auth status\` first, then re-run; nothing about CI state is claimed here"
  else
    CI_NWO="${CI_REPO%% *}"; CI_BR="${CI_REPO##* }"
    # A default branch may contain '/' (`feat/x`). Unencoded, that slash
    # addresses a DIFFERENT API path and GitHub answers 404 "Branch not found"
    # — which the protection arm below would read as "Branch not protected",
    # i.e. coherent-empty. Such a repo would silently never have its required
    # checks read at all, which is the failure this row exists to catch.
    CI_BR_ENC="$(printf '%s' "$CI_BR" | sed 's|/|%2F|g')"
    # --- half 1: does anything still RUN? ---
    # `gh workflow list` without --all is active-only by construction, which is
    # the fallback's whole safety: an older gh missing --json still answers the
    # only question this half asks.
    if CI_WF_JSON="$(ci_gh workflow list --all --json name,state 2>/dev/null)"; then
      CI_WF_N="$(printf '%s' "$CI_WF_JSON" | grep -o '"state":"active"' | wc -l | tr -d ' ' || true)"
    else
      CI_WF_N="$(ci_gh workflow list 2>/dev/null | grep -c . || true)"
    fi
    [ -n "$CI_WF_N" ] || CI_WF_N=0
    # --- half 2: does anything still BLOCK? ---
    CI_PROT="$(ci_gh api "repos/$CI_NWO/branches/$CI_BR_ENC/protection" 2>&1 || true)"
    CI_PROT_BLIND=0; CI_CHK_N=0; CI_CHK_SRC=""
    case "$CI_PROT" in
      *"Branch not found"*)
        # ALSO a 404, and it must be tested BEFORE the 404 arm: "not found" is
        # a failed read, "not protected" is a successful read of an empty
        # protection set. Collapsing them reports blindness as coherence.
        CI_PROT_BLIND=1 ;;
      *"HTTP 403"*|*'"status":"403"'*)
        CI_PROT_BLIND=1 ;;
      *"HTTP 404"*|*'"status":"404"'*|*"Branch not protected"*)
        : ;;  # measured: the maintainer's normal case — unprotected is coherent-empty
      *)
        # `"contexts":["a","b"]` → count the quoted entries between the brackets
        CI_CTX="$(printf '%s' "$CI_PROT" | sed -n 's/.*"contexts":\[\([^]]*\)\].*/\1/p')"
        if [ -n "$CI_CTX" ]; then
          CI_CHK_N="$(printf '%s' "$CI_CTX" | grep -o '"[^"]*"' | wc -l | tr -d ' ' || true)"
          [ "$CI_CHK_N" = 0 ] || CI_CHK_SRC="branch protection"
        fi ;;
    esac
    # The rulesets half needs the SAME blind flag as the protection half. A
    # timeout kill, a network blip or any non-200 answer yields no body, which
    # is byte-identical to a genuine `[]` — so an unflagged failure reads as
    # "nothing bound" and the row calls a possibly half-retired repo coherent.
    # This is the endpoint that cannot 403, not the endpoint that cannot fail.
    CI_RULES_BLIND=0; CI_RULE_N=0
    if CI_RULES="$(ci_gh api "repos/$CI_NWO/rules/branches/$CI_BR_ENC" 2>/dev/null)" && [ -n "$CI_RULES" ]; then
      CI_RULE_N="$(printf '%s' "$CI_RULES" | grep -o '"context":"[^"]*"' | wc -l | tr -d ' ' || true)"
      [ -n "$CI_RULE_N" ] || CI_RULE_N=0
    else
      CI_RULES_BLIND=1
    fi
    if [ "$CI_RULE_N" != 0 ]; then
      CI_CHK_N=$((CI_CHK_N + CI_RULE_N))
      CI_CHK_SRC="${CI_CHK_SRC:+$CI_CHK_SRC + }rulesets"
    fi
    CI_BLIND=""
    [ "$CI_PROT_BLIND" = 0 ] || CI_BLIND="branch-protection read returned 403 or could not resolve the branch"
    [ "$CI_RULES_BLIND" = 0 ] || CI_BLIND="${CI_BLIND:+$CI_BLIND; }rulesets read FAILED (timeout, network, or a non-200 answer)"
    CI_SEEN="$CI_WF_N active workflow(s), $CI_CHK_N required check(s)${CI_CHK_SRC:+ via $CI_CHK_SRC}"
    [ -z "$CI_BLIND" ] || CI_SEEN="$CI_SEEN; $CI_BLIND — that half is UNREAD"
    if [ -n "$CI_DECL" ] && { [ "$CI_WF_N" != 0 ] || [ "$CI_CHK_N" != 0 ]; }; then
      # WHICH half is left over decides the consequence, so the row says only
      # the true one: an unbound-but-running workflow costs minutes, a bound
      # check with nothing to run it blocks the merge outright. Naming both
      # unconditionally is how a report trains its reader to skim it.
      CI_WHY=""
      [ "$CI_CHK_N" = 0 ] || CI_WHY="$CI_WHY A required check with no run that can turn it green blocks every merge, which is what makes lands reach for --admin."
      [ "$CI_WF_N" = 0 ] || CI_WHY="$CI_WHY An active workflow still runs on every push — the cost half of the retirement, and the half that burns a free tier."
      report "ci-coherence" "DRIFT" "CI is declared retired but $CI_SEEN.$CI_WHY $CI_FIX. $CI_DECL_TXT"
    elif [ -z "$CI_DECL" ] && [ "$CI_WF_N" = 0 ] && [ "$CI_CHK_N" != 0 ]; then
      report "ci-coherence" "DRIFT" "the reverse half-retirement: $CI_SEEN — nothing runs, yet the check still blocks. Either re-enable the workflow or unbind the check; if CI is retired here, declare it (\`- ci: retired (<date> — <reason>)\` in CLAUDE.md or docs/reference/conventions.md) so campaign-land Phase 0 can attest the skip — $CI_FIX"
    elif [ -n "$CI_BLIND" ]; then
      report "ci-coherence" "MANUAL-CHECK" "$CI_SEEN — nothing so far contradicts the project's CI state, but a half was unreadable, so this is NOT a coherence verdict; re-run, read it with a token that can, or check the branch's settings by hand"
    elif [ -n "$CI_DECL" ]; then
      report "ci-coherence" "CONSISTENT" "declared retired and nothing contradicts it: $CI_SEEN. $CI_DECL_TXT"
    elif [ "$CI_WF_N" != 0 ]; then
      report "ci-coherence" "CONSISTENT" "CI is in use and undeclared, which is the ordinary case: $CI_SEEN"
    else
      report "ci-coherence" "CONSISTENT" "$CI_SEEN — a workflows directory exists but nothing runs and nothing blocks. If CI is retired here, DECLARE it (\`- ci: retired (<date> — <reason>)\` in CLAUDE.md or docs/reference/conventions.md): campaign-land Phase 0 reads that line and attests the skip instead of re-deriving the story every land"
    fi
  fi
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
  AL_MARKS="$(grep -o '<!-- *ohd:always-loaded[^>]*-->' CLAUDE.md 2>/dev/null || true)"
  AL_B="$(wc -c < CLAUDE.md)"; AL_N=1; AL_MISS=""
  if [ -n "$AL_MARKS" ]; then
    # EVERY marker, and each one's content read as a PATH rather than word-split.
    # The unquoted expansion this replaces turned `docs/my plan.md` into two
    # nonexistent paths and dropped the file's bytes out of the budget silently,
    # and only the first marker was ever read. One path per marker always
    # parses; the space-separated list still resolves when no path has a space.
    while IFS= read -r mark; do
      [ -n "$mark" ] || continue
      body="$(printf '%s' "$mark" | sed 's/<!-- *ohd:always-loaded//; s/-->$//')"
      body="${body#"${body%%[![:space:]]*}"}"; body="${body%"${body##*[![:space:]]}"}"
      [ -n "$body" ] || continue
      if [ -f "$body" ]; then AL_P=("$body"); else read -r -a AL_P <<< "$body"; fi
      [ "${#AL_P[@]}" -gt 0 ] || continue
      for p in "${AL_P[@]}"; do
        if [ -f "$p" ]; then
          AL_B=$((AL_B + $(wc -c < "$p"))); AL_N=$((AL_N + 1))
        else
          AL_MISS="$AL_MISS$p "
        fi
      done
    done <<< "$AL_MARKS"
    AL_SCOPE="across $AL_N file(s) (CLAUDE.md + the always-loaded marker list)"
  else
    AL_SCOPE="CLAUDE.md only — no \`<!-- ohd:always-loaded <path>... -->\` marker, so a plan/ledger file every worker must read is NOT in this count; add one to budget it"
  fi
  [ -z "$AL_MISS" ] || AL_SCOPE="$AL_SCOPE; marker names path(s) that do not exist: $AL_MISS"
  AL_ST=OK; [ "$AL_B" -le "$HOT_TARGET" ] || AL_ST=OVER
  report "always-loaded" "$AL_ST" "${AL_B}B $AL_SCOPE vs ~20KB hot target"
else
  report "always-loaded" "NONE" "no CLAUDE.md — nothing is always-loaded, so there is no wake mass to budget (see the CLAUDE.md row)"
fi

# ---- reference tier: existence + pointer resolution + dated-claim expiry ----
# A rotted catalog MISDIRECTS, which is worse than no catalog — these two gates
# are what make the tier safe to trust, so they are constitutive, not advisory.
# EVERY backticked path-shaped token in the format law's pointer zone (the tail
# after the FIRST ' — ') is resolved; a prose bullet with no pointer is left
# alone rather than guessed at, and `(example)` scaffold lines are counted,
# never gated.
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
    # `|| [ -n "$line" ]`: a file with no trailing newline hands its LAST line to
    # `read` with a non-zero status, and that line — the one most likely to be
    # freshly appended — went ungated.
    while IFS= read -r line || [ -n "$line" ]; do
      # A placeholder is a TOKEN, not a line shape, so this test runs before the
      # list-item filter: the scaffold's Route map TABLE row is not a list item
      # and went uncounted — and that is the one table whose whole job is to be
      # executable truth. STATED CAVEAT: the scaffold's instruction PROSE also
      # carries `(example)`, so a filled tier reads placeholders>0 until the
      # instruction line itself is deleted. That is correct — deleting the
      # scaffold's instructions when done IS the finish line — and it is said
      # out loud so the total is not read as "rows left to fill".
      case "$line" in *'(example)'*) REF_PH=$((REF_PH + 1)); continue ;; esac
      case "$line" in
        [-*]" "*|"  "[-*]" "*) : ;;
        *) continue ;;
      esac
      case "$line" in
        # `- ci: retired (<date> — <reason>)` is campaign-land's canonical
        # declaration and this tier is one of the two homes it may live in. It
        # is a declaration, not an anchored claim, and a natural reason names
        # the deleted workflow FILE or the command that replaced CI — both
        # path-shaped, neither resolvable. Not redundant with the shape rule
        # below, which the FILE form would sail straight through.
        *'ci: retired'*) : ;;
        *' — '*)
          # The pointer ZONE is the tail after the FIRST ' — ', and EVERY
          # backticked path-shaped token in it is resolved. Tail rather than
          # just-after-the-LAST-separator because companion pointers (a
          # rationale link, a second test) went unchecked one per line — 21 of
          # them across 12 lines in the field, which is how 5 genuinely dead
          # pointers rode through behind a first one that resolved. Zone rather
          # than whole line because naming a REMOVED file is exactly what a
          # gotcha's claim half is for.
          rest="${line#* — }"
          while :; do
            case "$rest" in *'`'*'`'*) : ;; *) break ;; esac
            rest="${rest#*\`}"; p="${rest%%\`*}"; rest="${rest#*\`}"
            # `::node-id` FIRST (pytest's canonical anchor form, and the format
            # law's own encouraged shape), then `:line`, then `#anchor`: all
            # three are parts of the CITATION, not of the path.
            p="${p%%::*}"; p="${p%%:[0-9]*}"; p="${p%%#*}"
            # Only path-shaped tokens are pointers — contains `/`, or ends in
            # an all-alpha dot-extension. Prose ending in a backticked
            # identifier (a skill name, a command, a version string) is not a
            # claim about a file. Fail-open by construction: an extensionless
            # bare name now goes unchecked, the accepted cost of not reporting
            # `uv run pytest` as a rotted doc pointer.
            case "$p" in
              */*) : ;;
              *.*) case "${p##*.}" in ""|*[!a-zA-Z]*) continue ;; esac ;;
              *) continue ;;
            esac
            # Try BOTH resolutions — root-relative (the format law's dominant
            # shape, and the passing majority) and relative to the reference
            # file itself. Adopters write bare names and `../` shapes, which
            # resolved dead under root-only. Strictly permissive on purpose:
            # pure dir-relative would break every currently-passing pointer.
            [ -e "$p" ] || [ -e "$(dirname "$f")/$p" ] \
              || REF_DEAD="$REF_DEAD$p "
          done ;;
      esac
      if [ "$IS_STATE" = 1 ] && [ -n "$REF_CUT" ]; then
        for d in $(printf '%s' "$line" | grep -o 'as of [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' | sed 's/as of //' || true); do
          [ "$d" \< "$REF_CUT" ] && REF_OLD="$REF_OLD$d "
        done
      fi
    done < "$f"
  done
  REF_PH_TXT="$REF_PH placeholder line(s) still to replace"
  if [ "$REF_N" = 0 ]; then
    # an empty tier used to report exactly like a filled one
    report "reference" "STALE" "0 file(s) — the directory exists but is EMPTY, which is not the same as healthy; scaffold it from the plugin's assets/home-set/reference/ (\`/ohd-checkup structure\` offers this) or remove the directory"
  elif [ -n "$REF_DEAD$REF_OLD" ]; then
    D=""
    [ -z "$REF_DEAD" ] || D="dead pointer(s): $REF_DEAD"
    [ -z "$REF_OLD" ] || D="${D}${D:+; }state.md dated claim(s) older than 14 days: $REF_OLD"
    report "reference" "STALE" "$D — refresh the line or delete it; a reference line nobody can re-run is the misdirection this tier exists to prevent ($REF_N file(s), $REF_PH_TXT)"
  else
    NOTE=""; [ -n "$REF_CUT" ] || NOTE=" (date arithmetic unavailable — dated-claim expiry NOT checked)"
    report "reference" "OK" "$REF_N file(s), pointers resolve, no state.md claim older than 14 days, $REF_PH_TXT$NOTE"
  fi
fi

# ---- "this doc records a TERMINAL verdict" — one rule, three consumers -------
# (the false-OPEN census, the structure summary, and the solidation list). Each
# used a hardcoded strict `result / verdict` literal, which field measurement
# found wrong in BOTH directions: it MISSED decorated, translated and
# `status: LANDED` verdict rows — the census read 0 on a corpus full of them —
# and it COUNTED placeholder and PENDING text as a filled verdict.
# The shape is the land-report audit's rule below (same marker/checkbox/label
# tolerance, and its comment carries the full reasoning), ANCHORED on a terminal
# verdict word. That anchor is the part that cannot be dropped: the audit's rule
# reused verbatim still counts every placeholder row, because its verdict-label
# branch accepts ANY non-space value — both `*(fill in after the gate)*` and
# `PENDING the GPU gate` match it, verified. The audit keeps that tolerance on
# purpose (it over-reports, and its output is a prompt to go look); these three
# rows drive batch-closing and archiving, where a false positive costs more.
#
# TWO branches, because the label case and the bare case need OPPOSITE case
# rules — one regex could not do both:
#
# LABELLED, case-insensitive. The label is a WHITELIST, not "any word ending in
# a colon": a verdict word is also an ordinary English word, so a generic label
# admitted `- plan: LANDS eventually if the gate goes green` and archived a live
# campaign (reproduced). `[^:]*` after the whitelist word is what carries the
# scaffold's own `result / verdict:` compound. After the colon the class is
# `[*_\`[:space:]]*`, NOT `[[:space:]]*`: in `- **verdict:** LANDS` the closing
# `**` sits between the colon and the verdict word, and skipping only spaces
# stopped dead on the whole colon-inside-emphasis family — which the audit rule
# below accepts, so the shared rule was stricter than the rule it mirrors.
#
# BARE, case-SENSITIVE and deliberately so. With no label to key on, the only
# thing separating a verdict from prose is that a verdict row SHOUTS it:
# `- LANDED as PR #7` is a verdict, `- Aborted runs are retried by the
# scheduler` is a sentence, and case is the whole difference. The trailing
# `([^:]|$)` drops `- landed: no`, where the word is its own label.
VERDICT_LABEL_RE='^[[:space:]]*[-*][[:space:]]+(\[[xX]\][[:space:]]*)?[*_`]*(status|verdict|result|outcome|결론|결과)[^:]*:[*_`[:space:]]*(LANDS|LANDED|ABANDONED|ABORTED)\b'
VERDICT_BARE_RE='^[[:space:]]*[-*][[:space:]]+(\[[xX]\][[:space:]]*)?[*_`]*(LANDS|LANDED|ABANDONED|ABORTED)\b([^:]|$)'
has_verdict() {
  grep -qiE "$VERDICT_LABEL_RE" "$1" 2>/dev/null || grep -qE "$VERDICT_BARE_RE" "$1" 2>/dev/null
}

# "this doc carries a land-report artifact" — used by the land-reports gap
# test, which asks for its ABSENCE. Single consumer: the ritual-bypass
# sub-count used to call it too, but that row now scopes on the scaffold
# marker instead, since a land-report artifact says nothing about which era
# wrote it. The TABLE test stays deliberately LOOSE here, unlike campaign.sh's
# gate: tightening it to the full scaffold header was measured to false-flag
# genuine hand-written reports whose tables use other columns.
has_land_report() {
  grep -qiE '^[[:space:]]*\|[[:space:]]*phase[[:space:]]*\|' "$1" 2>/dev/null \
    || grep -qiE '^##[[:space:]]*([0-9]+\.?[[:space:]]*)?land[- ]report' "$1" 2>/dev/null
}

# Print a doc's LAND-REPORT REGION: from the scaffold marker (or, absent one,
# the land-report heading) to the next '## ' heading. Content checks read this
# rather than the whole file — a `sanity:` sitting in unrelated prose elsewhere
# in a long state doc must not satisfy the land report's own contract.
land_report_region() {
  awk '
    {
      low = tolower($0)
      isLR = (low ~ /^##[ \t]*([0-9]+\.?[ \t]*)?land[- ]report/)
      if (!inr) {
        if (index($0, "ohd:land-report-scaffold") > 0 || isLR) { inr = 1; started = NR }
      } else if (low ~ /^##[ \t]/ && NR > started && !isLR) {
        exit
      }
      if (inr) print
    }
  ' "$1" 2>/dev/null
}

# Solidation candidates — one path per line: a state doc whose verdict is filled
# and which is not yet under docs/archive/. ONE rule for its two consumers (the
# default row counts them, --structure lists them with sizes), so the SOLIDATION
# TERM of the count and the list cannot disagree. The row is not that term
# alone — it adds a reference-tier candidate when docs/reference/ is absent, so
# the number a project sees may legitimately exceed the list by one.
# NOT the census above, which counts archived docs too. The archive skip below
# is DEFENSIVE and normally dead: "$SD"/*.md does not recurse, so it can only
# fire when STATE_DIR is itself docs/archive or a directory under it.
sol_candidates() {
  local d
  [ -d "$SD" ] || return 0
  for d in "$SD"/*.md; do
    [ -f "$d" ] || continue
    case "$d" in docs/archive/*) continue ;; esac
    has_verdict "$d" && printf '%s\n' "$d"
  done
  # explicit: under `set -e` a last file WITHOUT a verdict would otherwise make
  # this function's status non-zero and abort every caller that pipes it
  return 0
}

# ---- campaign census: OPEN status vs filled verdict (the false-OPEN term) ---
if [ -d "$SD" ]; then
  C_TOT=0; C_OPEN=0; C_FALSE=0
  for d in "$SD"/*.md; do
    [ -f "$d" ] || continue
    C_TOT=$((C_TOT + 1))
    grep -qiE '^[[:space:]]*[-*][[:space:]]+[*_`]*status[*_`]*:[[:space:]]*[*_`]*OPEN' "$d" 2>/dev/null || continue
    C_OPEN=$((C_OPEN + 1))
    has_verdict "$d" && C_FALSE=$((C_FALSE + 1))
  done
  report "campaigns" "$C_OPEN open/$C_TOT total, $C_FALSE false-OPEN" "false-OPEN = the doc still says \`status: OPEN\` while its verdict row records a terminal outcome; grep archaeology reads those as in-flight work — fix: flip \`status: OPEN\` to the verdict state in the same edit that fills the verdict (campaign-land Phase 4)"
fi

# ---- structure: ONE summary line. A count is a POINTER, not an audit — the
#      default run never nags a project into structural work. -----------------
ST_CAND="$(sol_candidates | wc -l | tr -d ' ')"
[ -d "$REFD" ] || ST_CAND=$((ST_CAND + 1))
report "structure" "$ST_CAND candidates" "last full audit: no record (the structure report is output-only, so nothing here is stamped) — run /ohd-checkup structure for the work-list"

# ---- land-report audit (behavioral fossils: landed without the ritual?) ----
if [ -d "$SD" ]; then
  GAPS=""; BYP=""; BYP_N=0; BYP_TOT=0
  for d in "$SD"/*.md; do
    [ -f "$d" ] || continue
    # Ritual-bypass sub-count runs FIRST and is scoped by its OWN marker, NOT
    # by the land-reports row's post-scaffold exclusion below. Nesting it there
    # would let a hand-rolled bypass escape the count by deleting the dated
    # status line — the one edit a bypasser is most likely to make.
    # Scoped by an EXPLICIT scaffold marker, because the named-cell TOKENS
    # cannot mark an era: `reference:` and `verification:` have been MANDATED
    # ritual vocabulary since v0.6.0, so a pre-scaffold report legitimately
    # contains them. Both genuine reports in the plugin's own repo do, written
    # four days before the scaffold existed — token-based scoping counted them
    # as scaffold-born no matter where the anchor sat, which is why anchor
    # position was never the fix. Only a v0.7.0+ `--report` run emits the
    # comment marker, so it is the one thing a report the scaffold did not
    # write cannot contain.
    # ACCEPTED TRADE, disclosed in the row text: scoping on a line the author
    # can delete means deleting it removes the report from BOTH the count and
    # the named list, while the land gate still passes — measured, `1 of 2`
    # becomes `OK | 1`. This row is MARKER-scoped, not ritual-scoped, and says
    # so. The era boundary is real and nothing weaker draws it, so the trade is
    # taken rather than hidden; C1's honesty precedent is that a detector
    # states what it cannot see.
    if grep -qF 'ohd:land-report-scaffold' "$d" 2>/dev/null; then
      BYP_TOT=$((BYP_TOT + 1))
      REGION="$(land_report_region "$d")"
      # Content checks read the REGION, not the file: a `sanity:` in unrelated
      # prose elsewhere in the doc must not attest this land report.
      # The BARE-PROMPT test stays cell-initial on purpose — an unfilled
      # scaffold prompt is cell-initial by construction, so that is the one
      # place the tighter shape is the correct one.
      if printf '%s\n' "$REGION" | grep -qE '^[[:space:]]*\|.*\|[[:space:]]*(reference|verification):[[:space:]]*(\|[[:space:]]*)?$' \
         || ! printf '%s\n' "$REGION" | grep -q 'sanity:'; then
        BYP_N=$((BYP_N + 1)); BYP="$BYP$(basename "$d") "
      fi
    fi
    # The land-reports row SCOPES to the post-scaffold era: 'campaign.sh new'
    # writes a '- status: <state> (YYYY-MM-DD)' line, so a doc without one
    # predates the scaffold and is excluded BY INTENT (#21 §6 asked for exactly
    # this narrowing). That line is the one on-disk date that is neither mtime
    # nor git-derived, which is why it is the scoping key rather than a date
    # the audit would have to derive. HONEST HALF: this removes pre-ritual
    # history only — the never-landed lexical misclassification below is
    # unaffected and stays (backlog #11's accepted trade).
    grep -qiE '^[[:space:]]*-[[:space:]]*status:.*\([0-9]{4}-[0-9]{2}-[0-9]{2}\)' "$d" 2>/dev/null || continue
    # The VERDICT test below is deliberately NOT campaign.sh clean's rule, and
    # the scoping line above does not change that. Their inputs differ: 'clean'
    # only sees campaigns 'campaign.sh new' opened, so it can anchor on the
    # literal '- result / verdict:' scaffold row, and it does. This audit reads
    # LEGACY docs, of which only 84 of 365 carry that row — so anchoring the
    # VERDICT on a scaffold row would silently skip 77% of the docs the audit
    # exists to read. (The status-line scoping above is the opposite move and
    # is safe for the same reason: it SUBTRACTS docs that predate the ritual
    # rather than deciding which verdicts count.) The verdict test stays
    # TOLERANT instead:
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
       && ! has_land_report "$d"; then
      GAPS="$GAPS$(basename "$d") "
    fi
  done
  if [ -n "$GAPS" ]; then
    report "land-reports" "GAPS" "landed state doc(s) without a land-report table: ${GAPS}— lands that skipped the ritual; backfill honestly or annotate (see campaign-land). SCOPE CHANGED in v0.7.0: only docs carrying the scaffold's \`- status: … (date)\` line are audited, so pre-scaffold docs are excluded and this row no longer sees them (spec E5 honest-half — it removes pre-ritual history only; the never-landed lexical misclassification is unchanged). Any landing date you backfill comes from the PR's MERGE date — never \`git log -1 -- <doc>\`, which reports when the file was last touched and is skewed by every back-fill and later edit"
  else
    report "land-reports" "OK" "every landed state doc carries its land-report table"
  fi
  if [ "$BYP_N" -gt 0 ]; then
    report "ritual-bypass" "$BYP_N of $BYP_TOT" "scaffold-written land report(s) leaving a named cell at its bare prompt or carrying no \`sanity:\` in the land-report section: ${BYP}— ADVISORY, not a gate: those cells are what campaign-land Phase 4/6 attest, and a prompt with nothing after it reads as silent rather than attested. The denominator counts reports carrying the \`ohd:land-report-scaffold\` marker — it is MARKER-scoped, not ritual-scoped. Two honest false negatives: a bypasser who fills the cells with plausible text reads clean, and one who DELETES the marker line drops out of this row entirely while still passing the land gate"
  elif [ "$BYP_TOT" -gt 0 ]; then
    report "ritual-bypass" "OK" "$BYP_TOT scaffold-written land report(s) (those carrying the \`ohd:land-report-scaffold\` marker), every named cell filled — MARKER-scoped, not ritual-scoped: a report whose marker line was deleted is not counted here at all, and still passes the land gate"
  else
    report "ritual-bypass" "0 scaffolded" "no land report here carries the \`ohd:land-report-scaffold\` marker, so this row has nothing to audit yet — SILENT BY SCOPE, not a health claim. The marker is explicit because the named cells cannot date a report: \`reference:\`/\`verification:\` are mandated ritual vocabulary from v0.6.0, so pre-scaffold reports legitimately carry them. Reports written before v0.7.0, by a fork, or by a stale plugin are excluded by construction"
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
  while IFS= read -r d; do
    SOL_N=$((SOL_N + 1)); SOL="$SOL  $d ($(wc -c < "$d" | tr -d ' ')B)
"
  done < <(sol_candidates)
  echo "## solidation — $SOL_N candidate(s): verdict filled, not yet under docs/archive/"
  [ -z "$SOL" ] || printf '%s' "$SOL"
  echo "   Move at CHECKUP or MILESTONE time, NEVER per land (the fixed-tax rule)."
  echo "   Leave the literal search key behind: \`~~old claim~~ → archive/<file>.md\`."
  echo ""

  # 2. orphan-verification census -------------------------------------------
  TF="$(mktemp)"; git ls-files -z > "$TF" 2>/dev/null || : > "$TF"
  ALLOWF=".ohd-orphan-allowlist"
  # the separator is OPTIONAL: requiring one made the commonest real form —
  # a bare `check.sh` / `verify.py` — match nothing at all
  VER_RE='(^|/)((test|check|verify|probe|bench|assert|validate|sanity|smoke|measure|audit)([-_.][^/]*)?|[^/]*[-_](test|check|verify|probe|bench|assert|validate|sanity|smoke))\.(sh|bash|py|mjs|js)$'
  ORPH=""; ORPH_N=0; ALLOW_N=0; CAND_N=0
  while IFS= read -r -d '' f; do
    case "$f" in bench/*|tools/*|scripts/*) : ;; *) continue ;; esac
    printf '%s' "$f" | grep -qE "$VER_RE" || continue
    CAND_N=$((CAND_N + 1))
    if [ -f "$ALLOWF" ] && grep -qxF "$f" "$ALLOWF" 2>/dev/null; then
      ALLOW_N=$((ALLOW_N + 1)); continue
    fi
    base="${f##*/}"
    # word-boundary-ish, not a raw substring: `recheck_gate.py` CONTAINS
    # `check_gate.py`, and that collision reported a genuine orphan as referenced
    BRE="$(printf '%s' "$base" | sed 's/[^[:alnum:]_-]/\\&/g')"
    hit="$(xargs -0 grep -lE -- "(^|[^[:alnum:]_])$BRE([^[:alnum:]_]|\$)" < "$TF" 2>/dev/null | grep -vxF "$f" | head -1 || true)"
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
  echo "   HONEST CROSS-REFERENCE: that exclusion is safe only while the runner"
  echo "   really does discover the directory. A colocated test dir it does NOT"
  echo "   collect looks discovered and is invisible here — the runner-scope row"
  echo "   below is the check for that, and this census cannot answer it."
  echo ""

  # 2b. runner scope: tracked tests the configured runner never collects -----
  # Distinct question from the census above ("does anything reference this
  # file"): this one compares the RUNNER's configured scope against tracked
  # test files, and is answerable exit-code-shaped. Field witness: 8 tests over
  # two adopted modules had never been collected while `pytest` reported green,
  # because `testpaths` named a sibling directory. `testpaths` ONLY —
  # norecursedirs is a different parser class with no field witness yet.
  # bash+awk by construction: checkup has no python3 dependency and does not
  # acquire one for a report row.
  RS_F=""; RS_TP=""
  for c in pytest.ini pyproject.toml tox.ini setup.cfg; do
    [ -f "$c" ] || continue
    case "$c" in
      pyproject.toml) sec="[tool.pytest.ini_options]" ;;
      setup.cfg)      sec="[tool:pytest]" ;;
      *)              sec="[pytest]" ;;
    esac
    # section-SCOPED: a `testpaths` key under some other tool's table is not
    # pytest's. Handles ini `a b` lists and toml `["a", "b"]` including the
    # simple multiline array form.
    RS_TP="$(awk -v sec="$sec" -v Q="'" '
      { l=$0; sub(/[[:space:]]*[#;].*$/, "", l)
        t=l; sub(/^[[:space:]]+/, "", t); sub(/[[:space:]]+$/, "", t)
        if (open) { val = val " " t; if (t ~ /\]/) open=0; next }
        if (t ~ /^\[/) { insec = (t == sec); if (insec) sawsec=1; next }
        if (insec && t ~ /^testpaths[[:space:]]*=/) {
          found=1; v=t; sub(/^testpaths[[:space:]]*=[[:space:]]*/, "", v)
          if (v ~ /\[/ && v !~ /\]/) { open=1; val=v; next }
          val=v } }
      END { if (!sawsec) { print "NOSEC"; exit }
            if (!found)  { print "NOKEY"; exit }
            gsub(/[][",]/, " ", val); gsub(Q, " ", val)
            n=split(val, a, /[[:space:]]+/); out=""
            for (i = 1; i <= n; i++) if (a[i] != "") out = out a[i] "\n"
            if (out == "") { print "EMPTY"; exit }
            printf "%s", out }' "$c" 2>/dev/null || echo NOSEC)"
    case "$RS_TP" in
      # pytest.ini IS the config file even with no `[pytest]` section; for the
      # other three the section is what makes the file pytest's config at all,
      # so an absent one means keep looking.
      NOSEC) if [ "$c" != pytest.ini ]; then RS_TP=""; continue; fi
             RS_TP=NOKEY ;;
      "")    RS_TP=NOKEY ;;
    esac
    RS_F="$c"; break
  done
  if [ -n "$RS_F" ] && [ "$RS_TP" = EMPTY ]; then
    echo "## runner scope — MANUAL-CHECK"
    echo "  \`$RS_F\` declares \`testpaths\` but nothing literal could be extracted"
    echo "  from it. Read the key by hand and compare it against the tracked test"
    echo "  files: a parser that guesses here would print a confident wrong answer,"
    echo "  which is the exact failure this row exists to end."
    echo ""
  elif [ -n "$RS_F" ] && [ "$RS_TP" != NOKEY ]; then
    # collected into an ARRAY, not a `a|b` case pattern: `|` arrives after
    # expansion, and a case pattern's alternation is parsed before it — the
    # pattern would match one literal string containing a pipe.
    RS_A=(); RS_ALL=0
    while IFS= read -r tp; do
      [ -n "$tp" ] || continue
      tp="${tp%/}"
      if [ "$tp" = "." ] || [ -z "$tp" ]; then RS_ALL=1; break; fi
      RS_A[${#RS_A[@]}]="$tp"
    done <<RSTP
$RS_TP
RSTP
    RS_OUT=""; RS_N=0; RS_TOT=0
    while IFS= read -r t; do
      case "$t" in test_*.py|*_test.py|*/test_*.py|*/*_test.py) : ;; *) continue ;; esac
      RS_TOT=$((RS_TOT + 1))
      [ "$RS_ALL" = 0 ] || continue
      RS_IN=0
      for tp in "${RS_A[@]}"; do
        case "$t" in "$tp"/*|"$tp") RS_IN=1; break ;; esac
      done
      [ "$RS_IN" = 0 ] || continue
      RS_N=$((RS_N + 1)); RS_OUT="$RS_OUT  $t
"
    done <<RSFILES
$(git ls-files 2>/dev/null || true)
RSFILES
    echo "## runner scope — $RS_N of $RS_TOT tracked pytest-collectible file(s) outside \`testpaths\` ($RS_F)"
    [ -z "$RS_OUT" ] || printf '%s' "$RS_OUT"
    echo "   A file listed here is not a failing test — it is a test the configured"
    echo "   runner never collects, so it reads green by never running. Widen"
    echo "   testpaths or move the file. Candidates are pytest-COLLECTIBLE names"
    echo "   only (test_*.py / *_test.py), never the census's verification-family"
    echo "   regex above: \"this shell check is outside pytest scope\" is a nonsense"
    echo "   finding. SILENT BY DESIGN when no pytest config declares testpaths —"
    echo "   pytest then collects rootdir-wide and everything is in scope."
    echo ""
  fi

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

  # 5. state-claim staleness: re-verify candidates --------------------------
  # Reference integrity is gated; claim CURRENCY is not gated anywhere, so a
  # doc can be arbitrarily wrong about the state of the world and stay green
  # indefinitely. Deliberately NO dating: mtime and git-log dating both
  # re-import the back-fill skew the land-reports remedy warns about, and the
  # human reading the list judges staleness better than either.
  echo "## state-claim staleness — re-verify candidates"
  SC=""; SC_N=0
  if [ -n "$TRACKED_DOCS" ]; then
    while IFS= read -r g; do
      [ -f "$g" ] || continue
      case "$g" in "$REFD"/*) continue ;; esac
      while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        SC_N=$((SC_N + 1)); SC="$SC  $g:$hit
"
      done < <(grep -nE 'NOT landed|LAND owed|pending|TODO' "$g" 2>/dev/null || true)
    done <<< "$TRACKED_DOCS"
  fi
  echo "  $SC_N line(s) asserting state, outside the reference tier"
  [ -z "$SC" ] || printf '%s' "$SC"
  echo "   Each is a CANDIDATE to re-verify, never a defect on its own: a gate can"
  echo "   check that a path resolves, never that a claim is still true. One stale"
  echo "   \"NOT landed (LAND owed)\" line made three dead branches look like a live"
  echo "   blocker and cost a full triage campaign to disprove."
  echo "   Kin: campaign-land's verify-on-read rule and the false-OPEN census"
  echo "   already cover the state-DOC half of this class."
  echo ""

  # 6. baselines for the re-count -------------------------------------------
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
  echo "## before you commit the executed work-list"
  echo "  The executed list is a DELIVERABLE, not bookkeeping: run"
  echo "  review-to-convergence on it before committing. A docs-only cleanup on a"
  echo "  docs-only trunk never reaches campaign.sh's land die-gate, so this is the"
  echo "  only review it gets — and a field run confirmed the error mass is real."
  echo ""
fi

printf -- '— scope: state alignment + land-report presence only (this script). Plugin presence is /ohd-checkup'"'"'s dependency pass (list owned by /ohd-setup §1); per-land ritual compliance is enforced per-land by the land gates (campaign-land). A green table attests none of: code correctness, discipline compliance.\n'
