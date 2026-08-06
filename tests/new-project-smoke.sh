#!/usr/bin/env bash
# new-project-smoke.sh — 3-profile round-trip of assets/new-project.sh. Network-free.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
NP="$HERE/assets/new-project.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "NP-SMOKE FAIL: $*" >&2; exit 1; }

export GIT_AUTHOR_NAME=smoke GIT_AUTHOR_EMAIL=smoke@test
export GIT_COMMITTER_NAME=smoke GIT_COMMITTER_EMAIL=smoke@test
export CAMPAIGN_WT_ROOT="$TMP/wt"

# ---------- profile 1: defaults + hook + non-main trunk ----------
P1="$TMP/p1"
"$NP" --name proj1 --dir "$P1" --trunk work --hook >/dev/null
cd "$P1"
[ "$(git branch --show-current)" = work ]            || fail "p1 trunk"
grep -q '{{' CLAUDE.md && fail "p1 tokens remain"
grep -q 'trunk-checkout root' CLAUDE.md               || fail "p1 anchor guidance missing"
grep -q 'CAMPAIGN_TRUNK:-work' tools/campaign.sh      || fail "p1 campaign.sh trunk subst"
grep -q 'CAMPAIGN_TRUNK:-work' tools/install-hooks.sh || fail "p1 install-hooks trunk subst"
[ -f pyproject.toml ] && [ -f .python-version ]       || fail "p1 uv stubs"
[ -f README.md ] && [ -f docs/campaigns/.gitkeep ] && [ -f .claude/skills/.gitkeep ] || fail "p1 structure"
grep -q '^/data$' .gitignore                          || fail "p1 gitignore anchor"
[ -x tools/campaign.sh ] && [ -x tools/install-hooks.sh ] || fail "p1 exec bits"

# ---------- the home-set: reference tier + archive (v0.6.0) ----------
# The scaffold is the ONLY carrier that reaches a project at birth, so every
# rule the tier depends on has to be IN the scaffolded text, not in a skill.
for f in capabilities conventions state; do
  [ -f "docs/reference/$f.md" ] || fail "p1 docs/reference/$f.md not scaffolded"
done
[ "$(ls docs/reference/*.md | wc -l)" -le 4 ] || fail "p1 reference tier over the 3-4 file cap"
[ -f docs/archive/README.md ] || fail "p1 docs/archive/README.md not scaffolded"
# format law, stated where the writer will read it
grep -q 'executable truth' docs/reference/capabilities.md || fail "p1 capabilities.md does not state the executable-truth format law"
grep -q 'executable truth' docs/reference/conventions.md  || fail "p1 conventions.md does not state the executable-truth format law"
# ...and DEMONSTRATED by every scaffold entry: `<claim> — <file:line>`
for f in capabilities conventions; do
  n_ex="$(grep -c '^- (example)' "docs/reference/$f.md" || true)"
  [ "$n_ex" -ge 2 ] || fail "p1 $f.md carries fewer than 2 placeholder entries"
  n_ptr="$(grep -c '^- (example).* — `[^`]*`$' "docs/reference/$f.md" || true)"
  [ "$n_ex" = "$n_ptr" ] || fail "p1 $f.md has placeholder entries that do not demonstrate '<claim> — <pointer>' ($n_ptr/$n_ex)"
done
# conventions.md carries BOTH named tables
grep -qi '^## Route map' docs/reference/conventions.md      || fail "p1 conventions.md missing the ROUTE MAP section"
grep -q 'assertion' docs/reference/conventions.md            || fail "p1 route map does not name the engagement assertion"
grep -qi '^## The writing router' docs/reference/conventions.md || fail "p1 conventions.md missing the writing router"
for home in 'docs/reference/' 'docs/superpowers/' 'state doc'; do
  grep -q "$home" docs/reference/conventions.md || fail "p1 writing router missing a home row for '$home'"
done
grep -qi 'new root-level document' docs/reference/conventions.md || fail "p1 writing router missing the new-root-doc attested-skip rule"
# state registry: the exemption and the two gates that replace it
grep -qi 'exempt' docs/reference/state.md   || fail "p1 state.md does not claim the executable-truth exemption"
grep -q '14' docs/reference/state.md        || fail "p1 state.md header carries no 14-day dated-claim expiry notice"
grep -q 'as of' docs/reference/state.md     || fail "p1 state.md does not demonstrate the dated-claim form"
# archive: the search-key preservation rule travels with the directory
grep -qi 'search key' docs/archive/README.md || fail "p1 archive README missing the search-key preservation rule"
grep -q 'checkup' docs/archive/README.md     || fail "p1 archive README does not name WHEN solidation runs"
# hot kernel gains exactly two pointer lines (S1b)
grep -q 'docs/reference/ first' CLAUDE.md            || fail "p1 CLAUDE.md hot kernel missing the orientation line"
grep -q 'router before creating' CLAUDE.md           || fail "p1 CLAUDE.md hot kernel missing the writing-router pointer"
[ "$(grep -c 'docs/reference/ first' CLAUDE.md)" = 1 ] || fail "p1 orientation line is not one line"
# a FRESH scaffold must be green: placeholders may not fabricate drift on day one
out="$(bash "$HERE/assets/checkup.sh" .)"
grep -q "reference | OK" <<<"$out" || fail "p1 fresh scaffold does not report reference | OK: $(grep '^reference' <<<"$out")"
# scaffold commit passed BEFORE hook activation
[ "$(git rev-list --count HEAD)" = 1 ]                || fail "p1 scaffold commit count"
# hook rejects a NEW non-docs file on trunk
echo x > code.py && git add code.py
if git commit -qm nope 2>/dev/null; then fail "p1 hook accepted non-docs commit"; fi
git reset -q && rm code.py
# campaign round-trip (needs origin)
git init -q --bare "$TMP/p1-origin.git"
git remote add origin "$TMP/p1-origin.git"
git push -q -u origin work
tools/campaign.sh new t1 >/dev/null
[ -d "$TMP/wt/t1" ] && [ -f docs/campaigns/t1.md ]    || fail "p1 campaign new"
tools/campaign.sh abort t1 >/dev/null
rm docs/campaigns/t1.md

# ---------- profile 2: full (fork host, multi env/node, data, deploy) ----------
P2="$TMP/p2"
mkdir -p "$TMP/data-src"
"$NP" --name proj2 --dir "$P2" --naming numbered --merge-model review-gate --no-hook \
  --host-name mylib --host-vehicle fork --host-repo "file://$TMP/host-origin.git" --host-trunk dev \
  --env build:conda --env extra:conda --env hpc:module@gpunode \
  --node gpunode:compute:gpu1 --node login:session --fs separate \
  --data-dir "$TMP/data-src" --deploy mirror >/dev/null
cd "$P2"
grep -q 'CAMPAIGN_NAMING:-numbered' tools/campaign.sh || fail "p2 naming subst"
grep -q 'CAMPAIGN_DEP_DIR:-../mylib' tools/campaign.sh || fail "p2 DEP_DIR"
grep -q 'CAMPAIGN_DEP_TRUNK:-dev' tools/campaign.sh    || fail "p2 DEP_TRUNK"
grep -q 'CAMPAIGN_PIN_FILE:-hosts/mylib/manifest' tools/campaign.sh || fail "p2 PIN_FILE"
[ -f environment.yml ] && [ -f envs/extra.yml ]        || fail "p2 conda stubs"
[ -f hosts/mylib/manifest ] && [ -x hosts/mylib/setup.sh ] || fail "p2 host files"
grep -q '^TRUNK=dev$' hosts/mylib/manifest             || fail "p2 manifest trunk"
grep -q '^PATCHES=' hosts/mylib/manifest && fail "p2 fork manifest kept PATCHES line"
grep -q '^PIN=$' hosts/mylib/manifest                  || fail "p2 manifest PIN"
[ -L data ]                                            || fail "p2 data symlink"
grep -q 'commit→push→pull' CLAUDE.md                   || fail "p2 git-only line"
grep -q 'deploy: mirror' CLAUDE.md                     || fail "p2 deploy fact"
grep -q 'gpunode' CLAUDE.md                             || fail "p2 matrix machine"
# numbered naming enforced by instantiated campaign.sh
git init -q --bare "$TMP/p2-origin.git"; git remote add origin "$TMP/p2-origin.git"; git push -q -u origin main
if tools/campaign.sh new badname 2>/dev/null; then fail "p2 numbered accepted bad name"; fi
# multi-uv / non-primary uv rejected
if "$NP" --name bad1 --dir "$TMP/bad1" --env a:conda --env b:uv 2>/dev/null; then fail "non-primary uv accepted"; fi
[ ! -e "$TMP/bad1" ] || fail "preflight-failed run left files"
# bad trunk rejected at preflight (no partial dir)
if "$NP" --name bad2 --dir "$TMP/bad2" --trunk "my branch" 2>/dev/null; then fail "bad trunk accepted"; fi
[ ! -e "$TMP/bad2" ] || fail "bad-trunk run left files"
# env type none: no stubs, recorded in matrix
"$NP" --name proj4 --dir "$TMP/p4" --env research:none >/dev/null
[ ! -f "$TMP/p4/pyproject.toml" ] && [ ! -f "$TMP/p4/environment.yml" ] || fail "none env produced stubs"
grep -q 'managed manually' "$TMP/p4/CLAUDE.md" || fail "none env not recorded"
# path-escaping env name rejected
if "$NP" --name bad3 --dir "$TMP/bad3" --env '../../oops:conda' 2>/dev/null; then fail "path-escape env accepted"; fi
[ ! -e "$TMP/bad3" ] || fail "bad-env run left files"
# scaffolded CLAUDE.md does not open with the template comment residue
head -1 "$P2/CLAUDE.md" | grep -q '^#' || fail "CLAUDE.md opens with residue, not the title"

# ---------- profile 3: patches host + live setup.sh first-run ----------
# seeded throwaway upstream (unseeded bare = unborn HEAD = no default branch)
git init -q --bare "$TMP/host-origin.git"
HW="$TMP/host-seed"; git clone -q "$TMP/host-origin.git" "$HW" 2>/dev/null
( cd "$HW" && git config user.email s@t && git config user.name s \
  && echo up > up.txt && git add . && git commit -qm up && git push -q origin HEAD:master )
P3="$TMP/p3"
"$NP" --name proj3 --dir "$P3" \
  --host-name plib --host-vehicle patches --host-repo "file://$TMP/host-origin.git" >/dev/null
cd "$P3"
grep -q '^PATCHES=$' hosts/plib/manifest               || fail "p3 manifest PATCHES"
grep -q '^TRUNK=' hosts/plib/manifest && fail "p3 patches manifest kept TRUNK line"
grep -q '^PIN=$' hosts/plib/manifest                   || fail "p3 manifest PIN"
[ -f hosts/plib/patches/.gitkeep ]                     || fail "p3 patches gitkeep"
grep -q 'CAMPAIGN_DEP_DIR:-}' tools/campaign.sh        || fail "p3 DEP_* should stay empty"
out="$(OHD_HOST_DIR="$TMP/plib-dest" hosts/plib/setup.sh)"
echo "$out" | grep -q 'PIN=.*in'                       || fail "p3 setup missing PIN guidance"
echo "$out" | grep -q 'skipping apply'                 || fail "p3 setup empty-patches skip"
[ -d "$TMP/plib-dest/.git" ]                           || fail "p3 setup clone missing"

echo "NP-SMOKE PASS"
