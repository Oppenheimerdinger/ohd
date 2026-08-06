#!/usr/bin/env bash
# checkup-smoke.sh — drift detection + config-preserving sync round-trip.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CK="$HERE/assets/checkup.sh"
TPL="$HERE/assets/campaign.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "CHECKUP-SMOKE FAIL: $*" >&2; exit 1; }

mkdir -p "$TMP/proj" && cd "$TMP/proj" && git init -q
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
mkdir -p "$TMP/decoy" && cd "$TMP/decoy" && git init -q && mkdir tools
sed 's/^wt_path() .*/# ── section banner (decoy)\nwt_path() { echo x; }/' "$TPL" > tools/campaign.sh
out="$("$HERE/assets/checkup.sh" .)"; grep -q "campaign.sh | DRIFT" <<<"$out" || fail "decoy banner test setup wrong"
"$HERE/assets/checkup.sh" . --sync >/dev/null
grep -q '^TRUNK=' tools/campaign.sh || fail "decoy banner corrupted the config splice"
bash -n tools/campaign.sh || fail "decoy sync produced broken script"
cd "$TMP/proj"

# 9) land-report audit: landed doc without a table → GAPS; with table → OK; abandoned → ignored
cat > docs/campaigns/oldland.md <<'EOF'
# campaign: oldland
- result / verdict: LANDS — merged 2026-07-20
EOF
cat > docs/campaigns/aborted.md <<'EOF'
# campaign: aborted
- result / verdict: ABANDONED — superseded
EOF
cat > docs/campaigns/openplan.md <<'EOF'
# campaign: openplan
- result / verdict:

## plan
- [ ] probe stress test → result: inconclusive, next: sweep k
- [ ] check if this already LANDED upstream before redoing the work
EOF
cat > docs/campaigns/prose.md <<'EOF'
# campaign: prose
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
- **verdict**: LANDS — merged as PR #13
EOF
cat > docs/campaigns/korean.md <<'EOF'
# campaign: korean
- 결론: LANDS — PR #13 머지됨
EOF
cat > docs/campaigns/boxed.md <<'EOF'
# campaign: boxed
- [x] LANDED as PR #7
EOF
cat > docs/campaigns/decoabandon.md <<'EOF'
# campaign: decoabandon
- **verdict**: ABANDONED — superseded
EOF
cat > docs/campaigns/fakephase.md <<'EOF'
# campaign: fakephase
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
- 결론결론결론결론: LANDS — PR #13 머지됨
EOF
cat > docs/campaigns/boxabandon.md <<'EOF'
# campaign: boxabandon
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
  printf '# campaign: %s\n%s\n' "$1" "$2" > "docs/campaigns/m_$1.md"
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
mkdir -p "$TMP/fresh" && cd "$TMP/fresh" && git init -q
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

# 13) CHANGELOG header-format pin (the relay's parsing contract)
grep -E '^## v' "$HERE/CHANGELOG.md" | grep -vE '^## v[0-9]+\.[0-9]+\.[0-9]+ \([0-9]{4}-[0-9]{2}-[0-9]{2}\)$' \
  && fail "CHANGELOG header format drifted — harness-changes relay parsing depends on '## vX.Y.Z (date)'"

# 14) v0.6.0 DEFAULT rows — counts and gates only. Every one of these must be
#     cheap (no tree walks beyond the doc dirs) and none may propose work: the
#     default run is a drift doctor, not a nag. A fresh, honest project must
#     come out green, or the rows manufacture drift on day one.
R="$TMP/rows"; mkdir -p "$R" && cd "$R" && git init -q
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
printf '# tiny\n' > CLAUDE.md; rm -f docs/plan.md

# --- reference: existence + pointer resolution + dated-claim expiry ---
out="$("$CK" .)"
grep -q "reference | MISSING" <<<"$out"   || fail "absent docs/reference/ not reported MISSING"
mkdir -p docs/reference
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
- status: LANDED
- result / verdict: LANDS — merged as PR #5
EOF
out="$("$CK" .)"
grep -qE "campaigns \| 2 open/3 total, 1 false-OPEN" <<<"$out" || fail "campaign census wrong: $(grep '^campaigns' <<<"$out")"

# --- structure: ONE summary line, never action-proposing in default mode ---
out="$("$CK" .)"
grep -q "^structure | " <<<"$out"                    || fail "no structure summary row"
grep -q "run /ohd-checkup structure" <<<"$out"       || fail "structure row does not point at the mode"
[ "$(grep -c '^structure | ' <<<"$out")" = 1 ]       || fail "structure row is not exactly one line"
grep -qi "orphan" <<<"$out"        && fail "default mode leaked the structure work-list (orphan census)"
grep -qi "candidates:" <<<"$out"   && fail "default mode enumerated solidation candidates (action-proposing)"

echo "CHECKUP-SMOKE PASS"
