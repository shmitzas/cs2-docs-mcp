#!/usr/bin/env bash
# update-cs2-gametracking.sh
# Sync a shallow mirror of https://github.com/SteamTracking/GameTracking-CS2
# into docs/counter-strike-2/GameTracking-CS2/.
#
# Note: this repo is LARGE (game files, protobufs, schemas). Depth-1 keeps the
# initial clone small; subsequent runs do a delta fetch. Expect several hundred
# MB of on-disk footprint.
#
# We clone into a subfolder (not directly into docs/counter-strike-2/) so we
# don't clobber sibling files the user has there (e.g. the manually-saved
# Valve Developer Community wiki pages).

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Overridable via DOCS_ROOT env var (see Pterodactyl deployment).
DOCS_ROOT="${DOCS_ROOT:-$SCRIPT_DIR/docs}"
OUT_DIR="$DOCS_ROOT/counter-strike-2/GameTracking-CS2"
REPO_URL="https://github.com/SteamTracking/GameTracking-CS2.git"
LEGACY_DIR="$DOCS_ROOT/counter-strike-2/GameTracking-CS2-master"

LOCK="/tmp/docs-mcp.$(basename "$0").lock"
exec 9>"$LOCK"
if ! flock -n 9; then
  echo "[cs2-gt] another instance is running; exiting" >&2
  exit 0
fi

if [ -d "$LEGACY_DIR" ] && [ ! -d "$OUT_DIR" ]; then
  echo "[cs2-gt] note: legacy '$LEGACY_DIR' exists alongside the new git checkout."
  echo "[cs2-gt] delete it manually once you've verified '$OUT_DIR' contains what you want."
fi

mkdir -p "$(dirname "$OUT_DIR")"

if [ -d "$OUT_DIR/.git" ]; then
  echo "[cs2-gt] fetching latest into $OUT_DIR"
  git -C "$OUT_DIR" fetch --depth 1 origin HEAD
  git -C "$OUT_DIR" reset --hard FETCH_HEAD
  git -C "$OUT_DIR" clean -fdx
else
  echo "[cs2-gt] cloning $REPO_URL (this may take a while — large repo)"
  git clone --depth 1 "$REPO_URL" "$OUT_DIR"
fi

# Smoke check.
if [ ! -f "$OUT_DIR/README.md" ]; then
  echo "[cs2-gt] ERROR: README.md missing after sync — clone may have failed" >&2
  exit 1
fi
echo "[cs2-gt] OK — HEAD $(git -C "$OUT_DIR" rev-parse --short HEAD)"
