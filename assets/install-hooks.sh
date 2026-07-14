#!/usr/bin/env bash
# install-hooks.sh — protected-trunk pre-commit hook (docs-only commits on trunk).
# Optional: projects that develop directly on trunk (like this plugin repo) skip it.
set -euo pipefail
TRUNK="${CAMPAIGN_TRUNK:-main}"
ALLOW_RE="${CAMPAIGN_TRUNK_ALLOW:-^docs/|\.md$}"   # ERE of paths allowed on trunk
HOOK_DIR="$(git rev-parse --git-common-dir)/hooks"
mkdir -p "$HOOK_DIR"
cat > "$HOOK_DIR/pre-commit" <<HOOK
#!/usr/bin/env bash
br="\$(git branch --show-current)"
[ "\$br" = "$TRUNK" ] || exit 0
bad="\$(git diff --cached --name-only | grep -Ev '$ALLOW_RE' || true)"
if [ -n "\$bad" ]; then
  echo "pre-commit: trunk '$TRUNK' is docs-only; blocked paths:" >&2
  echo "\$bad" >&2
  echo "land code via a campaign worktree (campaign.sh new <name>)." >&2
  exit 1
fi
exit 0
HOOK
chmod +x "$HOOK_DIR/pre-commit"
echo "installed pre-commit (trunk=$TRUNK, allow='$ALLOW_RE') at $HOOK_DIR/pre-commit"
