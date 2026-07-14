#!/usr/bin/env bash
# new-project.sh — deterministic research-project scaffolder (oppenheimerdinger).
# All inputs are flags; /ohd-new-project runs the interview and calls this.
set -euo pipefail

die() { echo "new-project.sh: $*" >&2; exit 1; }

NAME="" DIR="" GITHUB="none" TRUNK="main" NAMING="free" MERGE_MODEL="coordinator"
HOOK=no HOST_NAME="" HOST_VEHICLE="" HOST_REPO="" HOST_TRUNK=""
DATA_DIR="" DEPLOY="none" FS="separate"
NODES=() ENVS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="${2:-}"; shift 2;;
    --dir) DIR="${2:-}"; shift 2;;
    --github) GITHUB="${2:-}"; shift 2;;
    --trunk) TRUNK="${2:-}"; shift 2;;
    --naming) NAMING="${2:-}"; shift 2;;
    --merge-model) MERGE_MODEL="${2:-}"; shift 2;;
    --hook) HOOK=yes; shift;;
    --no-hook) HOOK=no; shift;;
    --host-name) HOST_NAME="${2:-}"; shift 2;;
    --host-vehicle) HOST_VEHICLE="${2:-}"; shift 2;;
    --host-repo) HOST_REPO="${2:-}"; shift 2;;
    --host-trunk) HOST_TRUNK="${2:-}"; shift 2;;
    --node) NODES+=("${2:-}"); shift 2;;
    --fs) FS="${2:-}"; shift 2;;
    --env) ENVS+=("${2:-}"); shift 2;;
    --data-dir) DATA_DIR="${2:-}"; shift 2;;
    --deploy) DEPLOY="${2:-}"; shift 2;;
    *) die "unknown flag: $1";;
  esac
done

TPL="$(cd "$(dirname "$0")" && pwd)"   # the plugin's assets dir

# ── preflight (no filesystem effects before this block passes) ──────────
NAME_RE='^[A-Za-z0-9][A-Za-z0-9._-]*$'
[ -n "$NAME" ] || die "--name is required"
[[ "$NAME" =~ $NAME_RE ]] || die "bad --name '$NAME' (allowed: $NAME_RE)"
case "$NAMING" in free|numbered) :;; *) die "--naming must be free|numbered";; esac
case "$MERGE_MODEL" in coordinator|review-gate) :;; *) die "--merge-model must be coordinator|review-gate";; esac
case "$FS" in shared|separate) :;; *) die "--fs must be shared|separate";; esac
case "$DEPLOY" in none|snapshot|mirror) :;; *) die "--deploy must be none|snapshot|mirror";; esac
[ "$GITHUB" = none ] || [[ "$GITHUB" == */* ]] || die "--github must be owner/name (or none)"
git check-ref-format --branch "$TRUNK" >/dev/null 2>&1 || die "bad --trunk '$TRUNK'"
[ -n "$HOST_TRUNK" ] && { git check-ref-format --branch "$HOST_TRUNK" >/dev/null 2>&1 || die "bad --host-trunk '$HOST_TRUNK'"; }
[ -n "$HOST_REPO" ] && [[ "$HOST_REPO" =~ [[:space:]] ]] && die "--host-repo must not contain whitespace"
if [ -n "$HOST_NAME" ]; then
  [[ "$HOST_NAME" =~ $NAME_RE ]] || die "bad --host-name '$HOST_NAME'"
  [ -n "$HOST_VEHICLE" ] && [ -n "$HOST_REPO" ] || die "--host-name requires --host-vehicle and --host-repo"
  case "$HOST_VEHICLE" in
    fork) [ -n "$HOST_TRUNK" ] || die "--host-vehicle fork requires --host-trunk";;
    patches) :;;
    *) die "--host-vehicle must be fork|patches";;
  esac
fi
DIR="${DIR:-$HOME/projects/$NAME}"
[ -e "$DIR" ] && die "$DIR already exists — rerunning into an existing dir is undefined; pick another --dir"
if [ -n "$DATA_DIR" ] && [ "$DATA_DIR" != none ]; then
  [ -d "$DATA_DIR" ] || die "--data-dir '$DATA_DIR' does not exist"
else
  DATA_DIR=""
fi
[ ${#ENVS[@]} -gt 0 ] || ENVS=("main:uv")
idx=0
for e in "${ENVS[@]}"; do
  [[ "$e" == *:* ]] || die "bad --env '$e' (want name:type[@machine])"
  n="${e%%:*}"
  [[ "$n" =~ $NAME_RE ]] || die "bad --env name '$n'"
  t="${e#*:}"; t="${t%%@*}"
  case "$t" in uv|conda|module) :;; *) die "bad --env type '$t' in '$e'";; esac
  [ "$t" = uv ] && [ $idx -ne 0 ] && die "uv is allowed only as the primary (first) --env"
  idx=$((idx+1))
done
for nd in "${NODES[@]}"; do
  n="${nd%%:*}"
  [[ "$n" =~ $NAME_RE ]] || die "bad --node name '$n'"
done
(cd / && git config user.email >/dev/null 2>&1) || [ -n "${GIT_COMMITTER_EMAIL:-}" ] \
  || die "no git identity (set git config user.email, or export GIT_COMMITTER_EMAIL/GIT_AUTHOR_EMAIL)"

# ── helpers ──────────────────────────────────────────────────────────────
subst() {  # subst <file> KEY=value...  ({{KEY}} value tokens)
  local f="$1"; shift
  local args=() kv k v
  for kv in "$@"; do
    k="${kv%%=*}"; v="${kv#*=}"
    v="${v//\\/\\\\}"; v="${v//&/\\&}"; v="${v//|/\\|}"
    args+=(-e "s|{{$k}}|$v|g")
  done
  sed -i.bak "${args[@]}" "$f" && rm -f "$f.bak"
}
inject_block() {  # inject_block <file> <TOKEN> <blockfile> (token alone on its line)
  local f="$1" tok="{{$2}}" blk="$3"
  awk -v tok="$tok" -v blk="$blk" '
    { line0=$0; sub(/\r$/,"",line0) }
    line0 == tok { while ((getline line < blk) > 0) print line; close(blk); next }
    { print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}
set_default() {  # set_default <file> VAR value — rewrite ${CAMPAIGN_VAR:-old}
  local f="$1" var="$2" val="$3"
  val="${val//\\/\\\\}"; val="${val//&/\\&}"; val="${val//|/\\|}"
  sed -i.bak "s|\${CAMPAIGN_$var:-[^}]*}|\${CAMPAIGN_$var:-$val}|" "$f" && rm -f "$f.bak"
}

# ── scaffold ─────────────────────────────────────────────────────────────
trap 'echo "new-project.sh: died after directory creation — remove $DIR before rerunning" >&2' ERR
mkdir -p "$DIR"; cd "$DIR"
git init -q -b "$TRUNK"

cat > .gitignore <<'GITIGNORE'
.omc/
.superpowers/
.venv/
__pycache__/
*.pyc
/data
GITIGNORE

mkdir -p tools docs/campaigns .claude/skills
cp "$TPL/campaign.sh" tools/campaign.sh
cp "$TPL/install-hooks.sh" tools/install-hooks.sh
set_default tools/campaign.sh TRUNK "$TRUNK"
set_default tools/campaign.sh NAMING "$NAMING"
set_default tools/campaign.sh MERGE_MODEL "$MERGE_MODEL"
set_default tools/install-hooks.sh TRUNK "$TRUNK"
touch docs/campaigns/.gitkeep .claude/skills/.gitkeep

# env stubs (primary = first)
primary="${ENVS[0]}"; pn="${primary%%:*}"; pt="${primary#*:}"; pt="${pt%%@*}"
case "$pt" in
  uv)
    printf '[project]\nname = "%s"\nversion = "0.1.0"\nrequires-python = ">=3.12"\n' "$NAME" > pyproject.toml
    echo "3.12" > .python-version ;;
  conda)
    printf 'name: %s\nchannels: [conda-forge]\ndependencies:\n  - python=3.12\n' "$pn" > environment.yml ;;
  module) : ;;
esac
for e in "${ENVS[@]:1}"; do
  n="${e%%:*}"; t="${e#*:}"; t="${t%%@*}"
  if [ "$t" = conda ]; then
    mkdir -p envs
    printf 'name: %s\nchannels: [conda-forge]\ndependencies:\n  - python=3.12\n' "$n" > "envs/$n.yml"
  fi
done

# hosts machinery
if [ -n "$HOST_NAME" ]; then
  mkdir -p "hosts/$HOST_NAME"
  cp "$TPL/hosts-templates/manifest"  "hosts/$HOST_NAME/manifest"
  cp "$TPL/hosts-templates/setup.sh"  "hosts/$HOST_NAME/setup.sh"
  cp "$TPL/hosts-templates/README.md" "hosts/$HOST_NAME/README.md"
  subst "hosts/$HOST_NAME/manifest" HOST="$HOST_NAME" VEHICLE="$HOST_VEHICLE" REPO="$HOST_REPO" HOST_TRUNK="$HOST_TRUNK"
  subst "hosts/$HOST_NAME/README.md" HOST="$HOST_NAME"
  if [ "$HOST_VEHICLE" = fork ]; then
    sed -i.bak '/^PATCHES=/d' "hosts/$HOST_NAME/manifest" && rm -f "hosts/$HOST_NAME/manifest.bak"
    set_default tools/campaign.sh DEP_DIR "../$HOST_NAME"
    set_default tools/campaign.sh DEP_TRUNK "$HOST_TRUNK"
    set_default tools/campaign.sh PIN_FILE "hosts/$HOST_NAME/manifest"
  else
    sed -i.bak '/^TRUNK=/d' "hosts/$HOST_NAME/manifest" && rm -f "hosts/$HOST_NAME/manifest.bak"
    mkdir -p "hosts/$HOST_NAME/patches"
    touch "hosts/$HOST_NAME/patches/.gitkeep"
  fi
fi

# data symlink
if [ -n "$DATA_DIR" ]; then ln -s "$DATA_DIR" data; fi

# CLAUDE.md
cp "$TPL/CLAUDE.md.template" CLAUDE.md
sed -i.bak '1,2d' CLAUDE.md && rm -f CLAUDE.md.bak
subst CLAUDE.md NAME="$NAME" TRUNK="$TRUNK" NAMING="$NAMING" MERGE_MODEL="$MERGE_MODEL" DEPLOY="$DEPLOY"
blk="$(mktemp)"
if [ ${#NODES[@]} -eq 0 ]; then
  echo "- machine: (single machine) — all roles; fs: local" > "$blk"
else
  : > "$blk"
  for nd in "${NODES[@]}"; do
    IFS=: read -r nn nr ns <<<"$nd"
    echo "- machine \`$nn\` — role: ${nr:-(fill in)}${ns:+ · ssh: \`$ns\`} · fs: $FS" >> "$blk"
  done
  if [ "$FS" = separate ]; then
    { echo ""
      echo "Code moves between machines by commit→push→pull ONLY — no scp of repo files."
      echo "Remote machines: clone from the git remote; never copy checkouts."; } >> "$blk"
  fi
fi
{ echo ""; echo "Environments:"; } >> "$blk"
for e in "${ENVS[@]}"; do
  n="${e%%:*}"; rest="${e#*:}"; t="${rest%%@*}"; m=""
  case "$rest" in *@*) m="${rest#*@}";; esac
  echo "- env \`$n\` ($t${m:+ @ \`$m\`}) — activate: (fill in)" >> "$blk"
done
inject_block CLAUDE.md MATRIX_BLOCK "$blk"
dblk="$(mktemp)"
if [ -n "$DATA_DIR" ]; then
  { echo "## Data"; echo ""
    echo "- shared data at \`$DATA_DIR\` → symlinked as \`data\` (gitignored;"
    echo "  treat as read-only — the source permissions are the real guard)"; } > "$dblk"
else : > "$dblk"; fi
inject_block CLAUDE.md DATA_BLOCK "$dblk"
hblk="$(mktemp)"
if [ -n "$HOST_NAME" ]; then
  { echo "## External code"; echo ""
    echo "- host \`$HOST_NAME\` ($HOST_VEHICLE) from $HOST_REPO — see"
    echo "  \`hosts/$HOST_NAME/\` (\`setup.sh\` materializes it; PIN lives in the manifest;"
    echo "  \`OHD_HOST_DIR\` and \`CAMPAIGN_DEP_DIR\` must point at the same place)"; } > "$hblk"
else : > "$hblk"; fi
inject_block CLAUDE.md HOSTS_BLOCK "$hblk"
rm -f "$blk" "$dblk" "$hblk"
grep -q '{{' CLAUDE.md && die "internal error: unsubstituted tokens remain in CLAUDE.md"

# README stub
{ echo "# $NAME"; echo ""; echo "goal: (한 줄)"; echo ""
  echo "Worked with the [oppenheimerdinger](https://github.com/Oppenheimerdinger/oppenheimerdinger) harness."; } > README.md

chmod +x tools/campaign.sh tools/install-hooks.sh
[ -n "$HOST_NAME" ] && chmod +x "hosts/$HOST_NAME/setup.sh"

# ── commit → hook → github (order is load-bearing) ──────────────────────
git add -A
git commit -q -m "chore: scaffold by oppenheimerdinger new-project"
if [ "$HOOK" = yes ]; then bash tools/install-hooks.sh; fi
if [ "$GITHUB" != none ]; then
  if command -v gh >/dev/null 2>&1 && gh repo create "$GITHUB" --private --source=. --push; then
    echo "GitHub: https://github.com/$GITHUB (private)"
  else
    echo "gh absent or failed — run manually:"
    echo "  gh repo create $GITHUB --private --source=. --push"
    echo "  (or: git remote add origin git@github.com:$GITHUB.git && git push -u origin $TRUNK)"
    echo "  (repo may already exist and origin may be set — then just: git push -u origin $TRUNK)"
  fi
fi

# ── next steps ───────────────────────────────────────────────────────────
trap - ERR
echo ""
echo "scaffolded: $DIR"
echo "next steps:"
echo "  1. open a NEW session anchored at $DIR"
echo "  2. the way-of-working skill is the tool router; CLAUDE.md carries this project's facts"
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "  *  campaign.sh needs an origin remote — first:"
  echo "     git remote add origin <url> && git push -u origin $TRUNK"
fi
echo "  3. first campaign: tools/campaign.sh new <name>"
