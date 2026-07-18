#!/usr/bin/env bash
# update-source2.sh
# Sync the Source2 Wiki content from its upstream GitHub repo. The public site
# https://www.source2.wiki/ is a Docusaurus build of that repo, so we mirror
# the source directly instead of scraping rendered HTML.
#
# We shallow-clone the repo into a cache dir, then copy only the doc-content
# subdirectories into docs/source2/. Docusaurus source (src/, static/, config,
# node_modules) is skipped so the MCP index isn't polluted with TS/CSS.

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Overridable via DOCS_ROOT / CACHE_ROOT env vars (see Pterodactyl deployment).
DOCS_ROOT="${DOCS_ROOT:-$SCRIPT_DIR/docs}"
CACHE_ROOT="${CACHE_ROOT:-$SCRIPT_DIR/.cache}"
CACHE_DIR="$CACHE_ROOT/source2wiki"
OUT_DIR="$DOCS_ROOT/source2"
REPO_URL="https://github.com/Source2Wiki/Source2Wiki.git"

# Doc-content subdirs (whitelist). README kept for landing context.
CONTENT_ITEMS=(docs con_dump fgd_dump fgd_dump_overrides tooltex_dump README.md)

LOCK="/tmp/docs-mcp.$(basename "$0").lock"
exec 9>"$LOCK"
if ! flock -n 9; then
  echo "[source2] another instance is running; exiting" >&2
  exit 0
fi

mkdir -p "$(dirname "$CACHE_DIR")"

if [ -d "$CACHE_DIR/.git" ]; then
  echo "[source2] fetching latest into $CACHE_DIR"
  git -C "$CACHE_DIR" fetch --depth 1 origin HEAD
  git -C "$CACHE_DIR" reset --hard FETCH_HEAD
  git -C "$CACHE_DIR" clean -fdx
else
  echo "[source2] cloning $REPO_URL"
  git clone --depth 1 "$REPO_URL" "$CACHE_DIR"
fi

# Fresh mirror. Removes upstream-deleted pages; small enough that a full recopy
# is simpler than rsync --delete gymnastics.
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

for item in "${CONTENT_ITEMS[@]}"; do
  src="$CACHE_DIR/$item"
  if [ -e "$src" ]; then
    cp -a "$src" "$OUT_DIR/"
  else
    echo "[source2] warning: upstream missing '$item' (skipped)" >&2
  fi
done

# Smoke check — expect at least a handful of markdown/mdx docs.
count=$(find "$OUT_DIR" -type f \( -name '*.md' -o -name '*.mdx' \) | wc -l)
if [ "$count" -lt 10 ]; then
  echo "[source2] ERROR: only $count markdown files under $OUT_DIR" >&2
  exit 1
fi
echo "[source2] OK — $count markdown file(s) in $OUT_DIR ($(git -C "$CACHE_DIR" rev-parse --short HEAD))"
