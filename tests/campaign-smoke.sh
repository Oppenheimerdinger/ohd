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

# ...and the MAIN checkout of that same project must resolve to the SAME slot.
# The checkout directory is deliberately named differently from the git dir
# here: when they coincide ('sep/alpha' + 'sepgit/alpha.git', as above) the two
# derivations agree by accident and a split stays invisible. A split is not
# cosmetic — 'clean' run from the side that guesses wrong deletes the branches
# while the worktree survives untouched at the other slot.
( unset CAMPAIGN_WT_ROOT
  mkdir -p "$TMP/aghome" "$TMP/aggit"
  git clone -q --separate-git-dir="$TMP/aggit/agproj.git" "$TMP/origin.git" "$TMP/agcheckout"
  ( cd "$TMP/agcheckout" && git config user.email smoke@test && git config user.name smoke )
  git -C "$TMP/agcheckout" worktree add -q "$TMP/aglinked" -b ag0
  ( cd "$TMP/agcheckout" && HOME="$TMP/aghome" "$CS" new a1 >/dev/null ) \
    || fail "separate-git-dir MAIN checkout: new failed"
  ( cd "$TMP/aglinked"   && HOME="$TMP/aghome" "$CS" new a2 >/dev/null ) \
    || fail "separate-git-dir LINKED worktree: new failed"
  slots="$(ls "$TMP/aghome/wt" | wc -l)"
  [ "$slots" = 1 ] \
    || fail "separate-git-dir: main checkout and linked worktree of ONE project resolved to $slots slots ($(ls "$TMP/aghome/wt" | tr '\n' ' '))"
  [ -d "$TMP/aghome/wt/agproj/a1" ] && [ -d "$TMP/aghome/wt/agproj/a2" ] \
    || fail "separate-git-dir: shared slot is not the git dir's name (got: $(ls "$TMP/aghome/wt"))"
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


# ---- clean's verdict gate: the SCAFFOLD ROW, filled ----
# This gate and checkup's land-report audit use DIFFERENT rules on purpose (see
# cmd_clean's comment). 'clean' only ever runs on campaigns 'new' opened, and
# 'new' always writes the literal '- result / verdict:' row, so an exact anchor
# is available here — and only an exact anchor separates a real verdict from a
# mid-campaign bold sub-conclusion, which is lexically identical to a decorated
# canonical row. Acceptance is destructive (clean tears the campaign down), so
# one campaign per accepted row.
clean_ok() {   # <campaign name> <row that replaces the scaffold's>
  local n="$1" row="$2"
  "$CS" new "$n" >/dev/null
  ( cd "$TMP/wt/$n" && echo w > "$n.txt" && git add . && git commit -qm "$n" && git push -q -u origin "$n" )
  git fetch -q origin && git merge -q --no-ff "origin/$n" -m "merge $n" && git push -q origin main
  # drop the scaffold's empty row and re-add the filled one at the END of the
  # doc, i.e. BELOW '## plan' — the anchor is position-free, because 25 of the
  # 139 live docs carrying a verdict line keep it under a heading.
  grep -v '^- result / verdict:$' "docs/campaigns/$n.md" > "$TMP/doc.tmp"
  { cat "$TMP/doc.tmp"; printf '%s\n' "$row"; } > "docs/campaigns/$n.md"
  env ${CLEAN_ENV:-} "$CS" clean "$n" >/dev/null \
    || fail "clean refused a FILLED scaffold row${CLEAN_ENV:+ (${CLEAN_ENV})}: $row"
  [ ! -d "$TMP/wt/$n" ] || fail "clean reported success but left the worktree: $row"
}
clean_ok k01 '- result / verdict: LANDS — merged as PR #13'
clean_ok k02 '- result / verdict: ABANDONED — superseded'
clean_ok k03 '  - result / verdict: LANDS'
clean_ok k04 '* result / verdict: LANDS'
clean_ok k05 '- Result / Verdict: LANDS'
clean_ok k06 '- result/verdict: LANDS'
# 2 of the 84 live docs carrying this row decorate the label, so emphasis around
# the phrase is accepted; the literal phrase is the anchor, not the decoration.
clean_ok k07 '- **result / verdict**: LANDS'
clean_ok k08 '- **result / verdict: DONE.** both arms, identically'
# Locale independence: a character-counted bound on a label group counts BYTES
# under LC_ALL=C (cron, systemd, env -i), which silently dropped non-ASCII
# content past ~5 characters — the exact silent skip this gate exists to remove.
CLEAN_ENV='LC_ALL=C' clean_ok k09 '- result / verdict: 랜딩됨 — PR #13 머지됨'

# Rows that do NOT fill the scaffold row. Refusal is non-destructive, so they
# all run against ONE merged campaign whose scaffold row is still empty.
"$CS" new k10 >/dev/null
( cd "$TMP/wt/k10" && echo w > k10.txt && git add . && git commit -qm k10 && git push -q -u origin k10 )
git fetch -q origin && git merge -q --no-ff origin/k10 -m "merge k10" && git push -q origin main
clean_refuses() {   # <row appended to an OPEN doc>
  printf '%s\n' "$1" >> docs/campaigns/k10.md
  if "$CS" clean k10 2>/dev/null; then fail "clean accepted a row that does not fill the scaffold: $1"; fi
  [ -d "$TMP/wt/k10" ] || fail "worktree destroyed by a REFUSED clean: $1"
}
# BEHAVIOR-CHANGE (v0.5.22): these substitutes still satisfy checkup's audit,
# but they no longer authorize teardown.
clean_refuses '- **verdict**: LANDS — merged as PR #13'
clean_refuses '- [x] LANDED as PR #7'
clean_refuses '- status: LANDED (PR #12 merged)'
clean_refuses '- LANDED as PR #7'
clean_refuses '- `verdict`: LANDS'
clean_refuses '- ABANDONED — superseded'
clean_refuses '- **LANDS** — ok'
# The row that destroyed a real worktree: a bold sub-conclusion written as a
# REAL bullet, in a doc whose scaffold row is still empty and whose campaign is
# open ("NOT built, NOT measured"). Structurally identical to a decorated
# canonical row — only the scaffold anchor tells them apart.
clean_refuses '- **VERDICT: nrxx-tiling genuinely reduces the peak.** Keep the grids HOST;'
# A label whose value STARTS with the verdict word, with no checkbox to betray
# it as a plan item — the hole that survived three rounds of regex tightening.
clean_refuses '- TODO: LANDED upstream? check before redoing'
clean_refuses '- 확인: LANDED 됐는지 먼저 보기'
# An empty scaffold row is not a filled one, whitespace included.
clean_refuses '- result / verdict:'
clean_refuses '- result / verdict:      '
# A doc with NO scaffold row at all is REFUSED rather than waved through. 'new'
# leaves the doc alone when one already exists, so this is reachable.
printf '# campaign: k10\n- goal: x\n- **verdict**: LANDS\n' > docs/campaigns/k10.md
if "$CS" clean k10 2>/dev/null; then fail "clean accepted a doc carrying no scaffold verdict row"; fi
[ -d "$TMP/wt/k10" ] || fail "worktree destroyed by a refused clean (no scaffold row)"
# ...and FORCE_CLEAN=1 remains the escape for exactly that case.
FORCE_CLEAN=1 "$CS" clean k10 >/dev/null || fail "FORCE_CLEAN=1 did not bypass the verdict gate"
[ ! -d "$TMP/wt/k10" ] || fail "FORCE_CLEAN=1 did not tear the worktree down"

# ---- teardown must not report success it did not achieve ----
# If the worktree is not where teardown looked — moved by hand, or a WT_ROOT
# that differs between 'new' and 'clean' — the BRANCHES still get deleted.
# Printing "cleaned" there leaves a live worktree holding uncommitted work with
# no branch left to recover it from. That is the shape the --separate-git-dir
# slot split produced before the derivation above was unified.
"$CS" new t1 >/dev/null
( cd "$TMP/wt/t1" && echo w > t1.txt && git add . && git commit -qm t1 && git push -q -u origin t1 )
git fetch -q origin && git merge -q --no-ff origin/t1 -m "merge t1" && git push -q origin main
sed -i 's|- result / verdict:|- result / verdict: LANDS|' docs/campaigns/t1.md
echo "UNCOMMITTED WORK" > "$TMP/wt/t1/inprogress.txt"
out="$(CAMPAIGN_WT_ROOT="$TMP/elsewhere" "$CS" clean t1 2>&1)" && rc=0 || rc=1
[ -d "$TMP/wt/t1" ] || fail "teardown fixture is not exercising the surviving-worktree case"
grep -q '^cleaned t1' <<<"$out" && fail "clean printed 'cleaned' while the worktree survived at $TMP/wt/t1"
[ "$rc" = 1 ] || fail "clean exited 0 while the worktree survived"
grep -q "$TMP/wt/t1" <<<"$out" || fail "clean did not name the surviving worktree's real path"
"$CS" abort t1 --purge >/dev/null 2>&1 || true

# The 15-row required-accept matrix that used to live here — every decorated,
# translated and checkboxed verdict row a real doc carries — is now the AUDIT's
# contract and lives in tests/checkup-smoke.sh §9e. Under clean's scaffold
# anchor most of those rows are refusals, asserted above.

# ---- land gate: state doc must carry the land-report artifact before push ----
"$CS" new g1 >/dev/null
( cd "$TMP/wt/g1" && echo w > g1.txt && git add . && git commit -qm g1 )
if PATH="/usr/bin:/bin" "$CS" land g1 2>/dev/null; then fail "land pushed without a land-report"; fi
git ls-remote --exit-code origin g1 >/dev/null 2>&1 && fail "land gate died AFTER pushing"
PATH="/usr/bin:/bin" "$CS" land g1 --report >/dev/null || fail "land --report failed"
grep -q '| phase | ran? | evidence |' docs/campaigns/g1.md || fail "--report did not append the table"
grep -q 'reference:' docs/campaigns/g1.md || fail "--report did not seed the row-4 'reference:' prompt"
grep -q 'verification:' docs/campaigns/g1.md || fail "--report did not seed the row-6 'verification:' prompt"
# the era marker: the seeded PROMPTS cannot date a report (they are mandated
# ritual vocabulary from v0.6.0, so pre-scaffold reports carry them too), so
# the scaffold emits one literal only it can produce. checkup's ritual-bypass
# row scopes on exactly this string.
grep -qF '<!-- ohd:land-report-scaffold v0.7.0 -->' docs/campaigns/g1.md \
  || fail "--report did not emit the scaffold era marker"
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

# a genuine SECOND table using 'phase' as a column name — what a plan, status
# or measurement table looks like — is not a land report. Line-anchoring alone
# accepted it; the gate must refuse, and --report must still scaffold past it.
"$CS" new g7 >/dev/null
( cd "$TMP/wt/g7" && echo w > g7.txt && git add . && git commit -qm g7 )
printf '\n## plan\n| phase | what |\n|---|---|\n| 1 | design |\n' >> docs/campaigns/g7.md
if PATH="/usr/bin:/bin" "$CS" land g7 2>/dev/null; then fail "land accepted a plan table headed '| phase |'"; fi
git ls-remote --exit-code origin g7 >/dev/null 2>&1 && fail "land gate died AFTER pushing (g7)"
PATH="/usr/bin:/bin" "$CS" land g7 --report >/dev/null || fail "--report refused: plan-phase table read as an existing land report"
PATH="/usr/bin:/bin" "$CS" land g7 >/dev/null 2>&1 || fail "land refused despite a real land-report table (g7)"
"$CS" abort g7 --purge >/dev/null

# numbered heading dialects are in real field use, and their hand-written
# tables do not use the scaffold's columns — the heading test is what keeps
# them passing once the table test is anchored on the full scaffold header
"$CS" new g8 >/dev/null
( cd "$TMP/wt/g8" && echo w > g8.txt && git add . && git commit -qm g8 )
printf '\n## 13. Land report\n| phase | item | status |\n|---|---|---|\n| 0 | preconditions | yes |\n' >> docs/campaigns/g8.md
PATH="/usr/bin:/bin" "$CS" land g8 >/dev/null 2>&1 || fail "land refused a numbered '## 13. Land report' heading"
"$CS" abort g8 --purge >/dev/null

"$CS" new g9 >/dev/null
( cd "$TMP/wt/g9" && echo w > g9.txt && git add . && git commit -qm g9 )
printf '\n## 5. LAND REPORT\n| phase | state | evidence |\n' >> docs/campaigns/g9.md
PATH="/usr/bin:/bin" "$CS" land g9 >/dev/null 2>&1 || fail "land refused the uppercase numbered '## 5. LAND REPORT'"
"$CS" abort g9 --purge >/dev/null

# ERE trap guard: with '?' unescaped, 'ran?' makes the 'n' optional — it would
# match this garbage header and MISS every real one (g1 asserts the other half)
"$CS" new ga >/dev/null
( cd "$TMP/wt/ga" && echo w > ga.txt && git add . && git commit -qm ga )
printf '\n| phase | ra |\n' >> docs/campaigns/ga.md
if PATH="/usr/bin:/bin" "$CS" land ga 2>/dev/null; then fail "land accepted '| phase | ra |' — the '?' in 'ran?' lost its escape"; fi
"$CS" abort ga --purge >/dev/null

# C2 repo-debt line: report-only, and NEVER a wrong number when gh is absent
"$CS" new gb >/dev/null
( cd "$TMP/wt/gb" && echo w > gb.txt && git add . && git commit -qm gb )
PATH="/usr/bin:/bin" "$CS" land gb --report >/dev/null
out="$(PATH="/usr/bin:/bin" "$CS" land gb 2>&1)" || fail "gb land failed outright"
grep -q "repo debt: unverifiable" <<<"$out" || fail "no gh: debt line must say unverifiable, not a number"
# with gh present, the count is a set difference against the PR list — a
# squash-merged branch HAS a PR and must not be counted (ancestry counting
# would; that is the phantom-debt trap this leg pins)
mkdir -p "$TMP/fakebin"
printf '#!/bin/sh\nif [ "$1" = pr ] && [ "$2" = list ]; then echo gb-had-a-pr; else exit 0; fi\n' > "$TMP/fakebin/gh"
chmod +x "$TMP/fakebin/gh"
git update-ref refs/remotes/origin/gb-had-a-pr HEAD
git update-ref refs/remotes/origin/gb-never-offered HEAD
out="$(PATH="$TMP/fakebin:/usr/bin:/bin" "$CS" land gb 2>&1)" || fail "gb land with gh failed"
grep -qE "repo debt: [0-9]+ remote branch\(es\) never offered as a PR" <<<"$out" \
  || fail "debt line missing or malformed with gh present"
grep -q "repo debt: 0 " <<<"$out" && fail "debt count did not see gb-never-offered"
# a PR list that hit the fetch limit would silently inflate the count (every
# head whose PR fell off the end reads as never-offered) — must go unverifiable
printf '#!/bin/sh\nif [ "$1" = pr ] && [ "$2" = list ]; then i=0; while [ $i -lt 1000 ]; do echo "b$i"; i=$((i+1)); done; else exit 0; fi\n' > "$TMP/fakebin/gh"
chmod +x "$TMP/fakebin/gh"
out="$(PATH="$TMP/fakebin:/usr/bin:/bin" "$CS" land gb 2>&1)" || fail "gb land with truncated PR list failed"
grep -q "repo debt: unverifiable (PR list hit the 1000 fetch limit)" <<<"$out" \
  || fail "a truncated PR list produced a number instead of 'unverifiable'"
"$CS" abort gb --purge >/dev/null
git update-ref -d refs/remotes/origin/gb-had-a-pr
git update-ref -d refs/remotes/origin/gb-never-offered

# LAND_GUARD=0 bypass
"$CS" new g2 >/dev/null
( cd "$TMP/wt/g2" && echo w > g2.txt && git add . && git commit -qm g2 )
LAND_GUARD=0 PATH="/usr/bin:/bin" "$CS" land g2 >/dev/null 2>&1 || fail "LAND_GUARD=0 bypass failed"
"$CS" abort g2 --purge >/dev/null
echo "SMOKE PASS"
