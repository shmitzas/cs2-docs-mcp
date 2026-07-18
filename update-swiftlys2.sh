#!/usr/bin/env bash
# update-swiftlys2.sh
# Download https://swiftlys2.net/llms-full.txt and split it into per-page .md
# files under docs/swiftlys2/, matching the logic of split-docs.ps1.
#
# Each section in llms-full.txt starts with a line shaped like:
#   # Some Title (/docs/some/path)
# The path is used to derive the output filename (with '/' -> '-', plus '.md').
# The special path "/docs" writes to introduction.md.

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Override with DOCS_ROOT env var (e.g. under Pterodactyl where the persistent
# volume lives at /home/container). Defaults to sibling of this script.
DOCS_ROOT="${DOCS_ROOT:-$SCRIPT_DIR/docs}"
OUT_DIR="$DOCS_ROOT/swiftlys2"
SRC_URL="https://swiftlys2.net/llms-full.txt"

# One instance at a time.
LOCK="/tmp/docs-mcp.$(basename "$0").lock"
exec 9>"$LOCK"
if ! flock -n 9; then
  echo "[swiftlys2] another instance is running; exiting" >&2
  exit 0
fi

TMP_TXT="$(mktemp)"
trap 'rm -f "$TMP_TXT"' EXIT

echo "[swiftlys2] fetching $SRC_URL"
curl -fsSL --retry 3 --retry-delay 5 --max-time 120 \
  --user-agent "docs-mcp-updater/1.0" \
  "$SRC_URL" -o "$TMP_TXT"

# Strip CRLF so awk's $ anchor matches correctly regardless of upstream endings.
sed -i 's/\r$//' "$TMP_TXT"

mkdir -p "$OUT_DIR"

# Stage output in a sibling dir so a mid-run awk failure can't leave the live
# tree half-populated. Swap in atomically at the end.
STAGE_DIR="${OUT_DIR}.new"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

# POSIX-awk splitter (works with mawk, the default awk on Debian).
awk -v outdir="$STAGE_DIR" '
  function derive_filename(line,    op, cp, path) {
    op = index(line, "(/")
    cp = index(line, ")")
    if (op == 0 || cp <= op) return ""
    path = substr(line, op + 2, cp - op - 2)   # strip "(/" prefix and ")" suffix
    if (path == "docs") return "introduction.md"
    gsub("/", "-", path)
    return path ".md"
  }

  /^# .+ \(\/[^)]+\)$/ {
    if (file != "") close(file)
    fn = derive_filename($0)
    if (fn == "") { file = ""; next }
    file = outdir "/" fn
    found++
    # Truncate on first write of this file (in case of duplicate sections).
    printf "" > file
  }
  { if (file != "") print >> file }
  END {
    if (found == 0) {
      print "no sections matched in input" > "/dev/stderr"
      exit 1
    }
    printf "[swiftlys2] wrote %d section(s)\n", found > "/dev/stderr"
  }
' "$TMP_TXT"

# Smoke check the staged output.
count=$(find "$STAGE_DIR" -maxdepth 1 -type f -name '*.md' | wc -l)
if [ "$count" -lt 10 ]; then
  echo "[swiftlys2] ERROR: only $count .md files staged (expected >= 10)" >&2
  rm -rf "$STAGE_DIR"
  exit 1
fi

# Swap: remove old top-level .md, move staged files in. Preserves any
# subdirectories under $OUT_DIR that we don't manage.
find "$OUT_DIR" -maxdepth 1 -type f -name '*.md' -delete
mv "$STAGE_DIR"/*.md "$OUT_DIR/"
rmdir "$STAGE_DIR"

echo "[swiftlys2] OK — $count .md files in $OUT_DIR"
