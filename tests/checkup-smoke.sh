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

# 5) adoption: empty repo bootstraps a fresh copy
mkdir -p "$TMP/fresh" && cd "$TMP/fresh" && git init -q
out="$("$CK" .)"; grep -q "campaign.sh | MISSING" <<<"$out" || fail "expected MISSING in fresh repo"
"$CK" . --sync >/dev/null
[ -x tools/campaign.sh ]                    || fail "bootstrap did not create executable copy"
diff <(grep -v '^# synced-from' tools/campaign.sh) "$TPL" >/dev/null || fail "bootstrap copy differs from template beyond the stamp"

echo "CHECKUP-SMOKE PASS"
