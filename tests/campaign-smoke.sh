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

# issue #10: with no CAMPAIGN_WT_ROOT, the default root is per-project
( unset CAMPAIGN_WT_ROOT
  mkdir -p "$TMP/fakehome"
  proj="$(basename "$PWD")"
  HOME="$TMP/fakehome" "$CS" new d1 >/dev/null
  [ -d "$TMP/fakehome/wt/$proj/d1" ] || fail "default WT_ROOT not per-project (expected \$HOME/wt/<repo>/d1)"
  # issue #10 follow-up: invoked from INSIDE a linked worktree, the project
  # slot must still be the repo name, not the campaign name
  ( cd "$TMP/fakehome/wt/$proj/d1"
    HOME="$TMP/fakehome" "$CS" new d2 >/dev/null
    [ -d "$TMP/fakehome/wt/$proj/d2" ] || fail "inside-worktree invocation nested WT_ROOT (campaign name in project slot)"
    HOME="$TMP/fakehome" "$CS" abort d2 >/dev/null
  )
  HOME="$TMP/fakehome" "$CS" abort d1 >/dev/null
)
export CAMPAIGN_TRUNK=main

# issue #10 regression guard: sibling clones that share one --separate-git-dir
# PARENT must still land in DIFFERENT project slots. Deriving the project name
# from the git dir's parent collapses both onto that parent, so the second
# clone's 'new' collides on an already-existing worktree path.
( unset CAMPAIGN_WT_ROOT
  mkdir -p "$TMP/sephome" "$TMP/sepgit"
  for p in alpha beta; do
    git clone -q --separate-git-dir="$TMP/sepgit/$p.git" "$TMP/origin.git" "$TMP/sep/$p"
    ( cd "$TMP/sep/$p" && git config user.email smoke@test && git config user.name smoke
      HOME="$TMP/sephome" "$CS" new s1 >/dev/null ) \
      || fail "--separate-git-dir clone '$p': new failed (sibling WT_ROOT collision?)"
    [ -d "$TMP/sephome/wt/$p/s1" ] \
      || fail "--separate-git-dir clone '$p': WT_ROOT project slot is not the project name"
  done
)

# A repo path containing a SPACE must not be truncated. 'git worktree list
# --porcelain' does not quote paths, so splitting the line on whitespace keeps
# only the first field ('/tmp/my' out of '/tmp/my proj') and every project whose
# path has a space collapses onto one bogus slot.
( unset CAMPAIGN_WT_ROOT
  mkdir -p "$TMP/spacehome"
  git clone -q "$TMP/origin.git" "$TMP/sp/my proj"
  ( cd "$TMP/sp/my proj" && git config user.email smoke@test && git config user.name smoke
    HOME="$TMP/spacehome" "$CS" new p1 >/dev/null ) || fail "space-path repo: new failed"
  [ -d "$TMP/spacehome/wt/my proj/p1" ] \
    || fail "space-path repo: WT_ROOT slot truncated at the space (got: $(ls "$TMP/spacehome/wt"))"
  # ...and from INSIDE a linked worktree of that repo the slot must still hold
  ( cd "$TMP/spacehome/wt/my proj/p1"
    HOME="$TMP/spacehome" "$CS" new p2 >/dev/null ) || fail "space-path repo: inside-worktree new failed"
  [ -d "$TMP/spacehome/wt/my proj/p2" ] \
    || fail "space-path repo: inside-worktree slot truncated at the space"
)

# Linked worktree whose MAIN checkout is a --separate-git-dir clone. Here git
# keeps NO back-pointer to the main worktree (core.worktree is unset), so
# 'worktree list' reports the GIT DIR itself; the project slot must still be a
# clean per-project name — '<gitdir>.git' stripped to '<gitdir>' — never a
# literal '.git' suffix and never a slot shared with a sibling clone.
( unset CAMPAIGN_WT_ROOT
  mkdir -p "$TMP/lwhome" "$TMP/lwgit"
  git clone -q --separate-git-dir="$TMP/lwgit/myproj.git" "$TMP/origin.git" "$TMP/lwmain"
  ( cd "$TMP/lwmain" && git config user.email smoke@test && git config user.name smoke )
  git -C "$TMP/lwmain" worktree add -q "$TMP/lwlinked" -b lw1
  ( cd "$TMP/lwlinked" && HOME="$TMP/lwhome" "$CS" new l1 >/dev/null ) \
    || fail "separate-git-dir LINKED worktree: new failed"
  [ -d "$TMP/lwhome/wt/myproj/l1" ] \
    || fail "separate-git-dir LINKED worktree: slot is not the project name (got: $(ls "$TMP/lwhome/wt"))"
)

# new: worktree + branch + state doc
"$CS" new c1 >/dev/null
[ -d "$TMP/wt/c1" ]                       || fail "worktree missing"
git rev-parse -q --verify c1 >/dev/null   || fail "branch missing"
[ -f docs/campaigns/c1.md ]                || fail "state doc missing"

# name validation (numbered mode rejects free names)
if CAMPAIGN_NAMING=numbered "$CS" new badname 2>/dev/null; then fail "numbered naming accepted bad name"; fi

# status before push: NO-BRANCH
out="$("$CS" status c1)"; grep -q NO-BRANCH <<<"$out" || fail "expected NO-BRANCH before push"

# work + push (simulating what land does, without gh)
( cd "$TMP/wt/c1" && echo work > f.txt && git add f.txt && git commit -qm work && git push -q -u origin c1 )

# status after push, unmerged, gh-free: UNVERIFIED (must NOT claim UNMERGED without PR API)
out="$(PATH="/usr/bin:/bin" "$CS" status c1)"; grep -q UNVERIFIED <<<"$out" || fail "expected UNVERIFIED without gh"

# clean must refuse an unmerged branch
if PATH="/usr/bin:/bin" "$CS" clean c1 2>/dev/null; then fail "clean accepted unmerged branch"; fi
[ -d "$TMP/wt/c1" ] || fail "worktree destroyed by refused clean"

# clean must refuse a never-pushed campaign (data-loss guard)
"$CS" new c3 >/dev/null
( cd "$TMP/wt/c3" && echo w3 > h.txt && git add h.txt && git commit -qm w3 )
if "$CS" clean c3 2>/dev/null; then fail "clean destroyed a never-pushed campaign"; fi
[ -d "$TMP/wt/c3" ] || fail "worktree destroyed by refused clean (unpushed)"
"$CS" abort c3 >/dev/null

# merge on trunk → status flips to MERGED (ancestry)
git fetch -q origin && git merge -q --no-ff origin/c1 -m merge && git push -q origin main
out="$("$CS" status c1)"; grep -q "MERGED (ancestry)" <<<"$out" || fail "expected MERGED after merge"

# verdict gate: merged but state doc verdict still empty → clean must refuse
if "$CS" clean c1 2>/dev/null; then fail "clean accepted a land with an empty verdict line"; fi
[ -d "$TMP/wt/c1" ] || fail "worktree destroyed by verdict-refused clean"
# a plan-section line mentioning 'result:' must NOT satisfy the verdict gate
grep -q '^## plan' docs/campaigns/c1.md || fail "scaffold missing ## plan section"
echo '- [ ] sweep k grid → result: inconclusive so far' >> docs/campaigns/c1.md
if "$CS" clean c1 2>/dev/null; then fail "clean accepted a plan-line 'result:' as a verdict"; fi
# ...and a plan bullet merely CONTAINING a verdict word must not either (bare-word branch)
echo '- [ ] check if this already LANDED upstream before redoing the work' >> docs/campaigns/c1.md
if "$CS" clean c1 2>/dev/null; then fail "clean accepted a plan-line containing LANDED as a verdict"; fi
# ...nor when the prose starts with a label token (decoration is ONE key, not prose)
echo '- [ ] note: this already LANDED upstream, confirm before redoing' >> docs/campaigns/c1.md
if "$CS" clean c1 2>/dev/null; then fail "clean accepted a labelled plan bullet as a verdict"; fi
# A BOLD PARAGRAPH is not a list item. Long research docs mark intermediate
# sub-conclusions with '**Verdict: …**'; without a space after the bullet
# marker the leading '*' poses as the marker and the second as emphasis, and a
# still-open campaign passes the gate that exists to protect it.
echo '**Verdict: L2 is validated.**' >> docs/campaigns/c1.md
if "$CS" clean c1 2>/dev/null; then fail "clean accepted a bold PARAGRAPH as a verdict row"; fi
echo '**VERDICT: ceiling ~1.3x deck, hard-capped by Amdahl (GEMM=24% of wall).**' >> docs/campaigns/c1.md
if "$CS" clean c1 2>/dev/null; then fail "clean accepted an all-caps bold paragraph as a verdict row"; fi
# An UNCHECKED '- [ ]' box is a TODO, never a verdict — including when the
# verdict WORD is the first token after the label, where "prose intervenes"
# cannot discriminate.
echo '- [ ] TODO: LANDED upstream? check before redoing' >> docs/campaigns/c1.md
if "$CS" clean c1 2>/dev/null; then fail "clean accepted an unchecked TODO box as a verdict"; fi
echo '- [ ] 확인: LANDED 됐는지 먼저 보기' >> docs/campaigns/c1.md
if "$CS" clean c1 2>/dev/null; then fail "clean accepted an unchecked non-ASCII TODO box as a verdict"; fi
echo '- [ ] risk: ABANDONED approach may resurface' >> docs/campaigns/c1.md
if "$CS" clean c1 2>/dev/null; then fail "clean accepted an unchecked risk box as a verdict"; fi
sed -i 's|- result / verdict:|- result / verdict: LANDS — smoke ok|' docs/campaigns/c1.md

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

# worktree hint: {wt} substituted when set, silent when empty
out="$(CAMPAIGN_WORKTREE_HINT='test: run {wt}/go' "$CS" new c5)"
grep -q "test: run $TMP/wt/c5/go" <<<"$out" || fail "worktree hint not printed/substituted"
"$CS" abort c5 >/dev/null

# submodule init: a fresh worktree must have populated submodules
# (modern git blocks file-protocol submodule clones; the env-var config
# reaches every child git process, including campaign.sh's inner
# 'submodule update' — repo config does NOT reach the inner clone)
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=protocol.file.allow GIT_CONFIG_VALUE_0=always
git init -q --bare -b main "$TMP/sub.git"
git clone -q "$TMP/sub.git" "$TMP/subwork"
( cd "$TMP/subwork" && git config user.email s@t && git config user.name s \
  && echo subfile > sub.txt && git add . && git commit -qm sub && git push -q origin HEAD:main ) \
  || fail "sub fixture setup failed"
git submodule add -q "$TMP/sub.git" external/sub || fail "submodule add failed"
git commit -qm add-submodule && git push -q origin main
"$CS" new c6 >/dev/null || fail "new failed on submodule repo"
[ -f "$TMP/wt/c6/external/sub/sub.txt" ] || fail "submodule not initialized in fresh worktree"
CAMPAIGN_INIT_SUBMODULES=0 "$CS" new c7 >/dev/null
[ -f "$TMP/wt/c7/external/sub/sub.txt" ] && fail "CAMPAIGN_INIT_SUBMODULES=0 still initialized"
"$CS" abort c6 >/dev/null && "$CS" abort c7 >/dev/null

# ---- PR-API edge cases (mock gh): squash+head-deleted (F1) and reused-name (F2) ----
# The verdict is tied to the branch TIP; a MERGED PR counts only when its headRefOid
# matches that tip. Mock gh returns $GH_MOCK for `pr list`, succeeds otherwise.
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" <<'GH'
#!/usr/bin/env bash
if [ "$1" = pr ] && [ "$2" = list ]; then printf '%s\n' "${GH_MOCK:-[]}"; exit 0; fi
exit 0
GH
chmod +x "$TMP/bin/gh"
ghp="$TMP/bin:/usr/bin:/bin"
merged_pr() { printf '[{"number":%s,"state":"MERGED","baseRefName":"main","headRefOid":"%s"}]' "$1" "$2"; }
badoid=0000000000000000000000000000000000000000

# F1: squash-merged, then GitHub auto-deleted the head branch → origin/<n> is gone;
# clean must judge the LOCAL tip via the PR API and allow, not refuse as "never pushed".
"$CS" new f1 >/dev/null
( cd "$TMP/wt/f1" && echo w > f1.txt && git add . && git commit -qm f1 && git push -q -u origin f1 )
f1tip="$(git rev-parse f1)"
git fetch -q origin && git merge -q --squash origin/f1 && git commit -qm "squash f1" && git push -q origin main
git push -q origin --delete f1 && git fetch -q origin --prune       # simulate head auto-delete
sed -i 's|- result / verdict:|- result / verdict: LANDS|' docs/campaigns/f1.md
GH_MOCK="$(merged_pr 1 "$f1tip")" PATH="$ghp" "$CS" clean f1 >/dev/null \
  || fail "F1: clean refused squash-merged, head-deleted work"
[ -d "$TMP/wt/f1" ] && fail "F1: worktree survived a valid clean"

# F2 (destructive path): unmerged reused name + a stale same-name MERGED PR whose head
# ≠ this tip must NOT green-light teardown.
"$CS" new f2 >/dev/null
( cd "$TMP/wt/f2" && echo w > f2.txt && git add . && git commit -qm f2 && git push -q -u origin f2 )
sed -i 's|- result / verdict:|- result / verdict: LANDS|' docs/campaigns/f2.md
if GH_MOCK="$(merged_pr 2 "$badoid")" PATH="$ghp" "$CS" clean f2 2>/dev/null; then
  fail "F2: clean tore down unmerged work via a stale same-name PR"; fi
[ -d "$TMP/wt/f2" ]                                   || fail "F2: worktree destroyed despite refusal"
git ls-remote --exit-code origin f2 >/dev/null 2>&1  || fail "F2: remote branch destroyed despite refusal"
"$CS" abort f2 --purge >/dev/null

# status: MERGED (via PR) only when headRefOid matches this tip; a stale-tip PR → UNMERGED?
"$CS" new f3 >/dev/null
( cd "$TMP/wt/f3" && echo w > f3.txt && git add . && git commit -qm f3 && git push -q -u origin f3 )
f3tip="$(git rev-parse f3)"
git fetch -q origin && git merge -q --squash origin/f3 && git commit -qm "squash f3" && git push -q origin main
git fetch -q origin --prune
out="$(GH_MOCK="$(merged_pr 3 "$f3tip")" PATH="$ghp" "$CS" status f3)"
grep -q "MERGED (via PR" <<<"$out" || fail "F3: status missed a squash merge whose PR head matches the tip"
out="$(GH_MOCK="$(merged_pr 3 "$badoid")" PATH="$ghp" "$CS" status f3)"
grep -q "UNMERGED?" <<<"$out" || fail "F3: status treated a stale-tip MERGED PR as this work"
sed -i 's|- result / verdict:|- result / verdict: LANDS|' docs/campaigns/f3.md
GH_MOCK="$(merged_pr 3 "$f3tip")" PATH="$ghp" "$CS" clean f3 >/dev/null \
  || fail "F3: clean refused a squash-merged branch (matching tip)"


# ---- verdict gate: decoration is allowed, prose is not (v0.5.20 over-anchored) ----
# Each form below is a verdict row a real state doc carries; the gate must accept
# it. Acceptance is destructive (clean tears the campaign down), so one campaign
# per form.
verdict_ok() {   # <campaign name> <verdict row>
  local n="$1" row="$2"
  "$CS" new "$n" >/dev/null
  ( cd "$TMP/wt/$n" && echo w > "$n.txt" && git add . && git commit -qm "$n" && git push -q -u origin "$n" )
  git fetch -q origin && git merge -q --no-ff "origin/$n" -m "merge $n" && git push -q origin main
  printf '%s\n' "$row" >> "docs/campaigns/$n.md"
  env ${VERDICT_ENV:-} "$CS" clean "$n" >/dev/null \
    || fail "verdict gate refused a legitimate row${VERDICT_ENV:+ (${VERDICT_ENV})}: $row"
}
verdict_ok v1 '- **verdict**: LANDS — merged as PR #13'
verdict_ok v2 '- 결론: LANDS — PR #13 머지됨'
verdict_ok v3 '- [x] LANDED as PR #7'
verdict_ok v4 '- `verdict`: LANDS'
verdict_ok v5 '- result / verdict: LANDS — ok'
verdict_ok v6 '- LANDED as PR #7'
verdict_ok v7 '- ABANDONED — superseded'
verdict_ok v8 '  - result / verdict: LANDS'
verdict_ok v9 '* result: LANDS'
verdict_ok v10 '- [X] LANDED as PR #7'
verdict_ok v11 '- [x] verdict: LANDS'
verdict_ok v12 '- _verdict_: LANDS'
verdict_ok v13 '- **LANDS** — ok'
verdict_ok v14 '- status: LANDED (PR #12 merged)'
# Locale independence: a character-counted bound on the label group counts
# BYTES under LC_ALL=C (cron, systemd, env -i), so a non-ASCII label silently
# stopped matching past ~5 characters — the exact silent skip this gate exists
# to remove. This row is 24 bytes of label under a C locale.
VERDICT_ENV='LC_ALL=C' verdict_ok v15 '- 결론결론결론결론: LANDS — PR #13 머지됨'

# ---- land gate: state doc must carry the land-report artifact before push ----
"$CS" new g1 >/dev/null
( cd "$TMP/wt/g1" && echo w > g1.txt && git add . && git commit -qm g1 )
if PATH="/usr/bin:/bin" "$CS" land g1 2>/dev/null; then fail "land pushed without a land-report"; fi
git ls-remote --exit-code origin g1 >/dev/null 2>&1 && fail "land gate died AFTER pushing"
PATH="/usr/bin:/bin" "$CS" land g1 --report >/dev/null || fail "land --report failed"
grep -q '| phase |' docs/campaigns/g1.md || fail "--report did not append the table"
PATH="/usr/bin:/bin" "$CS" land g1 >/dev/null 2>&1 || fail "land refused despite land-report table"
git ls-remote --exit-code origin g1 >/dev/null 2>&1 || fail "land did not push with table present"
"$CS" abort g1 --purge >/dev/null

# translated table header under an intact heading must still pass the gate
"$CS" new g3 >/dev/null
( cd "$TMP/wt/g3" && echo w > g3.txt && git add . && git commit -qm g3 )
PATH="/usr/bin:/bin" "$CS" land g3 --report >/dev/null
sed -i 's/| phase | ran? | evidence |/| 단계 | 실행? | 증거 |/' docs/campaigns/g3.md
sed -i 's/|-------|------|----------|/|------|------|------|/' docs/campaigns/g3.md
PATH="/usr/bin:/bin" "$CS" land g3 >/dev/null 2>&1 || fail "translated header under intact heading was refused"
git ls-remote --exit-code origin g3 >/dev/null 2>&1 || fail "g3 did not push"
"$CS" abort g3 --purge >/dev/null

# branch tracking the state doc must trigger the trunk-ownership WARN
"$CS" new g4 >/dev/null
( cd "$TMP/wt/g4" && echo w > g4.txt && mkdir -p docs/campaigns && echo "# campaign: g4" > docs/campaigns/g4.md \
  && git add . && git commit -qm g4 )
PATH="/usr/bin:/bin" "$CS" land g4 --report >/dev/null
out="$(PATH="/usr/bin:/bin" "$CS" land g4 2>&1)" || fail "g4 land failed outright"
grep -q "TRUNK-owned" <<<"$out" || fail "branch-tracked state doc did not WARN"
"$CS" abort g4 --purge >/dev/null

# a plan bullet merely MENTIONING the header must not satisfy the land gate
# (nor block --report as an "existing" table)
"$CS" new g5 >/dev/null
( cd "$TMP/wt/g5" && echo w > g5.txt && git add . && git commit -qm g5 )
echo '- [ ] add a | phase | table later' >> docs/campaigns/g5.md
if PATH="/usr/bin:/bin" "$CS" land g5 2>/dev/null; then fail "land accepted a plan bullet mentioning '| phase |'"; fi
git ls-remote --exit-code origin g5 >/dev/null 2>&1 && fail "land gate died AFTER pushing (g5)"
PATH="/usr/bin:/bin" "$CS" land g5 --report >/dev/null || fail "--report refused: plan bullet read as an existing table"
PATH="/usr/bin:/bin" "$CS" land g5 >/dev/null 2>&1 || fail "land refused despite a real land-report table"
"$CS" abort g5 --purge >/dev/null

# the existence-only escape hatch stays valid
"$CS" new g6 >/dev/null
( cd "$TMP/wt/g6" && echo w > g6.txt && git add . && git commit -qm g6 )
echo '- land-report: TBD' >> docs/campaigns/g6.md
PATH="/usr/bin:/bin" "$CS" land g6 >/dev/null 2>&1 || fail "land refused a '- land-report:' line"
"$CS" abort g6 --purge >/dev/null

# LAND_GUARD=0 bypass
"$CS" new g2 >/dev/null
( cd "$TMP/wt/g2" && echo w > g2.txt && git add . && git commit -qm g2 )
LAND_GUARD=0 PATH="/usr/bin:/bin" "$CS" land g2 >/dev/null 2>&1 || fail "LAND_GUARD=0 bypass failed"
"$CS" abort g2 --purge >/dev/null
echo "SMOKE PASS"
