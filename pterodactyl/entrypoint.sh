#!/bin/bash
# /app/entrypoint.sh — invoked by the egg's `startup` string on every boot.
#
# Pterodactyl mounts the persistent server volume at /home/container, so
# anything the update scripts write there survives restarts. This entrypoint
# just guarantees the directories exist, then execs the MCP server so its
# stdin is attached to Pterodactyl's console.
set -e

: "${DOCS_ROOT:=/home/container/docs}"
: "${CACHE_ROOT:=/home/container/.cache}"

mkdir -p "$DOCS_ROOT" "$CACHE_ROOT"

# On first boot the docs volume is empty. Print a hint (once) so users know
# they need to either upload manual docs via the File Manager or wait for
# the daily `update-docs` schedule to populate the auto-updated sources.
if [ -z "$(ls -A "$DOCS_ROOT" 2>/dev/null)" ]; then
    echo "[entrypoint] $DOCS_ROOT is empty — send the console command"
    echo "[entrypoint]   update-docs"
    echo "[entrypoint] to fetch swiftlys2 / source2 / GameTracking-CS2 now,"
    echo "[entrypoint] or upload your own markdown via the File Manager."
fi

cd /home/container

# `exec` replaces the shell with python so SIGINT from Pterodactyl reaches
# the server directly (otherwise config.stop=^C would time out).
exec python3 /app/doc-server.py
