#!/usr/bin/env bash
# campaign.sh — worktree campaign lifecycle (oppenheimerdinger template)
# Drop-in: fill the config block per docs/campaign-dropin.md, copy to tools/campaign.sh.
# instantiated 2026-07-14 for oppenheimerdinger: all defaults, hook skipped
set -euo pipefail

# ── config (drop-in interview fills these; CAMPAIGN_* env vars override) ──
TRUNK="${CAMPAIGN_TRUNK:-main}"
WT_ROOT="${CAMPAIGN_WT_ROOT:-$HOME/wt}"
NAMING="${CAMPAIGN_NAMING:-free}"                    # free | numbered (NNN-slug)
MERGE_MODEL="${CAMPAIGN_MERGE_MODEL:-coordinator}"   # coordinator | review-gate
STATE_DIR="${CAMPAIGN_STATE_DIR:-docs/campaigns}"
DEP_DIR="${CAMPAIGN_DEP_DIR:-}"       # local clone of a dependent/fork repo ("" = none)
DEP_TRUNK="${CAMPAIGN_DEP_TRUNK:-}"   # dependent repo's trunk branch
PIN_FILE="${CAMPAIGN_PIN_FILE:-}"     # file in THIS repo carrying a PIN=<sha> line
# ──────────────────────────────────────────────────────────────────────────

die() { echo "campaign.sh: $*" >&2; exit 1; }

usage() {
  cat <<USG
usage: campaign.sh <new|land|status|list|clean|abort${DEP_DIR:+|pin}> [name] [flags]
  new <name>              worktree + branch off origin/$TRUNK + state doc scaffold
  land <name>             push + PR toward $TRUNK (merge model: $MERGE_MODEL)
  status <name>           merge verdict from git refs + PR API — never from memory
  list                    open campaign worktrees (staleness guard)
  clean <name>            teardown after VERIFIED merge (refuses otherwise)
  abort <name> [--purge]  discard worktree; keeps remote branch unless --purge
USG
  [ -n "$DEP_DIR" ] && echo "  pin <name>              bump $PIN_FILE to the merged dep-trunk SHA"
  exit 1
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repo"
cd "$ROOT"

check_name() {
  local n="${1:-}"
  [ -n "$n" ] || usage
  if [ "$NAMING" = numbered ]; then
    [[ "$n" =~ ^[0-9]{3}-[a-z0-9-]+$ ]] || die "NAMING=numbered requires NNN-slug (got '$n')"
  else
    [[ "$n" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "bad campaign name '$n'"
  fi
}

wt_path() { echo "$WT_ROOT/$1"; }

cmd_new() {
  local n="$1"; check_name "$n"
  local wt; wt="$(wt_path "$n")"
  [ -e "$wt" ] && die "$wt already exists"
  git fetch origin -q
  mkdir -p "$WT_ROOT" "$STATE_DIR"
  git worktree add "$wt" -b "$n" "origin/$TRUNK"
  local doc="$STATE_DIR/$n.md"
  if [ ! -f "$doc" ]; then
    cat > "$doc" <<DOC
# campaign: $n
- goal:
- status: OPEN ($(date +%F))
- validation gate:
- result / verdict:
- follow-on:
DOC
    echo "state doc: $doc  (commit it on trunk — docs are allowed there)"
  fi
  echo "worktree: $wt  (branch '$n' off origin/$TRUNK)"
  echo "work INSIDE the worktree, commit only there; run 'campaign.sh land $n' when validated."
}

cmd_land() {
  local n="$1"; check_name "$n"
  local wt; wt="$(wt_path "$n")"
  [ -d "$wt" ] || die "no worktree at $wt"
  echo "land gates (see the campaign-land skill): validation green? code review run? state doc updated?"
  git -C "$wt" push -u origin "$n"
  if command -v gh >/dev/null 2>&1; then
    gh pr create --base "$TRUNK" --head "$n" --fill 2>/dev/null \
      || echo "(PR create failed or already exists — check: gh pr list --head $n)"
  else
    echo "gh not found — open the PR manually: base=$TRUNK head=$n"
  fi
  if [ "$MERGE_MODEL" = review-gate ]; then
    echo "review-gate model: STOP HERE — merge happens on GitHub after review."
  else
    echo "coordinator model: merge order = ${DEP_DIR:+dep PR → pin → }this PR → clean."
    echo "verify with 'campaign.sh status $n' after merging."
  fi
}

# Verdict rule (campaign-status skill): MERGED = ancestry MERGED OR a MERGED PR exists.
cmd_status() {
  local n="$1"; check_name "$n"
  git fetch origin -q --prune
  if ! git rev-parse -q --verify "origin/$n" >/dev/null; then
    echo "NO-BRANCH: origin/$n absent (cleaned after merge, or never pushed)"; return 0
  fi
  if git merge-base --is-ancestor "origin/$n" "origin/$TRUNK"; then
    echo "MERGED (ancestry): origin/$n is an ancestor of origin/$TRUNK"; return 0
  fi
  if command -v gh >/dev/null 2>&1; then
    local prs
    prs="$(gh pr list --head "$n" --state all --json number,state,mergedAt,baseRefName 2>/dev/null || echo '[]')"
    if echo "$prs" | grep -q '"state":"MERGED"'; then
      if echo "$prs" | grep -q "\"baseRefName\":\"$TRUNK\""; then
        echo "MERGED (via PR — squash/merge-commit; non-ancestry is NORMAL for squash)"
      else
        echo "STACKED?: MERGED PR exists but its base ≠ $TRUNK — content may not be on trunk."
        echo "prove content reach: git show origin/$TRUNK:<file> | grep <token-unique-to-this-diff>"
      fi
      return 0
    fi
    echo "UNMERGED: not an ancestor and no MERGED PR (PRs: $prs)"
  else
    echo "UNVERIFIED: not an ancestor by git, and gh is unavailable so a squash-merge"
    echo "cannot be ruled out. Do NOT treat as UNMERGED without checking the PR page."
  fi
}

cmd_list() {
  git fetch origin -q --prune 2>/dev/null || true
  git worktree list --porcelain | awk '/^worktree /{w=$2} /^branch /{print w, $2}' | \
  while read -r wt br; do
    br="${br#refs/heads/}"
    [ "$wt" = "$ROOT" ] && continue
    last="$(git -C "$wt" log -1 --format=%cr 2>/dev/null || echo '?')"
    ab="$(git rev-list --left-right --count "origin/$TRUNK...$br" 2>/dev/null | tr '\t' '/' || echo '?')"
    echo "$br  @ $wt  last: $last  behind/ahead: $ab"
  done
}

teardown() {
  local n="$1" del_remote="$2"
  local wt; wt="$(wt_path "$n")"
  git worktree remove --force "$wt" 2>/dev/null || true
  git branch -D "$n" 2>/dev/null || true
  if [ "$del_remote" = yes ]; then git push origin --delete "$n" 2>/dev/null || true; fi
  git worktree prune
  rmdir "$WT_ROOT" 2>/dev/null || true
}

cmd_clean() {
  local n="$1"; check_name "$n"
  git fetch origin -q --prune
  if git rev-parse -q --verify "origin/$n" >/dev/null; then
    if ! git merge-base --is-ancestor "origin/$n" "origin/$TRUNK"; then
      if command -v gh >/dev/null 2>&1 \
         && gh pr list --head "$n" --state merged --json number 2>/dev/null | grep -q '"number"'; then
        :  # merged via squash — verified through the PR API
      else
        die "refusing clean: '$n' is not verifiably merged (run 'campaign.sh status $n'; use abort to discard)"
      fi
    fi
  fi
  teardown "$n" yes
  echo "cleaned $n (worktree + local & remote branch)"
}

cmd_abort() {
  local n="$1"; check_name "$n"; local purge="${2:-}"
  local del=no; [ "$purge" = --purge ] && del=yes
  teardown "$n" "$del"
  echo "aborted $n (remote branch: $([ "$del" = yes ] && echo purged || echo kept))"
}

cmd_pin() {
  [ -n "$DEP_DIR" ] && [ -n "$DEP_TRUNK" ] && [ -n "$PIN_FILE" ] \
    || die "pin requires CAMPAIGN_DEP_DIR / CAMPAIGN_DEP_TRUNK / CAMPAIGN_PIN_FILE"
  local n="$1"; check_name "$n"
  git -C "$DEP_DIR" fetch origin -q
  git -C "$DEP_DIR" merge-base --is-ancestor "origin/$n" "origin/$DEP_TRUNK" \
    || die "'$n' is not merged into dep trunk '$DEP_TRUNK' yet — merge the dep PR first"
  local sha; sha="$(git -C "$DEP_DIR" rev-parse "origin/$DEP_TRUNK")"
  sed -i "s/^PIN=.*/PIN=$sha/" "$PIN_FILE"
  git add "$PIN_FILE"
  git commit --no-verify -m "pin: $PIN_FILE -> $sha ($n)"
  git push origin HEAD
  echo "pinned $sha"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  new)    cmd_new    "${1:-}" ;;
  land)   cmd_land   "${1:-}" ;;
  status) cmd_status "${1:-}" ;;
  list)   cmd_list ;;
  clean)  cmd_clean  "${1:-}" ;;
  abort)  cmd_abort  "${1:-}" "${2:-}" ;;
  pin)    cmd_pin    "${1:-}" ;;
  *)      usage ;;
esac
