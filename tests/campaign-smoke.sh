#!/usr/bin/env bash
# campaign-smoke.sh — round-trip test of assets/campaign.sh in a throwaway repo.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CS="$HERE/assets/campaign.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "SMOKE FAIL: $*" >&2; exit 1; }

# throwaway origin + clone
git init -q --bare "$TMP/origin.git"
git clone -q "$TMP/origin.git" "$TMP/repo"
cd "$TMP/repo"
git config user.email smoke@test && git config user.name smoke
echo hello > README.md && git add . && git commit -qm init && git push -q origin HEAD:main
git fetch -q origin && git checkout -q main 2>/dev/null || git checkout -qb main origin/main

export CAMPAIGN_WT_ROOT="$TMP/wt"
export CAMPAIGN_TRUNK=main

# new: worktree + branch + state doc
"$CS" new c1 >/dev/null
[ -d "$TMP/wt/c1" ]                       || fail "worktree missing"
git rev-parse -q --verify c1 >/dev/null   || fail "branch missing"
[ -f docs/campaigns/c1.md ]                || fail "state doc missing"

# name validation (numbered mode rejects free names)
if CAMPAIGN_NAMING=numbered "$CS" new badname 2>/dev/null; then fail "numbered naming accepted bad name"; fi

# status before push: NO-BRANCH
"$CS" status c1 | grep -q NO-BRANCH        || fail "expected NO-BRANCH before push"

# work + push (simulating what land does, without gh)
( cd "$TMP/wt/c1" && echo work > f.txt && git add f.txt && git commit -qm work && git push -q -u origin c1 )

# status after push, unmerged, gh-free: UNVERIFIED (must NOT claim UNMERGED without PR API)
PATH="/usr/bin:/bin" "$CS" status c1 | grep -q UNVERIFIED || fail "expected UNVERIFIED without gh"

# clean must refuse an unmerged branch
if PATH="/usr/bin:/bin" "$CS" clean c1 2>/dev/null; then fail "clean accepted unmerged branch"; fi
[ -d "$TMP/wt/c1" ] || fail "worktree destroyed by refused clean"

# merge on trunk → status flips to MERGED (ancestry)
git fetch -q origin && git merge -q --no-ff origin/c1 -m merge && git push -q origin main
"$CS" status c1 | grep -q "MERGED (ancestry)" || fail "expected MERGED after merge"

# clean now succeeds; worktree and branches gone
"$CS" clean c1 >/dev/null
[ ! -d "$TMP/wt/c1" ]                          || fail "worktree survived clean"
git rev-parse -q --verify c1 >/dev/null && fail "local branch survived clean"
git ls-remote --exit-code origin c1 >/dev/null 2>&1 && fail "remote branch survived clean"

# abort keeps remote unless --purge
"$CS" new c2 >/dev/null
( cd "$TMP/wt/c2" && echo w2 > g.txt && git add g.txt && git commit -qm w2 && git push -q -u origin c2 )
"$CS" abort c2 >/dev/null
git ls-remote --exit-code origin c2 >/dev/null 2>&1 || fail "abort deleted remote branch"
git push -q origin --delete c2

# list runs without error on empty set
"$CS" list >/dev/null || fail "list errored"

echo "SMOKE PASS"
