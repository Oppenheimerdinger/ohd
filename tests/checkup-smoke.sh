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

# 3) post-sync: IN-SYNC (config differences must NOT count as drift)
out="$("$CK" .)"; grep -q "campaign.sh | IN-SYNC" <<<"$out" || fail "expected IN-SYNC after sync"

# 4) hook + state-dir + CLAUDE.md reporting
out="$("$CK" .)"; grep -q "trunk-hook | MISSING" <<<"$out" || fail "expected hook MISSING"
bash "$HERE/assets/install-hooks.sh" >/dev/null
out="$("$CK" .)"; grep -q "trunk-hook | INSTALLED" <<<"$out" || fail "expected hook INSTALLED"
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

echo "CHECKUP-SMOKE PASS"
