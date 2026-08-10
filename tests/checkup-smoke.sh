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

# 9g) C1 ritual-bypass sub-count, self-scoped on the scaffold's named-cell
#     prompts. A report with no prompts at all is PRE-v0.7.0 and excluded —
#     that exclusion is what stops every fork-lagged consumer false-flagging.
cat > docs/campaigns/nomarker.md <<'EOF'
# campaign: nomarker
- status: LANDED (2026-08-02)
- result / verdict: LANDS — merged
## land report
| phase | ran? | evidence |
|---|---|---|
| 4 docs same-land | yes | done |
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "^ritual-bypass" <<<"$out" && fail "a report with no scaffold prompts entered the bypass count"
# a scaffolded-but-unfilled report is the bypass signal
cat > docs/campaigns/bypassed.md <<'EOF'
# campaign: bypassed
- status: LANDED (2026-08-03)
- result / verdict: LANDS — merged
## land report
| phase | ran? | evidence |
|---|---|---|
| 4 docs same-land | yes | reference: |
| 6 distill + hygiene | yes | verification: |
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "ritual-bypass | 1 of 1" <<<"$out" || fail "named cells left at their bare prompts not counted"
grep -q "bypassed.md" <<<"$out"            || fail "bypass row does not name the doc"
# filling the cells (and adding sanity:) clears it
cat > docs/campaigns/bypassed.md <<'EOF'
# campaign: bypassed
- status: LANDED (2026-08-03)
- result / verdict: LANDS — merged
## land report
| phase | ran? | evidence |
|---|---|---|
| 4 docs same-land | yes | reference: nothing to graduate — one-line fix |
| 6 distill + hygiene | yes | sanity: no findings; verification: re-ran the suite, green |
EOF
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "ritual-bypass | OK" <<<"$out" || fail "filled named cells still counted as a bypass"
# a filled report that never names sanity: is still a bypass
sed -i 's/sanity: no findings; //' docs/campaigns/bypassed.md
out="$("$FAKE_ASSETS/checkup.sh" .)"
grep -q "ritual-bypass | 1 of 1" <<<"$out" || fail "missing 'sanity:' not counted as a bypass"
rm docs/campaigns/nomarker.md docs/campaigns/bypassed.md

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

echo "CHECKUP-SMOKE PASS"
