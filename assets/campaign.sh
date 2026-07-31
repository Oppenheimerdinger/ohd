#!/usr/bin/env bash
# campaign.sh — worktree campaign lifecycle (ohd template)
# Drop-in: fill the config block per docs/campaign-dropin.md, copy to tools/campaign.sh.
set -euo pipefail

# ── config (drop-in interview fills these; CAMPAIGN_* env vars override) ──
TRUNK="${CAMPAIGN_TRUNK:-main}"
WT_ROOT="${CAMPAIGN_WT_ROOT:-}"   # empty = per-project default, derived after ROOT below
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

# Worktree roots are per-project: a flat shared root collides as soon as two
# sibling projects both number campaigns from 001 (issue #10). The project name
# must be the SAME from every checkout of one project, so it is read from the
# first 'git worktree list --porcelain' entry — git lists the MAIN worktree
# first, from a linked worktree as well as from the main one. --show-toplevel
# cannot do this: inside a linked worktree it returns the worktree's own path,
# so every campaign would open a slot named after the previous campaign (issue
# #10 follow-up). Deriving the name from the git dir's PARENT is no substitute
# either: under 'clone --separate-git-dir' every sibling project resolves to the
# shared gitdir parent (siblings collide again), and inside a submodule every
# submodule collapses onto its 'modules/…' parent. The entry is read with sed,
# not awk: porcelain does NOT quote paths, so splitting on whitespace truncates
# any project path containing a space or tab.
# Under 'clone --separate-git-dir' that first entry is the GIT DIR rather than a
# checkout, from either side — git records no back-pointer to the main worktree
# there (core.worktree is unset) — so the git dir's own name, '.git' stripped,
# is the project name. It is the only identity available to BOTH the main
# checkout and a linked worktree, which is why this derivation is UNBRANCHED: a
# branch on layout made those two disagree (main → checkout dir name, linked →
# git dir name), and 'clean' from the losing side deleted both branches while
# the worktree survived, untouched, at the other slot. Sibling clones keep
# distinct '<name>.git' dirs and so still land in distinct slots — issue #10.
PROJECT_ROOT="$(git worktree list --porcelain | sed -n '1s/^worktree //p')"
WT_ROOT="${WT_ROOT:-$HOME/wt/$(basename "$PROJECT_ROOT" .git)}"

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

## plan
<!-- living plan: certain stretch = task checkboxes; uncertain stretch = ONE
line (next probe + decision rule). Results edit this section, plus a one-line
reason. -->
DOC
    echo "state doc: $doc  (TRUNK-owned: commit it on trunk; do NOT commit it on the campaign branch — add/add conflicts at merge)"
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
    grep -qiE '^##[[:space:]]*land[- ]report|^[[:space:]]*\|[[:space:]]*phase[[:space:]]*\|' "$doc" && die "$doc already has a land-report table"
    cat >> "$doc" <<'TBL'

## land report
Scope: land ritual only (branch→trunk mechanics and gates) — a green table is
NOT a claim the work is correct (validation gate, external) or enabled by
default (that is exactly the 2.5 row, no more).
| phase | ran? | evidence |
|-------|------|----------|
| 0 preconditions      | | |
| 0.5 plan recorded    | | |
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
  # from memory). The header match is line-anchored: a plan bullet that merely
  # MENTIONS '| phase |' is prose, not the artifact.
  if [ "${LAND_GUARD:-1}" != "0" ] \
     && ! grep -qiE '^[[:space:]]*\|[[:space:]]*phase[[:space:]]*\|' "$doc" 2>/dev/null \
     && ! grep -qiE '^##[[:space:]]*land[- ]report' "$doc" 2>/dev/null \
     && ! grep -qiE '^[[:space:]]*-?[[:space:]]*land-report[[:space:]]*:' "$doc" 2>/dev/null; then
    die "refusing land: '$doc' has no land-report — the gate matches the '## land report' heading or the '| phase |' header (keep those lines intact; row content is yours). Scaffold: 'campaign.sh land $n --report'. Bypass: LAND_GUARD=0 campaign.sh land $n"
  fi
  if git -C "$wt" ls-files --error-unmatch "$doc" >/dev/null 2>&1; then
    echo "WARN: the campaign branch tracks $doc — the state doc is TRUNK-owned; if the merge conflicts on it, resolve as UNION (campaign-land Phase 5)." >&2
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

# teardown <name> <del_remote> — returns NON-ZERO if a worktree for this
# campaign is still on disk afterwards. The branches are deleted either way, so a
# caller that printed success unconditionally would leave a live worktree holding
# uncommitted work with no branch left to recover it from. Two ways that happens:
# something else occupies our slot, or the campaign's worktree is registered at a
# DIFFERENT path than the slot we computed (a hand-moved worktree, or a WT_ROOT
# that changed between 'new' and 'clean'). 'worktree list' is consulted for the
# second, before 'branch -D' runs — git refuses to delete a branch that is still
# checked out somewhere, and that refusal is swallowed here.
teardown() {
  local n="$1" del_remote="$2" rc=0 stray=""
  local wt; wt="$(wt_path "$n")"
  git worktree remove --force "$wt" 2>/dev/null || true
  git worktree prune
  if [ -e "$wt" ]; then
    echo "WARN: $wt still exists (not this repo's worktree?) — left in place" >&2
    rc=1
  fi
  # substr, not fields: porcelain does not quote paths with spaces or tabs.
  stray="$(git worktree list --porcelain | awk -v b="refs/heads/$n" '
    /^worktree /{p = substr($0, 10)}
    /^branch /{if (substr($0, 8) == b) print p}')"
  if [ -n "$stray" ]; then
    echo "WARN: campaign '$n' is still checked out at $stray (expected $wt) — left in place" >&2
    rc=1
  fi
  git branch -D "$n" 2>/dev/null || true
  if [ "$del_remote" = yes ]; then git push origin --delete "$n" 2>/dev/null || true; fi
  git worktree prune
  rmdir "$WT_ROOT" 2>/dev/null || true
  return $rc
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
  # Land-report gate: the state doc's SCAFFOLD verdict row must be FILLED before
  # the worktree is destroyed (campaign-land Phase 4, "docs in the SAME land").
  #
  # This gate and checkup.sh's land-report audit deliberately use DIFFERENT
  # rules. Their inputs differ, so one shared rule cannot serve both:
  #   * 'clean' only ever runs on a campaign 'new' opened, and 'new' writes the
  #     literal '- result / verdict:' row, so an EXACT anchor is available here.
  #   * the audit reads LEGACY docs, of which only 84 of 365 carry that row, so
  #     it must stay tolerant of decorated, translated and 'status:'-labelled
  #     rows — that recognition is v0.5.22's headline fix.
  # Sharing forced the tolerant, prose-adjacent pattern onto this consumer, and
  # three rounds of tightening it failed, because '- **verdict**: LANDS' (a real
  # verdict, must pass) and '- **VERDICT: nrxx-tiling genuinely reduces the
  # peak.**' (a mid-campaign sub-conclusion in a doc whose campaign is still
  # OPEN, must not) are lexically near-identical. Only the scaffold row separates
  # them, and it separates them without any regex cleverness at all.
  #
  # So: the literal scaffold phrase, with non-whitespace after the colon. The
  # test is position-free — 25 of the 139 live docs carrying a verdict line keep
  # it BELOW a heading — and allows emphasis around the label, which 2 of the 84
  # live scaffold rows use. The untouched scaffold row does not pass.
  #
  # Cost, accepted knowingly: a doc recording its verdict ONLY as a substitute
  # row ('- **verdict**: LANDS', '- 결론: LANDS', '- [x] LANDED as PR #7',
  # '- status: LANDED (PR #12 merged)') no longer satisfies 'clean' — it still
  # satisfies the audit. A campaign whose doc pre-dated 'new' (which leaves an
  # existing doc alone) has no scaffold row at all and is refused until one is
  # added, so coverage here is high by construction but not total. Both are
  # fail-SAFE refusals of a command whose failure mode is destroying a live
  # worktree holding uncommitted work; FORCE_CLEAN=1 is the escape.
  local doc="$STATE_DIR/$n.md"
  if [ "${FORCE_CLEAN:-0}" != "1" ] && [ -f "$doc" ] && \
     ! grep -qiE '^[[:space:]]*[-*][[:space:]]+[*_`]*result[[:space:]]*/[[:space:]]*verdict[*_`]*[[:space:]]*:[[:space:]]*[^[:space:]]' "$doc"; then
    die "refusing clean: '$doc' has no FILLED scaffold verdict row — put the verdict after the '- result / verdict:' line (campaign-land Phase 4), then re-run. This is stricter than /ohd-checkup's land-report audit ON PURPOSE: a decorated or translated row ('- **verdict**: LANDS', '- 결론: LANDS') satisfies the AUDIT but does not authorize teardown. Bypass: FORCE_CLEAN=1 campaign.sh clean $n"
  fi
  if teardown "$n" yes; then
    echo "cleaned $n (worktree + local & remote branch)"
  else
    die "PARTIAL clean of '$n': branches were deleted but the worktree SURVIVED (see the WARN above) — remove it by hand once you have salvaged anything uncommitted in it"
  fi
}

cmd_abort() {
  local n="$1"; check_name "$n"; local purge="${2:-}"
  local del=no; [ "$purge" = --purge ] && del=yes
  if teardown "$n" "$del"; then
    echo "aborted $n (remote branch: $([ "$del" = yes ] && echo purged || echo kept))"
  else
    die "PARTIAL abort of '$n': branches were handled but the worktree SURVIVED (see the WARN above) — remove it by hand"
  fi
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
