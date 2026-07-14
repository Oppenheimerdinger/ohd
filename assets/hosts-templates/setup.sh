#!/usr/bin/env bash
# setup.sh — materialize this host at the pinned SHA on THIS machine.
# Override target dir with OHD_HOST_DIR (fixed name; must point at the same
# place as campaign.sh's CAMPAIGN_DEP_DIR when both are used).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/manifest"
ROOT="$(cd "$HERE/../.." && pwd)"
DEST="${OHD_HOST_DIR:-$(dirname "$ROOT")/$HOST}"
BUILD=no; [ "${1:-}" = --build ] && BUILD=yes

if [ -d "$DEST/.git" ]; then
  echo "EXISTING checkout at $DEST — adopting as-is (HEAD untouched; may be a live campaign branch)."
else
  echo "FRESH clone: $REPO -> $DEST"
  git clone "$REPO" "$DEST"
  if [ -n "${PIN:-}" ]; then
    git -C "$DEST" checkout -q "$PIN"
    echo "checked out PIN $PIN"
  else
    ref="${TRUNK:-}"
    if [ -n "$ref" ]; then git -C "$DEST" checkout -q "$ref"; fi
    sha="$(git -C "$DEST" rev-parse HEAD)"
    echo "PIN is empty — checked out ${ref:-the default branch} at $sha"
    echo ">>> record it: set PIN=$sha in $HERE/manifest"
  fi
  if [ "$VEHICLE" = patches ]; then
    shopt -s nullglob
    plist=("$HERE"/patches/*.patch)
    if [ -n "${PATCHES:-}" ]; then
      plist=(); for p in $PATCHES; do plist+=("$HERE/patches/$p"); done
    fi
    if [ ${#plist[@]} -eq 0 ]; then
      echo "no patches yet in $HERE/patches/ — skipping apply (add *.patch and re-run on a fresh clone)"
    else
      for p in "${plist[@]}"; do echo "applying $(basename "$p")"; git -C "$DEST" apply "$p"; done
      echo "patches applied (working tree intentionally dirty)"
    fi
  fi
fi

if [ "$BUILD" = yes ]; then
  if [ -x "$DEST/build.sh" ]; then (cd "$DEST" && ./build.sh)
  elif [ -f "$DEST/pyproject.toml" ] || [ -f "$DEST/setup.py" ]; then python -m pip install -e "$DEST"
  else echo "no known build entrypoint (build.sh / pyproject.toml) — build manually"; fi
fi
