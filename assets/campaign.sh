#!/usr/bin/env bash
# campaign.sh — worktree campaign lifecycle (ohd template)
# Drop-in: fill the config block per docs/campaign-dropin.md, copy to tools/campaign.sh.
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
WORKTREE_HINT="${CAMPAIGN_WORKTREE_HINT:-}"  # optional; printed by 'new' with {wt} → worktree path (e.g. how to run tests there)
# ──────────────────────────────────────────────────────────────────────────

die() { echo "campaign.sh: $*" >&2; exit 1; }

usage() {
  cat <<USG
usage: campaign.sh <new|land|status|list|clean|abort${DEP_DIR:+|pin}> [name] [flags]
  new <name>              worktree + branch off origin/$TRUNK + state doc scaffold
  land <name> [--report]  push + PR toward $TRUNK (merge model: $MERGE_MODEL); requires a
                          land-report in the state doc (--report appends the blank table)
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

# pr_merged_tip <name> <tip-sha> — true iff a MERGED PR into TRUNK exists whose head
# commit == <tip-sha>. The headRefOid match is load-bearing: it stops a stale
# same-name merged PR from green-lighting a genuinely-unmerged reused branch, and it
# is how squash/rebase merges (which break ancestry) get recognized as merged at all.
pr_merged_tip() {
  local nm="$1" tip="$2"
  command -v gh >/dev/null 2>&1 || return 1
  gh pr list --head "$nm" --state merged --json number,baseRefName,headRefOid 2>/dev/null \
    | grep -o '{[^}]*}' \
    | grep -F "\"baseRefName\":\"$TRUNK\"" \
    | grep -qF "\"headRefOid\":\"$tip\""
}

cmd_new() {
  local n="$1"; check_name "$n"
  local wt; wt="$(wt_path "$n")"
  [ -e "$wt" ] && die "$wt already exists"
  git fetch origin -q
  mkdir -p "$WT_ROOT" "$STATE_DIR"
  git worktree add "$wt" -b "$n" "origin/$TRUNK"
  # git worktree add does NOT populate submodules — an uninitialized submodule
  # worktree fails tests in ways that masquerade as pre-existing failures.
  if [ "${CAMPAIGN_INIT_SUBMODULES:-1}" != "0" ] && [ -f "$ROOT/.gitmodules" ]; then
    echo "init submodules in worktree (set CAMPAIGN_INIT_SUBMODULES=0 to skip)…"
    git -C "$wt" submodule update --init --recursive || \
      echo "WARN: submodule init failed — run 'git -C $wt submodule update --init --recursive' manually" >&2
  fi
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
  [ -n "$WORKTREE_HINT" ] && echo "${WORKTREE_HINT//\{wt\}/$wt}"
  echo "work INSIDE the worktree, commit only there; run 'campaign.sh land $n' when validated."
}

cmd_land() {
  local n="$1"; check_name "$n"
  local wt; wt="$(wt_path "$n")"
  [ -d "$wt" ] || die "no worktree at $wt"
  local doc="$STATE_DIR/$n.md"
  # --report: append the blank land-report table to the state doc and stop —
  # the artifact the gate below requires, scaffolded so filling it is the
  # only remaining work.
  if [ "${2:-}" = "--report" ]; then
    [ -f "$doc" ] || die "no state doc at $doc (run 'campaign.sh new' first?)"
    grep -qi '| phase |' "$doc" && die "$doc already has a land-report table"
    cat >> "$doc" <<'TBL'

## land report
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | | |
| 1 working-tree safety| | |
| 2 re-validation      | | |
| 2.5 reachability     | | |
| 3 quality gate       | | |
| 4 docs same-land     | | |
| 5 merge mechanics    | | |
| 6 distill + hygiene  | | |
TBL
    echo "appended land-report table to $doc — fill it per the campaign-land skill, then run 'campaign.sh land $n'"
    return 0
  fi
  # Land gate (die, not advice): the state doc must carry the land-report
  # artifact BEFORE push+PR. Prose reminders here were skipped twice in the
  # field; die-gates never were. Existence-only check — content honesty stays
  # with the campaign-land skill (re-load it on EVERY land; do not re-enact
  # from memory).
  if [ "${LAND_GUARD:-1}" != "0" ] \
     && ! grep -qi '| phase |' "$doc" 2>/dev/null \
     && ! grep -qiE '^[[:space:]]*-?[[:space:]]*land-report[[:space:]]*:' "$doc" 2>/dev/null; then
    die "refusing land: '$doc' has no land-report (load the campaign-land skill; scaffold the table with 'campaign.sh land $n --report'). Bypass: LAND_GUARD=0 campaign.sh land $n"
  fi
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
  local tip; tip="$(git rev-parse "origin/$n")"
  if git merge-base --is-ancestor "origin/$n" "origin/$TRUNK"; then
    echo "MERGED (ancestry): origin/$n is an ancestor of origin/$TRUNK"; return 0
  fi
  # Not an ancestor: squash/rebase merges break ancestry — ask the PR API. A MERGED PR
  # counts as merged ONLY if its head commit matches THIS tip (else it is a stale
  # same-name PR from a reused branch name, not this work).
  if command -v gh >/dev/null 2>&1; then
    local prs
    if prs="$(gh pr list --head "$n" --state all --json number,state,baseRefName,headRefOid 2>/dev/null)"; then
      if pr_merged_tip "$n" "$tip"; then
        echo "MERGED (via PR — squash/merge-commit; non-ancestry is NORMAL for squash)"; return 0
      fi
      local merged_objs
      merged_objs="$(echo "$prs" | grep -o '{[^}]*}' | grep '"state":"MERGED"' || true)"
      if [ -n "$merged_objs" ]; then
        if echo "$merged_objs" | grep -qF "\"baseRefName\":\"$TRUNK\""; then
          echo "UNMERGED?: a MERGED PR into $TRUNK exists but its head ≠ this tip — a stale"
          echo "same-name PR from a reused branch, not this work. Verify on the PR page."
        else
          echo "STACKED?: MERGED PR exists but its base ≠ $TRUNK — content may not be on trunk."
          echo "prove content reach: git show origin/$TRUNK:<file> | grep <token-unique-to-this-diff>"
        fi
        return 0
      fi
      echo "UNMERGED: not an ancestor and no MERGED PR (PRs: $prs)"
    else
      echo "UNVERIFIED: not an ancestor by git, and the PR API is unreachable (non-GitHub"
      echo "remote or gh auth failure) — a squash merge cannot be ruled out. Check the PR page."
    fi
  else
    echo "UNVERIFIED: not an ancestor by git, and gh is unavailable so a squash-merge"
    echo "cannot be ruled out. Do NOT treat as UNMERGED without checking the PR page."
  fi
}

cmd_list() {
  git fetch origin -q --prune 2>/dev/null || true
  git worktree list --porcelain | awk '/^worktree /{sub(/^worktree /,""); w=$0} /^branch /{print w, $2}' | \
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
  # The tip we judge: the pushed branch if it still exists, else the local branch —
  # GitHub may auto-delete the head branch on merge, so origin/$n can be gone even
  # though the work IS merged.
  local tip=""
  if git rev-parse -q --verify "origin/$n" >/dev/null 2>&1; then
    tip="$(git rev-parse "origin/$n")"
  elif git rev-parse -q --verify "$n" >/dev/null 2>&1; then
    tip="$(git rev-parse "$n")"
  fi
  # Verdict for that tip = ancestry OR a MERGED PR into TRUNK for THIS exact tip.
  # Squash/rebase break ancestry; pr_merged_tip's headRefOid match keeps a stale
  # same-name merged PR from green-lighting genuinely-unmerged reused work.
  if [ -n "$tip" ]; then
    if git merge-base --is-ancestor "$tip" "origin/$TRUNK" 2>/dev/null; then
      :  # merge-commit merge — ancestry intact
    elif pr_merged_tip "$n" "$tip"; then
      :  # squash/rebase-merged into TRUNK — verified by PR headRefOid == our tip
    else
      die "refusing clean: '$n' is not verifiably merged into '$TRUNK' (tip ${tip:0:9}; run 'campaign.sh status $n'; use abort to discard)"
    fi
  fi
  # tip empty => both origin and local refs already gone => idempotent cleanup.
  # Land-report gate: the state doc must carry a filled verdict/result line
  # (campaign-land Phase 4, "docs in the SAME land") BEFORE the worktree is
  # destroyed. Content after the colon is required — the scaffold's empty
  # '- result / verdict:' line does not count.
  local doc="$STATE_DIR/$n.md"
  if [ "${FORCE_CLEAN:-0}" != "1" ] && [ -f "$doc" ] && \
     ! grep -qiE '(verdict|result)[^:]*:[[:space:]]*[^[:space:]]|LANDS|LANDED|ABANDONED' "$doc"; then
    die "refusing clean: '$doc' has no filled verdict/result line — update the state doc (campaign-land Phase 4) first. Bypass: FORCE_CLEAN=1 campaign.sh clean $n"
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
  if git -C "$DEP_DIR" merge-base --is-ancestor "origin/$n" "origin/$DEP_TRUNK"; then
    :  # ancestry confirms merge
  elif command -v gh >/dev/null 2>&1 \
       && (cd "$DEP_DIR" && gh pr list --head "$n" --state merged --json number 2>/dev/null | grep -q '"number"'); then
    :  # squash-merged — verified through the PR API
  else
    die "'$n' not verifiably merged into dep trunk '$DEP_TRUNK' (squash? verify on the dep repo's PR page; ancestry check alone is squash-blind)"
  fi
  local sha; sha="$(git -C "$DEP_DIR" rev-parse "origin/$DEP_TRUNK")"
  grep -q '^PIN=' "$PIN_FILE" || die "no PIN= line in $PIN_FILE"
  sed -i.bak "s|^PIN=.*|PIN=$sha|" "$PIN_FILE" && rm -f "$PIN_FILE.bak"
  git add "$PIN_FILE"
  git commit --no-verify -m "pin: $PIN_FILE -> $sha ($n)" -- "$PIN_FILE"
  git push origin HEAD
  echo "pinned $sha"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  new)    cmd_new    "${1:-}" ;;
  land)   cmd_land   "${1:-}" "${2:-}" ;;
  status) cmd_status "${1:-}" ;;
  list)   cmd_list ;;
  clean)  cmd_clean  "${1:-}" ;;
  abort)  cmd_abort  "${1:-}" "${2:-}" ;;
  pin)    cmd_pin    "${1:-}" ;;
  *)      usage ;;
esac
