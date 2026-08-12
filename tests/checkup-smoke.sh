#!/usr/bin/env bash
# checkup-smoke.sh — drift detection + config-preserving sync round-trip.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CK="$HERE/assets/checkup.sh"
TPL="$HERE/assets/campaign.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "CHECKUP-SMOKE FAIL: $*" >&2; exit 1; }
# Every fixture repo gets a LOCAL identity at INIT time, not before its first
# commit: a CI runner has no global identity, so a commit without one dies
# rc=128 ("empty ident name") — a fixture defect wearing the costume of a test
# failure. Doing it at init keeps a later assertion that adds a commit safe.
newrepo() { mkdir -p "$1" && cd "$1" && git init -q \
  && git config user.email smoke@test && git config user.name smoke; }

newrepo "$TMP/proj"
mkdir -p tools

# fake an OLD instantiated copy: custom config value + custom var + drifted body line
sed 's/^TRUNK=.*/TRUNK="${CAMPAIGN_TRUNK:-master}"/' "$TPL" > tools/campaign.sh
sed -i 's/^WT_ROOT=/MY_CUSTOM="x"   # project-local\nWT_ROOT=/' tools/campaign.sh
sed -i 's/^wt_path() .*/wt_path() { echo "OLD_IMPL"; }/' tools/campaign.sh
sed -i '3a # instantiated 2026-01-01 for smoke' tools/campaign.sh
chmod +x tools/campaign.sh

# 1) drift detected
out="$("$CK" .)"; grep -q "campaign.sh | DRIFT" <<<"$out" || fail "expected DRIFT on mutated copy"

# 2) sync: body updated, config preserved, provenance stamped
"$CK" . --sync >/dev/null
grep -q 'CAMPAIGN_TRUNK:-master' tools/campaign.sh   || fail "sync lost project config value"
grep -q '^MY_CUSTOM="x"' tools/campaign.sh           || fail "sync lost project-only custom var"
grep -q 'OLD_IMPL' tools/campaign.sh                 && fail "sync kept drifted body line"
grep -q '^# instantiated 2026-01-01' tools/campaign.sh || fail "sync lost instantiated line"
grep -q '^# synced-from ohd v' tools/campaign.sh     || fail "sync missing synced-from stamp"
bash -n tools/campaign.sh                            || fail "synced script has syntax errors"
ls tools/campaign.sh.pre-sync.* >/dev/null 2>&1      || fail "sync left no pre-sync backup (issue #11)"
grep -q 'OLD_IMPL' tools/campaign.sh.pre-sync.*      || fail "pre-sync backup is not the pre-sync body"

# 3) post-sync: IN-SYNC (config differences must NOT count as drift)
out="$("$CK" .)"; grep -q "campaign.sh | IN-SYNC" <<<"$out" || fail "expected IN-SYNC after sync"

# 4) hook + state-dir + CLAUDE.md reporting
out="$("$CK" .)"; grep -q "trunk-hook | MISSING" <<<"$out" || fail "expected hook MISSING"
bash "$HERE/assets/install-hooks.sh" >/dev/null
out="$("$CK" .)"; grep -q "trunk-hook | INSTALLED" <<<"$out" || fail "expected hook INSTALLED"

# 4b) hook VERSION detection. Before v0.5.23 the check matched 'docs-only' — a
#     string every previously installed hook also carries — so any future hook
#     change reported as already installed and was never offered. A hook from an
#     older ohd (no stamp, or an older stamp) must read STALE, not INSTALLED.
HOOKF="$(git rev-parse --git-common-dir)/hooks/pre-commit"
grep -q '^# ohd-hook v' "$HOOKF" || fail "install-hooks.sh writes no version stamp"
grep -v '^# ohd-hook v' "$HOOKF" > "$HOOKF.tmp" && mv "$HOOKF.tmp" "$HOOKF" && chmod +x "$HOOKF"
out="$("$CK" .)"; grep -q "trunk-hook | STALE" <<<"$out" || fail "stamp-less ohd hook not reported STALE"
grep -q "install-hooks.sh" <<<"$out" || fail "STALE row does not offer the re-install"
sed -i '2i # ohd-hook v1' "$HOOKF"
out="$("$CK" .)"; grep -q "trunk-hook | STALE" <<<"$out" || fail "OLDER hook stamp not reported STALE"
bash "$HERE/assets/install-hooks.sh" >/dev/null
out="$("$CK" .)"; grep -q "trunk-hook | INSTALLED" <<<"$out" || fail "re-run of install-hooks did not restore INSTALLED"

# 4c) the REVERSE skew. Hooks live in the shared common git dir, so a sibling
#     worktree running a NEWER ohd installs a hook stamped ahead of what THIS
#     plugin ships. Comparing stamps by string inequality alone called that
#     STALE and offered install-hooks.sh — a DOWNGRADE. Direction matters:
#     HAVE > WANT is the plugin cache being stale, not the hook.
sed -i 's/^# ohd-hook v.*/# ohd-hook v99/' "$HOOKF"
out="$("$CK" .)"
grep -q "trunk-hook | STALE" <<<"$out" && fail "newer-than-shipped hook reported STALE (recommends a downgrade)"
grep -q "trunk-hook | AHEAD" <<<"$out" || fail "newer-than-shipped hook not reported AHEAD"
grep -q "re-run the plugin's assets/install-hooks.sh" <<<"$out" && fail "AHEAD row still offers the downgrading re-install"
grep -q "reload-plugins" <<<"$out" || fail "AHEAD row does not name the real fix (stale plugin cache)"
bash "$HERE/assets/install-hooks.sh" >/dev/null
out="$("$CK" .)"; grep -q "trunk-hook | INSTALLED" <<<"$out" || fail "install-hooks did not restore INSTALLED after the AHEAD fixture"

# a foreign pre-commit is still OTHER, not STALE (nothing of ours to upgrade)
printf '#!/usr/bin/env bash\nexit 0\n' > "$HOOKF"; chmod +x "$HOOKF"
out="$("$CK" .)"; grep -q "trunk-hook | OTHER" <<<"$out" || fail "foreign pre-commit misreported"
bash "$HERE/assets/install-hooks.sh" >/dev/null

out="$("$CK" .)"; grep -q "state-dir | MISSING" <<<"$out" || fail "expected state-dir MISSING"
mkdir -p docs/campaigns
out="$("$CK" .)"; grep -q "state-dir | PRESENT" <<<"$out" || fail "expected state-dir PRESENT"
out="$("$CK" .)"; grep -q "CLAUDE.md | MISSING" <<<"$out" || fail "expected CLAUDE.md MISSING"

# 5) config-ONLY template change must count as drift and sync must deliver it
#    (the config block is excluded from the body diff — keys are compared explicitly)
FAKE_ASSETS="$TMP/fakeplugin/assets"; mkdir -p "$FAKE_ASSETS" "$TMP/fakeplugin/.claude-plugin"
cp "$TPL" "$FAKE_ASSETS/campaign.sh"
cp "$HERE/assets/checkup.sh" "$FAKE_ASSETS/checkup.sh"; chmod +x "$FAKE_ASSETS/checkup.sh"
echo '{"version": "9.9.9"}' > "$TMP/fakeplugin/.claude-plugin/plugin.json"
sed -i 's/^PIN_FILE=/NEW_TPL_VAR="${CAMPAIGN_NEW_TPL_VAR:-}"  # added in a newer template\nPIN_FILE=/' "$FAKE_ASSETS/campaign.sh"
out="$("$FAKE_ASSETS/checkup.sh" .)"; grep -q "campaign.sh | DRIFT" <<<"$out" || fail "config-only template change not reported as DRIFT"
grep -q "NEW_TPL_VAR" <<<"$out"                                             || fail "drift detail does not name the new config var"
"$FAKE_ASSETS/checkup.sh" . --sync >/dev/null
grep -q '^NEW_TPL_VAR=' tools/campaign.sh    || fail "sync did not deliver the new template config var"
grep -q 'CAMPAIGN_TRUNK:-master' tools/campaign.sh || fail "new-var sync lost project config value"

# 6) --sync on an IN-SYNC copy is a no-op
before="$(sha256sum tools/campaign.sh)"
out="$("$FAKE_ASSETS/checkup.sh" . --sync)"
grep -q "campaign.sh | SYNCED" <<<"$out" && fail "sync rewrote an IN-SYNC copy"
[ "$before" = "$(sha256sum tools/campaign.sh)" ] || fail "IN-SYNC sync modified the file"

# 7) markerless project copy: sync must REFUSE, not silently revert config
grep -v '^# ──' tools/campaign.sh > tools/campaign.sh.tmp && mv tools/campaign.sh.tmp tools/campaign.sh
out="$("$FAKE_ASSETS/checkup.sh" . --sync)"
grep -q "campaign.sh | SYNC-REFUSED" <<<"$out" || fail "markerless copy not refused"
grep -q 'CAMPAIGN_TRUNK:-master' tools/campaign.sh || fail "refusal still mutated the file"

# 8) decoy '# ──' banner in the body must not truncate the config range
newrepo "$TMP/decoy" && mkdir tools
sed 's/^wt_path() .*/# ── section banner (decoy)\nwt_path() { echo x; }/' "$TPL" > tools/campaign.sh
out="$("$HERE/assets/checkup.sh" .)"; grep -q "campaign.sh | DRIFT" <<<"$out" || fail "decoy banner test setup wrong"
"$HERE/assets/checkup.sh" . --sync >/dev/null
grep -q '^TRUNK=' tools/campaign.sh || fail "decoy banner corrupted the config splice"
bash -n tools/campaign.sh || fail "decoy sync produced broken script"
cd "$TMP/proj"

# 9) land-report audit: landed doc without a table → GAPS; with table → OK; abandoned → ignored
cat > docs/campaigns/oldland.md <<'EOF'
# campaign: oldland
- status: LANDED (2026-07-20)
- result / verdict: LANDS — merged 2026-07-20
EOF
cat > docs/campaigns/aborted.md <<'EOF'
# campaign: aborted
- status: ABANDONED (2026-07-21)
- result / verdict: ABANDONED — superseded
EOF
cat > docs/campaigns/openplan.md <<'EOF'
# campaign: openplan
- status: OPEN (2026-07-22)
- result / verdict:

## plan
- [ ] probe stress test → result: inconclusive, next: sweep k
- [ ] check if this already LANDED upstream before redoing the work
EOF
cat > docs/campaigns/prose.md <<'EOF'
# campaign: prose
- status: LANDED (2026-07-23)
- goal: retries must not abort on transient errors
- result / verdict: LANDS — merged
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"; grep -q "land-reports | GAPS" <<<"$out" || fail "landed doc without table not flagged"
grep -q "prose.md" <<<"$out" || fail "incidental 'abort' prose wrongly exempted a landed doc"
rm docs/campaigns/prose.md
grep -q "oldland.md" <<<"$out"  || fail "GAPS detail missing the offending doc"
grep -q "aborted.md" <<<"$out" && fail "abandoned campaign wrongly flagged as land gap"
grep -q "openplan.md" <<<"$out" && fail "open campaign's plan-line 'result:' wrongly read as landed"
rm docs/campaigns/openplan.md

# 9b) decorated / translated verdict rows must be COUNTED, not silently skipped
#     (v0.5.20's anchoring made the audit under-report), and a decorated
#     abandonment must still be excluded. A plan bullet mentioning the table
#     header must not exempt a landed doc either.
cat > docs/campaigns/deco.md <<'EOF'
# campaign: deco
- status: LANDED (2026-07-24)
- **verdict**: LANDS — merged as PR #13
EOF
cat > docs/campaigns/korean.md <<'EOF'
# campaign: korean
- status: LANDED (2026-07-25)
- 결론: LANDS — PR #13 머지됨
EOF
cat > docs/campaigns/boxed.md <<'EOF'
# campaign: boxed
- status: LANDED (2026-07-26)
- [x] LANDED as PR #7
EOF
cat > docs/campaigns/decoabandon.md <<'EOF'
# campaign: decoabandon
- status: ABANDONED (2026-07-27)
- **verdict**: ABANDONED — superseded
EOF
cat > docs/campaigns/fakephase.md <<'EOF'
# campaign: fakephase
- status: LANDED (2026-07-28)
- result / verdict: LANDS — merged

## plan
- [ ] add a | phase | table later
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "deco.md" <<<"$out"       || fail "bold verdict row silently skipped by the land-report audit"
grep -q "korean.md" <<<"$out"     || fail "translated-label verdict row silently skipped by the audit"
grep -q "boxed.md" <<<"$out"      || fail "checkbox verdict row silently skipped by the audit"
grep -q "fakephase.md" <<<"$out"  || fail "plan bullet mentioning '| phase |' wrongly exempted a landed doc"
grep -q "decoabandon.md" <<<"$out" && fail "decorated ABANDONED row wrongly counted as a land gap"
rm docs/campaigns/deco.md docs/campaigns/korean.md docs/campaigns/boxed.md \
   docs/campaigns/decoabandon.md docs/campaigns/fakephase.md

# 9c) the AUDIT's own structural rules, on shapes that read like a verdict but
#     are not one: a bold PARAGRAPH is not a verdict row, an unchecked box is a
#     TODO, and a long non-ASCII label must still be seen under a C locale. The
#     abandon exclusion is checked on the same shapes so an ABANDONED doc never
#     becomes a "gap". campaign.sh's clean gate is NOT under test here — since
#     round 4 the two consumers have DIFFERENT rules (clean anchors on the
#     scaffold row), and clean's matrix lives in tests/campaign-smoke.sh.
cat > docs/campaigns/boldpara.md <<'EOF'
# campaign: boldpara
- status: OPEN (2026-07-20)
- result / verdict:

## log
**Verdict: L2 is validated.** an intermediate sub-conclusion, campaign still OPEN
EOF
cat > docs/campaigns/todobox.md <<'EOF'
# campaign: todobox
- status: OPEN (2026-07-20)
- result / verdict:

## plan
- [ ] TODO: LANDED upstream? check before redoing
- [ ] risk: ABANDONED approach may resurface
EOF
cat > docs/campaigns/longkorean.md <<'EOF'
# campaign: longkorean
- status: LANDED (2026-07-24)
- 결론결론결론결론: LANDS — PR #13 머지됨
EOF
cat > docs/campaigns/boxabandon.md <<'EOF'
# campaign: boxabandon
- status: ABANDONED (2026-07-24)
- [x] verdict: ABANDONED — superseded by another campaign
EOF
out="$(LC_ALL=C "$FAKE_ASSETS/checkup.sh" .)"
grep -q "boldpara.md" <<<"$out"   && fail "bold PARAGRAPH counted an OPEN campaign as landed"
grep -q "todobox.md" <<<"$out"    && fail "unchecked TODO box counted an OPEN campaign as landed"
grep -q "longkorean.md" <<<"$out" || fail "long non-ASCII label silently skipped by the audit under LC_ALL=C"
grep -q "boxabandon.md" <<<"$out" && fail "checkbox ABANDONED row wrongly counted as a land gap"
rm docs/campaigns/boldpara.md docs/campaigns/todobox.md docs/campaigns/longkorean.md \
   docs/campaigns/boxabandon.md

# 9d) A label whose value STARTS with the verdict word, with NO checkbox to
#     betray it as a plan item, IS reported. Deliberate, not an oversight:
#     '- TODO: LANDED upstream?' and '- status: LANDED (PR #12 merged)' are
#     lexically the same shape, and separating them needs a list of blessed
#     label words — the game v0.5.20/v0.5.21 lost twice. The AUDIT is allowed to
#     over-report because its output is a prompt to go look ("backfill honestly
#     or annotate"), and under-reporting is the silent skip this release exists
#     to remove. `campaign.sh clean` makes the opposite trade for the opposite
#     reason: it DESTROYS a worktree, so it anchors on the scaffold row instead
#     and refuses every row in this block.
cat > docs/campaigns/todonobox.md <<'EOF'
# campaign: todonobox
- status: OPEN (2026-07-20)
- result / verdict:

## plan
- TODO: LANDED upstream? check before redoing
EOF
cat > docs/campaigns/konobox.md <<'EOF'
# campaign: konobox
- status: OPEN (2026-07-20)
- result / verdict:

## plan
- 확인: LANDED 됐는지 먼저 보기
EOF
out="$(LC_ALL=C "$FAKE_ASSETS/checkup.sh" .)"
grep -q "todonobox.md" <<<"$out" \
  || fail "checkbox-free labelled verdict row stopped being audited (behavior change: pin or update 9d)"
grep -q "konobox.md" <<<"$out" \
  || fail "checkbox-free non-ASCII labelled row stopped being audited (behavior change: pin or update 9d)"
rm docs/campaigns/todonobox.md docs/campaigns/konobox.md

# 9e) required-accept matrix for the AUDIT. Every row here is a verdict line a
#     real state doc carries; the audit must RECOGNIZE all of them (that
#     recognition is v0.5.22's headline fix). These are the rows that no longer
#     authorize `campaign.sh clean` — the two consumers diverge here by design,
#     so this matrix is the audit's own contract and does not track clean's.
audit_sees() {   # <slug> <verdict row>
  # the dated scaffold line keeps the doc inside the audit's post-scaffold
  # scope; 'CLOSED' is deliberately verdict-neutral so the matrix still tests
  # the row under test and nothing else
  printf '# campaign: %s\n- status: CLOSED (2026-07-24)\n%s\n' "$1" "$2" > "docs/campaigns/m_$1.md"
  local out; out="$(LC_ALL=C "$FAKE_ASSETS/checkup.sh" .)"
  grep -q "m_$1.md" <<<"$out" || fail "audit no longer recognizes a legitimate verdict row: $2"
  rm "docs/campaigns/m_$1.md"
}
audit_sees a01 '- **verdict**: LANDS — merged as PR #13'
audit_sees a02 '- 결론: LANDS — PR #13 머지됨'
audit_sees a03 '- [x] LANDED as PR #7'
audit_sees a04 '- `verdict`: LANDS'
audit_sees a05 '- result / verdict: LANDS — ok'
audit_sees a06 '- LANDED as PR #7'
audit_sees a07 '  - result / verdict: LANDS'
audit_sees a08 '* result: LANDS'
audit_sees a09 '- [X] LANDED as PR #7'
audit_sees a10 '- [x] verdict: LANDS'
audit_sees a11 '- _verdict_: LANDS'
audit_sees a12 '- **LANDS** — ok'
audit_sees a13 '- status: LANDED (PR #12 merged)'
audit_sees a14 '- 결론결론결론결론: LANDS — PR #13 머지됨'
audit_sees a15 '- verdict: LANDED'

{ echo; grep -m1 '^| phase | ran? | evidence |$' "$FAKE_ASSETS/campaign.sh"; } >> docs/campaigns/oldland.md \
  || fail "producer table header not found in campaign.sh (scaffold/audit integration broken)" 
out="$("$FAKE_ASSETS/checkup.sh" .)"; grep -q "land-reports | OK" <<<"$out" || fail "expected land-reports OK after backfill"
grep -q "^— scope:" <<<"$out" || fail "scope footer missing from report"

# 9f) E5 scoping: a doc with no scaffold '- status: … (date)' line predates the
#     ritual entirely and must be EXCLUDED, not reported as a gap it could
#     never have filled. The dated line is the scoping key precisely because it
#     is neither mtime nor git-derived.
cat > docs/campaigns/prescaffold.md <<'EOF'
# campaign: prescaffold
- result / verdict: LANDS — merged long before the scaffold existed
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "prescaffold.md" <<<"$out" && fail "pre-scaffold doc reported as a land-report gap"
# ...but a dated one with the same shape IS in scope
cat > docs/campaigns/postscaffold.md <<'EOF'
# campaign: postscaffold
- status: LANDED (2026-08-01)
- result / verdict: LANDS — merged as PR #99
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "postscaffold.md" <<<"$out" || fail "dated post-scaffold doc wrongly excluded from the audit"
# A9: the remedy must name the PR merge date and warn off the doc's git log
grep -q "MERGE date" <<<"$out"        || fail "GAPS remedy does not name the PR merge date"
grep -q 'git log -1 -- <doc>' <<<"$out" || fail "GAPS remedy does not warn off the back-fill-skewed derivation"
rm docs/campaigns/prescaffold.md docs/campaigns/postscaffold.md

# 9g) C1 ritual-bypass sub-count, scoped by an EXPLICIT scaffold marker.
#     The named-cell TOKENS cannot date a report: `reference:`/`verification:`
#     are mandated ritual vocabulary from v0.6.0, so a pre-scaffold report
#     legitimately carries them (both real reports in this repo do, written
#     four days before the scaffold existed). No anchor position fixes that —
#     only a literal the scaffold alone emits can. Five cases:

# (i) THE REAL FORK-LAG SHAPE: a pre-v0.7.0 report with the tokens written
#     mid-cell, no marker, no `sanity:`. It is compliant for its era and MUST
#     NOT be counted — this is the regression token-scoping made reachable.
cat > docs/campaigns/forklag.md <<'EOF'
# campaign: forklag
- status: LANDED (2026-08-06)
- result / verdict: LANDS — merged as PR #40
## land report
| phase | ran? | evidence |
|---|---|---|
| 4 docs same-land | yes | CHANGELOG updated, backlog #9 closed; reference: nothing to graduate |
| 6 distill + hygiene | yes | memory distilled; verification: promoted to tests/test_x.py |
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "forklag.md" <<<"$out" && fail "(i) a pre-scaffold report with era-vocabulary tokens was counted as a bypass"
grep -q "ritual-bypass | 0 scaffolded" <<<"$out" || fail "(i) empty denominator not reported explicitly"

# (ii) marker present, cells still at their BARE PROMPTS → counted
cat > docs/campaigns/barescaffold.md <<'EOF'
# campaign: barescaffold
- status: LANDED (2026-08-11)
- result / verdict: LANDS — merged as PR #50
## land report
<!-- ohd:land-report-scaffold v0.7.0 -->
| phase | ran? | evidence |
|---|---|---|
| 4 docs same-land | yes | reference: |
| 6 distill + hygiene | yes | verification: |
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "ritual-bypass | 1 of 1" <<<"$out" || fail "(ii) a marked scaffold left at bare prompts was not counted"
grep -q "barescaffold.md" <<<"$out"        || fail "(ii) bypass row does not name the bare-prompt doc"
rm docs/campaigns/barescaffold.md

# (iii) marker present, cells FILLED mid-cell, `sanity:` absent → counted
cat > docs/campaigns/midcell.md <<'EOF'
# campaign: midcell
- status: LANDED (2026-08-11)
- result / verdict: LANDS — merged as PR #51
## land report
<!-- ohd:land-report-scaffold v0.7.0 -->
| phase | ran? | evidence |
|---|---|---|
| 4 docs same-land | yes | CHANGELOG updated; reference: nothing to graduate — one-liner |
| 6 distill + hygiene | yes | memory distilled; verification: promoted to tests/test_y.py |
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "ritual-bypass | 1 of 1" <<<"$out" || fail "(iii) a marked report with no sanity: was not counted"
grep -q "midcell.md" <<<"$out"             || fail "(iii) bypass row does not name the mid-cell doc"

# (iv) marker present, everything filled INCLUDING sanity: → OK, and counted
#      in the denominator
sed -i 's/memory distilled;/memory distilled; sanity: no findings;/' docs/campaigns/midcell.md
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "ritual-bypass | OK" <<<"$out"          || fail "(iv) a fully attested marked report was counted as a bypass"
grep -q "1 scaffold-written land report" <<<"$out" || fail "(iv) attested report missing from the denominator"

# (v) the content checks read the LAND-REPORT REGION, not the whole file: a
#     `sanity:` in unrelated prose elsewhere must not attest the land report
sed -i 's/ sanity: no findings;//' docs/campaigns/midcell.md
cat >> docs/campaigns/midcell.md <<'EOF'

## appendix
- sanity: this line is prose in a different section and attests nothing
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "ritual-bypass | 1 of 1" <<<"$out" || fail "(v) a sanity: outside the land-report section satisfied the check"
rm docs/campaigns/midcell.md docs/campaigns/forklag.md


# 10) plugin-cache staleness: versioned cache layout with a newer sibling → STALE
CACHE="$TMP/cache/ohd"; mkdir -p "$CACHE/1.0.0/assets" "$CACHE/1.0.0/.claude-plugin" "$CACHE/9.9.9"
cp "$TPL" "$CACHE/1.0.0/assets/campaign.sh"
cp "$HERE/assets/checkup.sh" "$CACHE/1.0.0/assets/checkup.sh"; chmod +x "$CACHE/1.0.0/assets/checkup.sh"
echo '{"version": "1.0.0"}' > "$CACHE/1.0.0/.claude-plugin/plugin.json"
out="$("$CACHE/1.0.0/assets/checkup.sh" .)"
grep -q "plugin-cache | STALE" <<<"$out" || fail "stale plugin cache not detected"
grep -q "v9.9.9 is installed" <<<"$out"  || fail "STALE detail missing the installed version"
rm -rf "$CACHE/9.9.9"
touch "$CACHE/8.8.8"    # stray FILE — not an installed version
out="$("$CACHE/1.0.0/assets/checkup.sh" .)"
grep -q "plugin-cache" <<<"$out" && fail "current cache wrongly reported stale (or stray file counted)"
CACHE2="$TMP/cache2/ohd"; mkdir -p "$CACHE2/0.5.9/assets" "$CACHE2/0.5.9/.claude-plugin" "$CACHE2/0.5.10"
cp "$TPL" "$CACHE2/0.5.9/assets/campaign.sh"
cp "$HERE/assets/checkup.sh" "$CACHE2/0.5.9/assets/checkup.sh"; chmod +x "$CACHE2/0.5.9/assets/checkup.sh"
echo '{"version": "0.5.9"}' > "$CACHE2/0.5.9/.claude-plugin/plugin.json"
out="$("$CACHE2/0.5.9/assets/checkup.sh" .)"
grep -q "v0.5.10 is installed" <<<"$out" || fail "semantic version ordering broken (0.5.10 must beat 0.5.9)"
ln -s "$CACHE2/0.5.9" "$CACHE2/latest"
out="$("$CACHE2/latest/assets/checkup.sh" .)"
grep -q "plugin-cache | STALE" <<<"$out" || fail "symlinked cache path defeated staleness detection"

# 11) adoption: empty repo bootstraps a fresh copy
newrepo "$TMP/fresh"
out="$("$CK" .)"; grep -q "campaign.sh | MISSING" <<<"$out" || fail "expected MISSING in fresh repo"
"$CK" . --sync >/dev/null
[ -x tools/campaign.sh ]                    || fail "bootstrap did not create executable copy"
diff <(grep -v '^# synced-from' tools/campaign.sh) "$TPL" >/dev/null || fail "bootstrap copy differs from template beyond the stamp"

# 12) harness-changes relay: BEHAVIOR-CHANGE markers between stamp and current, sort -V range
cd "$TMP/proj"
cat > "$TMP/fakeplugin/CHANGELOG.md" <<'EOF'
## v0.5.11 (2026-07-29)

BEHAVIOR-CHANGE: new gate eleven

- filler prose

## v0.5.10 (2026-07-28)

BEHAVIOR-CHANGE: new gate ten

## v0.5.2 (2026-07-28)

BEHAVIOR-CHANGE: old gate two

## v0.5.1 (2026-07-28)

- no marker here
EOF
echo '{"version": "0.5.11"}' > "$TMP/fakeplugin/.claude-plugin/plugin.json"
grep -q '^# synced-from ohd v' tools/campaign.sh || fail "scenario-12 precondition: no stamp to rewrite"
sed -i 's/^# synced-from ohd v[0-9.]*/# synced-from ohd v0.5.2/' tools/campaign.sh
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "harness-changes | REVIEW" <<<"$out"    || fail "behavior-change relay missing"
grep -q "\[v0.5.10\] new gate ten" <<<"$out"    || fail "v0.5.10 marker not relayed (lexical-sort regression?)"
grep -q "\[v0.5.11\] new gate eleven" <<<"$out" || fail "v0.5.11 marker not relayed"
grep -q "old gate two" <<<"$out" && fail "stamp-version marker wrongly relayed (range must exclude the stamp itself)"
sed -i 's/^# synced-from ohd v0.5.2/# synced-from ohd v9.9.9/' tools/campaign.sh
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "harness-changes | ANOMALY" <<<"$out" || fail "inverted stamp not flagged as ANOMALY"
grep -v '^# synced-from' tools/campaign.sh > t.tmp && mv t.tmp tools/campaign.sh && chmod +x tools/campaign.sh
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "harness-changes | NO-BASELINE" <<<"$out" || fail "missing stamp not reported as NO-BASELINE"

# 12b) E2 fork stamp — version-pinned acceptance of a deliberately divergent
#      copy. It suppresses the LINE-DIFF nag and nothing else.
# scenario 7 deliberately left this copy markerless — re-instantiate a clean
# one so the fork case is tested, not the markerless one
cp "$FAKE_ASSETS/campaign.sh" tools/campaign.sh && chmod +x tools/campaign.sh
sed -i '3a # synced-from ohd v0.5.2 (fork)' tools/campaign.sh
echo '# a deliberate local divergence' >> tools/campaign.sh
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "campaign.sh | FORK" <<<"$out"         || fail "fork stamp did not suppress the line-diff nag"
grep -q "differing line(s)" <<<"$out"          && fail "fork stamp still emitted the line-diff count"
grep -q "review and restamp" <<<"$out"         || fail "fork behind the running plugin was not asked to restamp"
# the stamp version must still be extractable THROUGH the '(fork)' suffix, or
# the relay silently stops for exactly the consumers most likely to be behind
grep -q "harness-changes | REVIEW" <<<"$out"   || fail "BEHAVIOR-CHANGE relay stopped at a (fork) stamp"
grep -q "\[v0.5.10\] new gate ten" <<<"$out"   || fail "fork stamp lost the relayed marker lines"
# a new template config key must OUTRANK the fork suppression
cp "$FAKE_ASSETS/campaign.sh" "$TMP/tpl.bak"
sed -i 's/^# ── config.*/&\nFORK_ERA_VAR="z"/' "$FAKE_ASSETS/campaign.sh"
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "campaign.sh | DRIFT" <<<"$out"        || fail "fork stamp swallowed a new template config var"
grep -q "FORK_ERA_VAR" <<<"$out"               || fail "new-key detail not named for a forked copy"
cp "$TMP/tpl.bak" "$FAKE_ASSETS/campaign.sh"
# --sync on a fork is a one-command fork-destroyer — it must REFUSE
out="$("$FAKE_ASSETS/checkup.sh" . --sync)"
grep -q "campaign.sh | FORK-REFUSED" <<<"$out" || fail "--sync did not refuse a (fork)-stamped copy"
grep -q '(fork)' tools/campaign.sh             || fail "--sync dropped the fork stamp"
grep -q 'a deliberate local divergence' tools/campaign.sh || fail "--sync overwrote the forked body"
# restamping at the running version clears the restamp prompt, keeps FORK
sed -i 's/^# synced-from ohd v.*/# synced-from ohd v0.5.11 (fork)/' tools/campaign.sh
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "campaign.sh | FORK" <<<"$out"         || fail "restamped fork lost its FORK status"
grep -q "review and restamp" <<<"$out"         && fail "restamped fork still asked to restamp"
# M1: a fork stamp on a body that MATCHES the template is IN-SYNC, and --sync
# there is a no-op — refusing would contradict the IN-SYNC row printed beside it
sed -i '/a deliberate local divergence/d' tools/campaign.sh
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "campaign.sh | IN-SYNC" <<<"$out"      || fail "fork stamp on a template-identical body is not IN-SYNC"
out="$("$FAKE_ASSETS/checkup.sh" . --sync)"
grep -q "FORK-REFUSED" <<<"$out"               && fail "--sync refused a fork stamp whose body already matches the template"
echo '# a deliberate local divergence' >> tools/campaign.sh
"$FAKE_ASSETS/checkup.sh" . --sync >/dev/null || true
sed -i '/a deliberate local divergence/d' tools/campaign.sh
"$HERE/assets/checkup.sh" . --sync >/dev/null || true

# 13) CHANGELOG header-format pin (the relay's parsing contract)
grep -E '^## v' "$HERE/CHANGELOG.md" | grep -vE '^## v[0-9]+\.[0-9]+\.[0-9]+ \([0-9]{4}-[0-9]{2}-[0-9]{2}\)$' \
  && fail "CHANGELOG header format drifted — harness-changes relay parsing depends on '## vX.Y.Z (date)'"

# 14) v0.6.0 DEFAULT rows — counts and gates only. Every one of these must be
#     cheap (no tree walks beyond the doc dirs) and none may propose work: the
#     default run is a drift doctor, not a nag. A fresh, honest project must
#     come out green, or the rows manufacture drift on day one.
R="$TMP/rows"; newrepo "$R"
mkdir -p docs/campaigns
today() { date +%F; }
days_ago() { date -d "$1 days ago" +%F 2>/dev/null || date -v-"$1"d +%F; }

# --- always-loaded: the byte budget over what EVERY actor-wake pays for ---
out="$("$CK" .)"
grep -q "always-loaded | NONE" <<<"$out" || fail "no CLAUDE.md: expected always-loaded NONE"
printf '# tiny\n' > CLAUDE.md
out="$("$CK" .)"
grep -q "always-loaded | OK" <<<"$out"    || fail "small CLAUDE.md not OK"
grep -q "20KB" <<<"$out"                  || fail "always-loaded row does not name the ~20KB hot target"
grep -q "CLAUDE.md only" <<<"$out"        || fail "always-loaded row does not SAY its scope is CLAUDE.md only"
head -c 30000 /dev/zero | tr '\0' 'x' > CLAUDE.md
out="$("$CK" .)"
grep -q "always-loaded | OVER" <<<"$out"  || fail "30KB CLAUDE.md not reported OVER"
# the 168KB-plan class escapes a CLAUDE.md-only budget: an explicit, mechanical
# marker (not prose matching) opts extra always-read files into the count
printf '# tiny\n<!-- ohd:always-loaded docs/plan.md -->\n' > CLAUDE.md
head -c 30000 /dev/zero | tr '\0' 'x' > docs/plan.md
out="$("$CK" .)"
grep -q "always-loaded | OVER" <<<"$out"  || fail "marker-listed plan file not counted into the budget"
grep -q "2 file(s)" <<<"$out"             || fail "always-loaded row does not name the file count"
printf '# tiny\n<!-- ohd:always-loaded docs/gone.md -->\n' > CLAUDE.md
out="$("$CK" .)"
grep -q "always-loaded | " <<<"$out"      || fail "marker naming a missing file crashed the row"
grep -q "docs/gone.md" <<<"$out"          || fail "unresolvable always-loaded marker entry not named"
# a path with a SPACE: the marker used to be word-split, so the one file became
# two nonexistent ones and its bytes left the budget entirely
head -c 30000 /dev/zero | tr '\0' 'x' > "docs/my plan.md"
printf '# tiny\n<!-- ohd:always-loaded docs/my plan.md -->\n' > CLAUDE.md
out="$("$CK" .)"
grep -q "always-loaded | OVER" <<<"$out"  || fail "marker path containing a space not counted (word-split?)"
grep -q "2 file(s)" <<<"$out"             || fail "spaced marker path not counted as one file"
# the space-separated multi-path form still works when no path contains a space,
# and a SECOND marker line is read too (only the first ever was)
printf 'a\n' > docs/a.md; printf 'b\n' > docs/b.md
printf '# tiny\n<!-- ohd:always-loaded docs/a.md docs/b.md -->\n' > CLAUDE.md
out="$("$CK" .)"
grep -q "3 file(s)" <<<"$out"             || fail "space-separated multi-path marker stopped resolving"
printf '# tiny\n<!-- ohd:always-loaded docs/a.md -->\n<!-- ohd:always-loaded docs/my plan.md -->\n' > CLAUDE.md
out="$("$CK" .)"
grep -q "3 file(s)" <<<"$out"             || fail "a second always-loaded marker is ignored"
printf '# tiny\n' > CLAUDE.md; rm -f docs/plan.md "docs/my plan.md" docs/a.md docs/b.md

# --- reference: existence + pointer resolution + dated-claim expiry ---
out="$("$CK" .)"
grep -q "reference | MISSING" <<<"$out"   || fail "absent docs/reference/ not reported MISSING"
mkdir -p docs/reference
# an EMPTY tier is not a healthy one: 'OK' there reads identically to a filled
# tier, so the count is what makes 0 visible
out="$("$CK" .)"
grep -q "reference | STALE" <<<"$out"     || fail "empty docs/reference/ reported as a healthy tier"
grep -q "0 file(s)" <<<"$out"             || fail "reference row does not report the file count"
cp "$HERE/assets/home-set/reference/"*.md docs/reference/
out="$("$CK" .)"
grep -q "reference | OK" <<<"$out"        || fail "scaffold placeholders must not fabricate drift"
grep -q "placeholder" <<<"$out"           || fail "reference row does not count the unreplaced placeholders"
# a REAL line whose pointer does not resolve is the rotted-catalog failure
echo '- the writer sorts rows by key — `src/nowhere.py:57`' >> docs/reference/conventions.md
out="$("$CK" .)"
grep -q "reference | STALE" <<<"$out"     || fail "dead pointer not reported STALE"
grep -q "src/nowhere.py" <<<"$out"        || fail "STALE detail does not name the dead pointer"
mkdir -p src && echo x > src/nowhere.py
out="$("$CK" .)"
grep -q "reference | OK" <<<"$out"        || fail "resolvable pointer still reported STALE"
# dated-claim expiry is state.md ONLY (the exempt file's substitute gate)
echo "- \"best\" = lowest loss, as of $(days_ago 30) — \`src/nowhere.py\`" >> docs/reference/state.md
out="$("$CK" .)"
grep -q "reference | STALE" <<<"$out"     || fail "30-day-old dated claim in state.md not flagged"
sed -i "s/as of $(days_ago 30)/as of $(days_ago 3)/" docs/reference/state.md
out="$("$CK" .)"
grep -q "reference | OK" <<<"$out"        || fail "3-day-old dated claim wrongly flagged (14-day gate)"
echo "- some capability, as of $(days_ago 90) — \`src/nowhere.py\`" >> docs/reference/capabilities.md
out="$("$CK" .)"
grep -q "reference | OK" <<<"$out"        || fail "dated-claim expiry wrongly applied outside state.md"
# the LAST line of a file with no trailing newline: `read` returns non-zero on it
# and the loop body never ran, so the final pointer of such a file went ungated
cp docs/reference/conventions.md "$TMP/conv.bak"
printf -- '- the last fact, unterminated — `src/gone_last.py`' >> docs/reference/conventions.md
out="$("$CK" .)"
grep -q "reference | STALE" <<<"$out"     || fail "dead pointer on an unterminated last line not gated"
grep -q "src/gone_last.py" <<<"$out"      || fail "STALE detail does not name the unterminated line's pointer"
cp "$TMP/conv.bak" docs/reference/conventions.md
# A7: adopters write pointers relative to the reference DOC, not the repo root
# — bare names and `../` shapes. Root-only resolution called both dead. The
# fresh scaffold is vacuously green on this (its bare names sit in ungated
# prose), so the regression needs adopter-shaped bullets to bite.
echo '- the state registry lives beside this — `state.md`' >> docs/reference/conventions.md
out="$("$CK" .)"
grep -q "reference | OK" <<<"$out"        || fail "bare-name pointer beside the reference doc read as dead"
mkdir -p docs/adr && echo x > docs/adr/0001.md
echo '- the decision record — `../adr/0001.md`' >> docs/reference/conventions.md
out="$("$CK" .)"
grep -q "reference | OK" <<<"$out"        || fail "../ pointer relative to the reference doc read as dead"
# try-both is permissive, NOT blind: a pointer dead under both must stay dead
echo '- nothing is here — `../adr/absent.md`' >> docs/reference/conventions.md
out="$("$CK" .)"
grep -q "reference | STALE" <<<"$out"     || fail "try-both resolution swallowed a genuinely dead pointer"
grep -q "adr/absent.md" <<<"$out"         || fail "STALE detail does not name the dead adopter-shaped pointer"
cp "$TMP/conv.bak" docs/reference/conventions.md

# --- the combined placeholder/pointer extractor (#33 A1, #35 A2, #36 A3) ---
# One battery, because the three fixes share one loop and a fix for any of them
# can break the others: every rule below is asserted in BOTH directions
# (counted / not counted, dead-flagged / not flagged).
cp docs/reference/conventions.md "$TMP/conv.a.bak"
# each case runs against the SAME base tier plus one appended line, so a case
# cannot inherit the previous one's line
refline() { cp "$TMP/conv.a.bak" docs/reference/conventions.md
  printf '%s\n' "$1" >> docs/reference/conventions.md; "$CK" .; }
phcount() { cat docs/reference/*.md | grep -c '(example)' || true; }

# A1 (#33): the placeholder count is about the TOKEN, not the line shape — the
# scaffold's own Route map table row is not a list item and went uncounted.
cp "$TMP/conv.a.bak" docs/reference/conventions.md
EXP="$(phcount)"
out="$("$CK" .)"
grep -q "$EXP placeholder line(s)" <<<"$out" || fail "A1: placeholder count != the (example) lines actually present (non-list lines invisible)"
# ...and the count is the (example) token, not a list-item census: a non-list
# line WITHOUT the token must not move it, a non-list line WITH it must.
out="$(refline '| filled row | routes | canonical | `src/nowhere.py` |')"
grep -q "$EXP placeholder line(s)" <<<"$out" || fail "A1: a filled (non-(example)) table row counted as a placeholder"
out="$(refline '| (example) conv | fused / loop | fused | `probes/engage_grep.sh` |')"
grep -q "$((EXP + 1)) placeholder line(s)" <<<"$out" || fail "A1: an (example) TABLE row still not counted"

# A2 (#35): the canonical CI declaration is a declaration, not an anchored
# claim — its natural reason names the command that replaced CI, in backticks.
out="$(refline '- ci: retired (2026-08-11 — Actions disabled at the repo level; verification is worktree-local `uv run pytest`) — this line is the canonical declaration and `campaign-land` Phase 0 quotes it verbatim.')"
grep -q "reference | OK" <<<"$out" || fail "A2: the ci-retired declaration line still parsed for pointers"
# ...exemption is the DECLARATION's, not a blanket one: an ordinary line in the
# same position with a dead path-shaped pointer must still flag.
out="$(refline '- the sync path is generated — `tools/gone_decl.py`')"
grep -q "reference | STALE" <<<"$out" || fail "A2: declaration exemption leaked onto ordinary lines"
grep -q "tools/gone_decl.py" <<<"$out" || fail "A2: STALE detail does not name the dead pointer"
# A2 shape rule: only PATH-SHAPED tokens are pointers (contains '/', or ends in
# an all-alpha dot-extension). Extensionless bare names go silent — fail-open,
# accepted — and a version string is not a path.
out="$(refline '- reviews run to convergence — the loop is `uv run pytest`, dispatched by `review-to-convergence`')"
grep -q "reference | OK" <<<"$out" || fail "A2: a backticked command/skill name read as a dead path"
out="$(refline '- the pin moved with the release — `v0.7.1`')"
grep -q "reference | OK" <<<"$out" || fail "A2: a version string read as a dead path"
# ...and the shape rule must not silence the shapes the tier actually uses:
out="$(refline '- the writer is generated — `tools/absent_shape.py`')"
grep -q "reference | STALE" <<<"$out" || fail "A2: shape rule silenced a dead slash-bearing path"
out="$(refline '- the registry lives beside this — `absent_shape.md`')"
grep -q "reference | STALE" <<<"$out" || fail "A2: shape rule silenced a dead bare name with an all-alpha extension"

# A3 (#36) cause 1: pytest node-ids. `path.py::test` is the format law's own
# canonical anchor shape and every one of them was reported dead.
out="$(refline '- the boot site stays unhelped — `src/nowhere.py::test_no_unhelped_boot_site`')"
grep -q "reference | OK" <<<"$out" || fail "A3: live pointer with a ::node-id suffix reported dead"
out="$(refline '- the boot site stays unhelped — `src/absent_node.py::test_x`')"
grep -q "reference | STALE" <<<"$out" || fail "A3: node-id strip swallowed a genuinely dead file"
grep -q "src/absent_node.py" <<<"$out" || fail "A3: STALE detail does not name the node-id pointer's FILE"
# A3 cause 2: one pointer per line was checked, so a companion pointer went
# unchecked — 21 of them across 12 lines in the motivating measurement.
out="$(refline '- rows are sorted by key — `src/nowhere.py:57`, cross-checked by `src/absent_second.py`')"
grep -q "reference | STALE" <<<"$out" || fail "A3: the SECOND pointer on a line is still unchecked"
grep -q "src/absent_second.py" <<<"$out" || fail "A3: STALE detail does not name the second pointer"
# ...pointer ZONE = the tail after the FIRST ' — ', so a rationale clause
# between two separators IS gated...
out="$(refline '- a fact — the rationale lives in `src/absent_mid.py` — `src/nowhere.py`')"
grep -q "reference | STALE" <<<"$out" || fail "A3: a pointer between the first and last separator went unchecked"
grep -q "src/absent_mid.py" <<<"$out" || fail "A3: STALE detail does not name the mid-zone pointer"
# ...and the CLAIM half is not: naming a removed file is what a gotcha line is
# FOR, and whole-line iteration would flag every one of them.
out="$(refline '- the `src/deleted_shim.py` fallback is gone — `src/nowhere.py`')"
grep -q "reference | OK" <<<"$out" || fail "A3: a claim-half token naming a removed file was flagged dead"
# A3 recommended: `#anchor` suffixes are part of the citation, not the path.
echo x > docs/backlog_fixture.md
out="$(refline '- the deviation is logged — `docs/backlog_fixture.md#17`')"
grep -q "reference | OK" <<<"$out" || fail "A3: an #anchor suffix made a live pointer read dead"
out="$(refline '- the deviation is logged — `docs/absent_anchor.md#17`')"
grep -q "reference | STALE" <<<"$out" || fail "A3: anchor strip swallowed a genuinely dead pointer"
rm -f docs/backlog_fixture.md
cp "$TMP/conv.a.bak" docs/reference/conventions.md

# --- campaigns: OPEN count vs verdict-filled count (the false-OPEN census) ---
cat > docs/campaigns/c1.md <<'EOF'
# campaign: c1
- status: OPEN (2026-07-20)
- result / verdict:
EOF
cat > docs/campaigns/c2.md <<'EOF'
# campaign: c2
- status: OPEN (2026-07-20)
- result / verdict: LANDS — merged as PR #4
EOF
cat > docs/campaigns/c3.md <<'EOF'
# campaign: c3
- status: LANDED (2026-07-24)
- result / verdict: LANDS — merged as PR #5
EOF
out="$("$CK" .)"
grep -qE "campaigns \| 2 open/3 total, 1 false-OPEN" <<<"$out" || fail "campaign census wrong: $(grep '^campaigns' <<<"$out")"
# every other row that proposes work names its remedy; this one closes the set
grep '^campaigns | ' <<<"$out" | grep -q 'campaign-land' \
  || fail "campaigns row detail carries no remedy pointer (its siblings all do)"

# what counts as a FILLED verdict, both directions. The strict `result / verdict`
# literal was wrong BOTH ways, field-verified: it missed decorated, translated
# and `status:`-labelled verdicts (undercount to 0), and it counted placeholder
# and PENDING text as filled — false positives the repair table then invites you
# to batch-close. Same rule feeds the solidation list and the structure summary.
rm -f docs/campaigns/*.md
census_says() {   # <expected false-OPEN count> <verdict row>
  printf '# campaign: x\n- status: OPEN (2026-07-20)\n%s\n' "$2" > docs/campaigns/x.md
  local o; o="$(LC_ALL=C "$CK" .)"
  grep -qE "campaigns \| 1 open/1 total, $1 false-OPEN" <<<"$o" \
    || fail "false-OPEN census wants $1 for [$2] — got: $(grep '^campaigns' <<<"$o")"
}

# MATCH — every shape a real verdict row is written in. The emphasis family is
# the one that shipped broken: a closing `**` sits BETWEEN the colon and the
# verdict word, and a rule that only skips spaces there stops dead. These forms
# are accepted by the land-report audit, so a shared rule that missed them was
# stricter than the rule it claims to mirror.
census_says 1 '- verdict: LANDS'
census_says 1 '- [x] **verdict:** LANDS — merged as PR #7'
census_says 1 '- **verdict**: LANDS'
census_says 1 '- _verdict:_ ABANDONED'
census_says 1 '- **result / verdict:** LANDS'
census_says 1 '- `verdict:` LANDS'
census_says 1 '- 결론: LANDS'
census_says 1 '- status: LANDED (PR #12 merged)'
census_says 1 '- [x] LANDED as PR #7'
census_says 1 '- result/verdict: LANDS — merged'
census_says 1 '- result / verdict: LANDS — merged as PR #4'
census_says 1 '- result / verdict: ABANDONED — superseded'

# NO MATCH — the not-yet forms, and the PROSE class. A verdict word is an
# ordinary English word: it appears in plan bullets, risk notes and running
# text. Counting those drives two destructive suggestions (batch-close the
# campaign, archive the doc) against a doc that is still live.
census_says 0 '- status: OPEN'
census_says 0 '- result / verdict: PENDING'
census_says 0 '- result / verdict: PENDING the GPU gate'
census_says 0 '- result / verdict: *(fill in after the gate)*'
census_says 0 '- result / verdict:'
census_says 0 '- landed: no'
census_says 0 '- lands: not yet'
census_says 0 '- plan: LANDS eventually if the gate goes green'
census_says 0 '- Aborted runs are retried by the scheduler'
census_says 0 '- note: LANDS?'
rm -f docs/campaigns/x.md

# the SAME rule drives the SOLIDATION list, so the prose class must not propose
# archiving a live campaign either (scoped to the solidation block: the
# land-report audit keeps its own tolerant rule and legitimately names the doc)
printf '# campaign: live\n- status: OPEN (2026-08-01)\n- result / verdict:\n\n## plan\n- plan: LANDS eventually if the gate goes green\n' > docs/campaigns/live.md
out="$("$CK" . --structure)"
sol="$(sed -n '/## solidation/,/Move at CHECKUP/p' <<<"$out")"
grep -q "live.md" <<<"$sol" && fail "a plan bullet made a LIVE campaign a solidation candidate"
grep -qE "campaigns \| 1 open/1 total, 0 false-OPEN" <<<"$out" \
  || fail "a plan bullet counted as a false-OPEN: $(grep '^campaigns' <<<"$out")"
rm -f docs/campaigns/live.md

# --- structure: ONE summary line, never action-proposing in default mode ---
out="$("$CK" .)"
grep -q "^structure | " <<<"$out"                    || fail "no structure summary row"
grep -q "run /ohd-checkup structure" <<<"$out"       || fail "structure row does not point at the mode"
[ "$(grep -c '^structure | ' <<<"$out")" = 1 ]       || fail "structure row is not exactly one line"
grep -qi "orphan" <<<"$out"        && fail "default mode leaked the structure work-list (orphan census)"
grep -qi "candidates:" <<<"$out"   && fail "default mode enumerated solidation candidates (action-proposing)"

# 15) STRUCTURE mode — the opt-in work-list generator. It GENERATES; execution
#     is ordinary project campaigns. R22 binds it: counts and byte sizes only.
S="$TMP/struct"; newrepo "$S"
mkdir -p docs/campaigns docs/archive docs/superpowers/plans docs/superpowers/specs bench tools scripts
cat > docs/campaigns/done1.md <<'EOF'
# campaign: done1
- status: LANDED (2026-07-24)
- result / verdict: LANDS — merged as PR #4
EOF
cat > docs/campaigns/open1.md <<'EOF'
# campaign: open1
- status: OPEN (2026-07-20)
- result / verdict:
- the nightly job runs bench/check_beta.sh
EOF
cat > docs/archive/old.md <<'EOF'
# campaign: old
- result / verdict: LANDS — merged long ago
EOF
printf '#!/bin/sh\necho a\n' > bench/verify_alpha.sh
printf '#!/bin/sh\necho b\n' > bench/check_beta.sh
printf '#!/bin/sh\necho h\n' > tools/helper.sh
printf '#!/bin/sh\necho s\n' > scripts/smoke_gamma.sh
echo p > docs/superpowers/plans/p1.md
echo s > docs/superpowers/specs/s1.md
git add -A && git commit -qm fixture

out="$("$CK" . --structure)"
# it is still a checkup: the drift rows come with it
grep -q "campaign.sh | " <<<"$out"          || fail "structure mode dropped the default drift rows"
# solidation candidates: verdict-filled and not already archived
grep -q "done1.md" <<<"$out"                || fail "verdict-filled doc not listed as a solidation candidate"
grep -q "open1.md" <<<"$out"                && fail "OPEN campaign listed as a solidation candidate"
grep -q "archive/old.md" <<<"$out"          && fail "already-archived doc listed as a solidation candidate"
# orphan-verification census: naming family + no inbound reference
grep -q "bench/verify_alpha.sh" <<<"$out"   || fail "orphan verifier not censused"
grep -q "scripts/smoke_gamma.sh" <<<"$out"  || fail "orphan verifier in scripts/ not censused"
grep -q "bench/check_beta.sh" <<<"$out"     && fail "verifier WITH an inbound reference censused as an orphan"
grep -q "tools/helper.sh" <<<"$out"         && fail "non-verification script censused (naming family ignored)"
# allowlist: a deliberate orphan stops being work, and stays counted
printf 'bench/verify_alpha.sh\n' > .ohd-orphan-allowlist
out="$("$CK" . --structure)"
grep -q "bench/verify_alpha.sh" <<<"$out"   && fail "allowlisted orphan still listed as work"
grep -q "1 allowlisted" <<<"$out"           || fail "allowlisted orphan not counted"
grep -q "scripts/smoke_gamma.sh" <<<"$out"  || fail "allowlist swallowed a non-allowlisted orphan"
rm .ohd-orphan-allowlist
# a BARE family name is the commonest real form and matched nothing: the pattern
# required a separator (check_x.sh), so `check.sh` and `verify.py` were invisible
printf '#!/bin/sh\necho c\n' > tools/check.sh
printf 'print("v")\n' > bench/verify.py
# ...and the inbound-reference test was a raw fixed string, so an unrelated file
# merely NAMING recheck_gate.py made the genuine orphan check_gate.py look
# referenced
printf 'print("g")\n' > tools/check_gate.py
printf '#!/bin/sh\n# nightly: python tools/recheck_gate.py --all\n' > scripts/runner.sh
git add -A && git commit -qm fixture-collisions
out="$("$CK" . --structure)"
grep -q "tools/check.sh" <<<"$out"          || fail "bare family name check.sh not censused"
grep -q "bench/verify.py" <<<"$out"         || fail "bare family name verify.py not censused"
grep -q "tools/check_gate.py" <<<"$out"     || fail "substring collision (recheck_gate.py) hid a genuine orphan"
grep -q "scripts/runner.sh" <<<"$out"       && fail "non-verification script censused (naming family ignored)"
git rm -q tools/check.sh bench/verify.py tools/check_gate.py scripts/runner.sh
git commit -qm fixture-collisions-undo
# corpus + histogram + adoption offer + self-application
out="$("$CK" . --structure)"
grep -qi "plans/specs corpus" <<<"$out"     || fail "no plans/specs corpus size"
grep -qi "doc-size histogram" <<<"$out"     || fail "no doc-size histogram"
grep -q "docs/reference/" <<<"$out"         || fail "no adoption offer when the reference tier is absent"
grep -qi "harness repo itself" <<<"$out"    || fail "census does not state it applies to the harness repo itself"
grep -qi "baseline" <<<"$out"               || fail "structure run banks no baselines for the re-count"
# R22: counts and byte sizes ONLY — no token estimates anywhere
grep -qiE "[0-9][^|]*tok(en)?s?\b" <<<"$out" && fail "structure output estimates tokens (R22-blocked)"
# C1 (#34) runner scope: tracked pytest-collectible files the configured runner
# never collects — the question the orphan census structurally cannot answer.
# Both directions on every rule: SILENT where pytest collects rootdir-wide,
# speaking only where a config narrows collection.
out="$("$CK" . --structure)"
grep -qi "runner scope" <<<"$out"                && fail "C1: row spoke on a project with NO pytest config (must be SILENT)"
mkdir -p core/tests tests
printf 'def test_a():\n    assert 1\n' > core/tests/test_colocated.py
printf 'def test_c():\n    assert 1\n' > core/tests/other_test.py
printf 'def test_b():\n    assert 1\n' > tests/test_in_scope.py
git add -A && git commit -qm fixture-runner-scope
# a config carrying the section but NO testpaths: pytest collects rootdir-wide,
# so everything is in scope and the row still has nothing to say
printf '[tool.pytest.ini_options]\naddopts = "-q"\n' > pyproject.toml
out="$("$CK" . --structure)"
grep -qi "runner scope" <<<"$out"                && fail "C1: row spoke when the config declares no testpaths (must be SILENT)"
# testpaths narrows collection, and the colocated dir stops being discovered —
# it still LOOKS discovered, which is the whole failure
printf '[tool.pytest.ini_options]\ntestpaths = ["tests"]\n' > pyproject.toml
out="$("$CK" . --structure)"
grep -qi "runner scope" <<<"$out"                || fail "C1: no runner-scope row when testpaths narrows collection"
grep -q "core/tests/test_colocated.py" <<<"$out" || fail "C1: never-collected colocated test not reported"
grep -q "core/tests/other_test.py" <<<"$out"     || fail "C1: the *_test.py naming form is not treated as a candidate"
grep -q "tests/test_in_scope.py" <<<"$out"       && fail "C1: a test INSIDE testpaths reported as out of scope"
grep -q "tools/helper.sh" <<<"$out"              && fail "C1: a shell check censused as a pytest candidate (VER_RE leaked in)"
# the simple MULTILINE array form parses, and widening testpaths silences it
printf '[tool.pytest.ini_options]\ntestpaths = [\n  "tests",\n  "core",\n]\n' > pyproject.toml
out="$("$CK" . --structure)"
grep -qi "runner scope" <<<"$out"                || fail "C1: row vanished instead of reporting zero"
grep -q "core/tests/test_colocated.py" <<<"$out" && fail "C1: the multiline testpaths array was not parsed"
rm pyproject.toml
# ini form, and SECTION SCOPING both ways: a testpaths under another tool's
# table is not pytest's
printf '[tool:other]\ntestpaths = tests\n' > setup.cfg
out="$("$CK" . --structure)"
grep -qi "runner scope" <<<"$out"                && fail "C1: testpaths under another tool's section read as pytest's"
printf '[tool:pytest]\ntestpaths = tests\n' > setup.cfg
out="$("$CK" . --structure)"
grep -q "core/tests/test_colocated.py" <<<"$out" || fail "C1: ini-form [tool:pytest] testpaths not parsed"
# key present but nothing literal extractable: MANUAL-CHECK naming the file —
# a parser that guesses here prints a confident wrong answer
printf '[tool:pytest]\ntestpaths =\n' > setup.cfg
out="$("$CK" . --structure)"
grep -q "MANUAL-CHECK" <<<"$out"                 || fail "C1: unparseable testpaths did not raise MANUAL-CHECK"
grep -q "setup.cfg" <<<"$out"                    || fail "C1: MANUAL-CHECK does not name the config file"
rm setup.cfg
# the census's own scope note must SAY it cannot answer this
out="$("$CK" . --structure)"
grep -qi "runner-scope row" <<<"$out"            || fail "C1: the orphan-census scope note does not cross-reference this row"
git rm -rq core tests && git commit -qm fixture-runner-scope-undo

# C5 state-claim staleness: opt-in only, listed with NO dating, and the
# reference tier is excluded (its own expiry gate already covers state.md)
mkdir -p docs/reference
cat > docs/roadmap-fixture.md <<'EOF'
# roadmap
- stage 4 is NOT landed (LAND owed) on the integration branch
- stage 5 is pending review
EOF
cat > docs/reference/state.md <<'EOF'
# state
- the nightly job is pending a rewrite, as of 2026-08-01 — `docs/roadmap-fixture.md`
EOF
git add -A docs && git commit -qm fixture-c5
out="$("$CK" . --structure)"
grep -qi "state-claim staleness" <<<"$out"     || fail "structure mode has no state-claim staleness section"
grep -q "roadmap-fixture.md" <<<"$out"         || fail "state claim outside the reference tier not listed"
grep -q "NOT landed" <<<"$out"                 || fail "the matched claim line is not shown"
grep -qE "state-claim staleness" <<<"$out" && \
  { grep -A3 "state-claim staleness" <<<"$out" | grep -qiE "days? (old|ago)|mtime|last (touched|modified)" \
    && fail "C5 dated the candidates — mtime/git-log dating re-imports the back-fill skew"; }
grep -q "docs/reference/state.md:" <<<"$out"   && fail "reference tier not excluded from the staleness list"
# A8: the executed work-list is a deliverable and says so
grep -qi "review-to-convergence" <<<"$out"     || fail "structure footer does not route the executed list to r2c"
grep -qi "deliverable" <<<"$out"               || fail "structure footer does not call the executed list a deliverable"
# still opt-in: the default run must not carry any of it
out="$("$CK" .)"
grep -qi "state-claim staleness" <<<"$out"     && fail "default mode ran the staleness listing"

# and the DEFAULT run never carries the work-list
#     (done1.md legitimately appears in the pre-existing land-report row; what
#     must NOT appear is any part of the work-list itself)
out="$("$CK" .)"
grep -q "verify_alpha.sh" <<<"$out"         && fail "default mode leaked the orphan census"
grep -q "## solidation" <<<"$out"           && fail "default mode enumerated solidation candidates"
grep -q "structure work-list" <<<"$out"     && fail "default mode ran the work-list generator"
grep -q "^structure | " <<<"$out"           || fail "default mode lost its one-line structure pointer"

# 16) CI-coherence row (issue #31). REPORT-ONLY and exit-0 under every path,
#     which is the contract the row is most likely to break: it is the only
#     network call this script makes.
#     The `gh` here is a STUB whose output shapes were measured from gh 2.90.0
#     against a real repository (404 body + stderr line, `[]` rulesets, the
#     workflow-list JSON). A stub proves the BRANCHING — which signal
#     combination produces which verdict — and deliberately does not claim to
#     verify the API contract; the live run for that is recorded in the
#     campaign's land report.
mkdir -p "$TMP/bin" "$TMP/empty-bin"
cat > "$TMP/bin/gh" <<'GHSTUB'
#!/usr/bin/env bash
# stub gh — driven by STUB_* env vars; shapes copied from real gh output.
# ARG-AWARE and BRANCH-AWARE deliberately: a stub that answers every call shape
# identically cannot witness the older-gh fallback, a path-encoding bug, or a
# failed call, because to it those are the same call.
BR="${STUB_BR:-main}"
case "$1" in
  "repo")
    if [ "${STUB_AUTH:-ok}" = dead ]; then
      printf 'gh: To get started with GitHub CLI, please run: gh auth login\n' >&2
      exit 4
    fi
    printf 'acme/widget %s\n' "$BR"; exit 0 ;;
  "workflow")
    if printf '%s ' "$@" | grep -q -- '--json'; then
      if [ "${STUB_WF_NOJSON:-0}" = 1 ]; then
        printf 'unknown flag: --json\n' >&2; exit 1   # an older gh
      fi
      printf '%s\n' "${STUB_WF:-[]}"
    else
      # real `gh workflow list` without --all prints ACTIVE rows only, as TSV
      printf '%s' "${STUB_WF:-[]}" \
        | grep -o '"name":"[^"]*","state":"active"' \
        | sed 's/"name":"\([^"]*\)".*/\1\tactive\t1/'
    fi
    exit 0 ;;
  "api")
    # A branch name containing '/' must arrive PERCENT-ENCODED. Unencoded it
    # addresses a different path, and GitHub answers 404 "Branch not found" —
    # a body that is NOT "Branch not protected" and must not be read as one.
    case "$BR" in
      */*)
        enc="$(printf '%s' "$BR" | sed 's|/|%2F|g')"
        case "$2" in
          *"$enc"*) : ;;
          *) printf '%s' '{"message":"Branch not found","status":"404"}'
             printf 'gh: Branch not found (HTTP 404)\n' >&2; exit 1 ;;
        esac ;;
    esac
    case "$2" in
      */protection)
        if [ "${STUB_BRANCH_GONE:-0}" = 1 ]; then
          # the branch `gh repo view` named is not there any more (renamed, or
          # a race). A 404 whose body is "Branch not found", NOT "not protected".
          printf '%s' '{"message":"Branch not found","status":"404"}'
          printf 'gh: Branch not found (HTTP 404)\n' >&2; exit 1
        fi
        case "${STUB_PROT:-404}" in
          404) printf '%s' '{"message":"Branch not protected","status":"404"}'
               printf 'gh: Branch not protected (HTTP 404)\n' >&2; exit 1 ;;
          403) printf '%s' '{"message":"Resource not accessible","status":"403"}'
               printf 'gh: Resource not accessible (HTTP 403)\n' >&2; exit 1 ;;
          none) printf '%s' '{"required_status_checks":{"strict":false,"contexts":[]}}'; exit 0 ;;
          *)    printf '%s' '{"required_status_checks":{"strict":false,"contexts":["tests"]}}'; exit 0 ;;
        esac ;;
      */rules/*)
        if [ "${STUB_RULES_FAIL:-0}" = 1 ]; then
          # what a timeout kill or a network blip looks like: no body, non-zero
          printf 'gh: connection timed out\n' >&2; exit 1
        fi
        printf '%s\n' "${STUB_RULES:-[]}"; exit 0 ;;
    esac ;;
esac
exit 0
GHSTUB
chmod +x "$TMP/bin/gh"
WF_ACTIVE='[{"name":"tests","state":"active"}]'
WF_OFF='[{"name":"tests","state":"disabled_manually"}]'
RULES_CHK='[{"type":"required_status_checks","parameters":{"required_status_checks":[{"context":"tests"}]}}]'
DECL='- ci: retired (2026-08-11 — owner directive; release gate is the local suite)'

newrepo "$TMP/ci"
git remote add origin https://github.com/acme/widget.git

ci_run() {  # $1=expected status (or ABSENT); runs with the stub gh on PATH
  local want="$1" out rc
  set +e
  out="$(PATH="$TMP/bin:$PATH" "$CK" . 2>&1)"; rc=$?
  set -e
  [ "$rc" = 0 ] || fail "ci-coherence path '$want' broke checkup's exit-0 contract (rc=$rc)"
  if [ "$want" = ABSENT ]; then
    grep -q "^ci-coherence | " <<<"$out" && fail "ci-coherence row fired with nothing to be coherent about"
  else
    grep -q "^ci-coherence | $want" <<<"$out" \
      || fail "expected ci-coherence $want, got: $(grep '^ci-coherence' <<<"$out" || echo '(no row)')"
  fi
  printf '%s' "$out"
}

# 16a) neither declaration nor workflows dir → NO ROW (silence by scope)
ci_run ABSENT >/dev/null

# 16b) workflows present, no declaration, unprotected branch, no rulesets →
#      CONSISTENT (CI simply in use — this is the plugin repo's own pre-state)
mkdir -p .github/workflows && printf 'name: t\n' > .github/workflows/test.yml
out="$(STUB_WF="$WF_ACTIVE" ci_run CONSISTENT)"
grep -q "1 active workflow" <<<"$out" || fail "consistent row does not say what it measured"

# 16c) gh ABSENT → MANUAL-CHECK, never silence and never a failure.
#      Blanking PATH would take git with it and test nothing, so build a PATH
#      that drops ONLY gh: any directory providing a gh is replaced by a shim
#      holding symlinks to everything in it EXCEPT gh (gh and git share a
#      directory on plenty of machines).
NOGH="$TMP/nogh"; mkdir -p "$NOGH"; NOGH_PATH=""
IFS=: read -ra PATH_DIRS <<< "$PATH"
for d in "${PATH_DIRS[@]}"; do
  [ -n "$d" ] && [ -d "$d" ] || continue
  if [ -x "$d/gh" ]; then
    for e in "$d"/*; do
      [ -e "$e" ] && [ "$(basename "$e")" != gh ] || continue
      ln -sf "$e" "$NOGH/" 2>/dev/null || true
    done
  else
    NOGH_PATH="${NOGH_PATH:+$NOGH_PATH:}$d"
  fi
done
NOGH_PATH="$NOGH:$NOGH_PATH"
PATH="$NOGH_PATH" command -v gh >/dev/null 2>&1 && fail "gh-absent fixture still resolves gh"
PATH="$NOGH_PATH" command -v git >/dev/null 2>&1 || fail "gh-absent fixture lost git (fixture defect, not a checkup bug)"
set +e
out="$(PATH="$NOGH_PATH" "$CK" . 2>&1)"; rc=$?
set -e
[ "$rc" = 0 ] || fail "gh-absent path broke exit 0 (rc=$rc)"
grep -q "^ci-coherence | MANUAL-CHECK" <<<"$out" || fail "gh absent did not report MANUAL-CHECK"
grep -q "gh CLI not installed" <<<"$out" || fail "MANUAL-CHECK row does not say WHY it could not read"

# 16d) non-GitHub origin → MANUAL-CHECK (this row only knows GitHub)
git remote set-url origin git@internal-host:team/proj.git
out="$(STUB_WF="$WF_ACTIVE" ci_run MANUAL-CHECK)"
grep -qi "not a GitHub remote" <<<"$out" || fail "non-GitHub origin gave the wrong MANUAL-CHECK reason"
git remote set-url origin https://github.com/acme/widget.git

# 16e) declaration + a workflow still ACTIVE → DRIFT, carrying the #31 remedy.
#      The declaration is read from CLAUDE.md here...
printf '# proj\n\n## Facts\n\n%s\n' "$DECL" > CLAUDE.md
out="$(STUB_WF="$WF_ACTIVE" ci_run DRIFT)"
grep -q "workflow disable" <<<"$out"  || fail "DRIFT row carries no retirement checklist"
grep -q "ci: retired (2026-08-11" <<<"$out" || fail "DRIFT row does not cite the declaration it contradicts"
# ...and the whole declaration, not a truncated prefix: both consumers quote the
# MATCHED LINE, so a declaration that wraps cites itself half-said (found by
# dogfooding this row on the plugin's own CLAUDE.md)
grep -q "release gate is the local suite)" <<<"$out" || fail "DRIFT row truncated the declaration it quotes"
# the row must name the half that is ACTUALLY left over. Nothing is bound here,
# so claiming a blocked merge would be a false alarm in the commonest shape.
grep -qi "blocks every merge" <<<"$out" && fail "DRIFT row claims a blocking check with none bound"
grep -qi "runs on every push" <<<"$out" || fail "DRIFT row does not name the active-workflow half"

# 16f) ...and from docs/reference/conventions.md — EITHER file counts (1a)
rm CLAUDE.md && mkdir -p docs/reference
printf '# conventions\n\n%s\n' "$DECL" > docs/reference/conventions.md
STUB_WF="$WF_ACTIVE" ci_run DRIFT >/dev/null

# 16g) declaration + everything off → CONSISTENT
out="$(STUB_WF="$WF_OFF" ci_run CONSISTENT)"
grep -q "0 active workflow" <<<"$out" || fail "consistent-with-declaration row miscounted disabled workflows"

# 16h) declaration + workflows off but a required check STILL BOUND via branch
#      protection → DRIFT. This is the half-retirement that made every land
#      reach for --admin (issue #31).
out="$(STUB_WF="$WF_OFF" STUB_PROT=200 ci_run DRIFT)"
grep -q "required check" <<<"$out" || fail "protection-bound check not counted"
grep -qi "blocks every merge" <<<"$out" || fail "DRIFT row does not name the blocked-merge consequence when a check IS bound"
grep -qi "runs on every push" <<<"$out" && fail "DRIFT row claims an active workflow with none active"

# 16i) the RULESETS half is load-bearing, not redundant: nothing runs, branch
#      protection is 404-clean, and the block lives in a ruleset. Reading only
#      the protection endpoint calls this repo retired-and-clean.
rm -rf docs/reference
out="$(STUB_WF="$WF_OFF" STUB_RULES="$RULES_CHK" ci_run DRIFT)"
grep -qi "reverse half-retirement" <<<"$out" || fail "ruleset-bound check with no declaration not caught"
grep -q "rulesets" <<<"$out" || fail "DRIFT row does not name the ruleset as the source"

# 16j) 403 on the protection half → MANUAL-CHECK for that half only, and the
#      row must SAY it is not a coherence verdict rather than implying one
out="$(STUB_WF="$WF_OFF" STUB_PROT=403 ci_run MANUAL-CHECK)"
grep -q "403" <<<"$out" || fail "403 row does not name the status it hit"
grep -qi "not a coherence verdict" <<<"$out" || fail "403 row overstates what it knows"

# 16k) the RULESETS half must be able to say it is BLIND. A timeout kill or a
#      network blip returns nothing, which is byte-identical to a genuine `[]`
#      — so an unflagged failure reads as "no checks bound" and the row calls a
#      possibly half-retired repo CONSISTENT. The protection half already
#      degrades to MANUAL-CHECK; this half must mirror it.
out="$(STUB_WF="$WF_OFF" STUB_RULES_FAIL=1 ci_run MANUAL-CHECK)"
grep -qi "ruleset" <<<"$out" || fail "blind rulesets half is not named in the row"
grep -qi "not a coherence verdict" <<<"$out" || fail "blind-rulesets row overstates what it knows"

# 16l) a default branch containing '/' (`feat/x`) must be percent-encoded into
#      the API path. Unencoded it addresses a different path and GitHub answers
#      404 "Branch not found" — which the protection arm would otherwise read as
#      "Branch not protected", i.e. coherent-empty. A repo whose default branch
#      has a slash would silently never have its required checks read.
out="$(STUB_BR=feat/x STUB_WF="$WF_OFF" STUB_PROT=200 ci_run DRIFT)"
grep -qi "reverse half-retirement" <<<"$out" || fail "slash-named default branch: required checks went unread"

# 16m) the RULES call needs that encoding independently of the protection call
#       — they are two separate interpolations, and the case above would still
#       pass if only the first were fixed. Here the block lives ONLY in a
#       ruleset: encoded, the row sees it and reports DRIFT via rulesets;
#       unencoded, the call 404s, the half goes blind, and the row degrades to
#       MANUAL-CHECK. Discriminating in both directions is the point.
out="$(STUB_BR=feat/x STUB_WF="$WF_OFF" STUB_RULES="$RULES_CHK" ci_run DRIFT)"
grep -q "via rulesets" <<<"$out" || fail "slash-named default branch: the ruleset-bound check went unread"

# 16n) "Branch not found" is a FAILED read, not an empty protection set. Both
#      are 404s, so the arm order matters: read as "not protected" it reports a
#      repo whose checks were never read as coherent-empty.
out="$(STUB_WF="$WF_OFF" STUB_BRANCH_GONE=1 ci_run MANUAL-CHECK)"
grep -qi "could not resolve the branch" <<<"$out" || fail "'Branch not found' was read as 'not protected'"

# 16o) auth dead → MANUAL-CHECK. The third named degradation had no coverage.
out="$(STUB_AUTH=dead STUB_WF="$WF_ACTIVE" ci_run MANUAL-CHECK)"
grep -qi "could not read this repository" <<<"$out" || fail "dead auth gave the wrong MANUAL-CHECK reason"

# 16p) an older gh without `--json` on `workflow list`: the fallback path must
#      execute and reach the same count, or the fallback is decoration.
out="$(STUB_WF="$WF_ACTIVE" STUB_WF_NOJSON=1 ci_run CONSISTENT)"
grep -q "1 active workflow" <<<"$out" || fail "older-gh fallback miscounted active workflows"

# 16q) declaration present but NO workflows dir → the row still fires (the
#      declaration alone is a reason to check) and reads CONSISTENT
rm -rf .github
printf '# proj\n\n%s\n' "$DECL" > CLAUDE.md
STUB_WF="$WF_OFF" ci_run CONSISTENT >/dev/null
cd "$TMP/proj"

# 17) the `ci: retired` declaration is a LOCK-STEP across three surfaces, and
#     nothing but a test holds it: campaign-land Phase 0 greps it as prose (no
#     script reads that skill), checkup.sh greps it in code, and this repo
#     declares it about itself. A regex changed in one place and not the others
#     fails SILENTLY — Phase 0 simply stops finding declarations and every land
#     quietly falls back to a different branch.
CI_RE='\^\[\[:space:\]\]\*-\[\[:space:\]\]\*ci:\[\[:space:\]\]\*retired'
grep -qE "$CI_RE" "$HERE/assets/checkup.sh" \
  || fail "checkup.sh no longer greps the canonical ci-retired form"
grep -qE "$CI_RE" "$HERE/skills/campaign-land/SKILL.md" \
  || fail "campaign-land Phase 0 documents a DIFFERENT ci-retired grep than checkup.sh runs"
for f in "$HERE/assets/checkup.sh" "$HERE/skills/campaign-land/SKILL.md"; do
  grep -q 'docs/reference/conventions.md' "$f" || fail "$(basename "$f") lost the second declaration location (1a: either file counts)"
done
# ...and the plugin's own declaration must satisfy the form it publishes. It
# must also be ONE physical line: both consumers quote the MATCHED LINE, so a
# wrapped declaration cites itself truncated (measured, 2026-08-11).
OWN="$(grep -E '^[[:space:]]*-[[:space:]]*ci:[[:space:]]*retired' "$HERE/CLAUDE.md" || true)"
[ -n "$OWN" ] || fail "this repo declares CI retired nowhere its own Phase 0 can find it"
[ "$(printf '%s\n' "$OWN" | wc -l | tr -d ' ')" = 1 ] || fail "more than one ci-retired declaration"
case "$OWN" in
  *')') : ;;
  *) fail "the declaration does not end in ')' — it wrapped, and both consumers will quote it truncated: $OWN" ;;
esac

echo "CHECKUP-SMOKE PASS"
