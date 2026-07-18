# Pterodactyl deployment

Package the CS2 Docs MCP server as a [Pterodactyl](https://pterodactyl.io/)
egg so it runs alongside your game servers, gets managed by wings, and
refreshes its docs automatically every night.

Contents:

- `Dockerfile.pterodactyl` — image that stages the app in `/app/` (persistent
  volume at `/home/container` won't hide it) and runs as UID 988.
- `entrypoint.sh` — creates `/home/container/{docs,.cache}` on first boot,
  then execs `python3 /app/doc-server.py`.
- `cs2-docs-mcp.egg.json` — the importable egg (`PTDL_v2`).

The server accepts two **console commands** over stdin:

| Command       | What it does                                                |
| ------------- | ----------------------------------------------------------- |
| `update-docs` | Runs `/app/update-all.sh` then hot-reloads the index.       |
| `reindex`     | Rebuilds the index only (use after uploading manual docs).  |

Reindex swaps the in-memory metadata dict atomically and drops the file-content
LRU cache, so new / renamed / deleted markdown files become visible to MCP
clients within seconds. **No container restart is required.**

---

## 1. Build & push the image

The egg's `docker_images` entry points at `ghcr.io/shmitzas/cs2-docs-mcp:latest`.
Change that key/value in `cs2-docs-mcp.egg.json` if you're pushing somewhere else.

From the repo root:

```bash
# One-off local build (works for a same-arch node)
docker build -f pterodactyl/Dockerfile.pterodactyl -t ghcr.io/shmitzas/cs2-docs-mcp:latest .
docker push ghcr.io/shmitzas/cs2-docs-mcp:latest

# Or multi-arch via buildx (recommended — covers x86 + ARM nodes)
docker buildx build \
    -f pterodactyl/Dockerfile.pterodactyl \
    --platform linux/amd64,linux/arm64 \
    -t ghcr.io/shmitzas/cs2-docs-mcp:latest \
    --push .
```

If you want CI to do this on every push to `main`, drop a GitHub Actions
workflow that runs `docker/build-push-action@v6` with the same context and
tag — the egg will pull the new tag on next server restart.

---

## 2. Import the egg

1. **Admin → Nests** → pick or create a nest (e.g. "MCP servers").
2. **Import Egg** → upload `pterodactyl/cs2-docs-mcp.egg.json`.
3. The `CS2 Docs MCP Server` egg now appears under that nest.

---

## 3. Create the server

1. **Admin → Servers → Create New Server**.
2. Pick the nest and the `CS2 Docs MCP Server` egg.
3. Allocation: assign one port (the port number becomes the `PORT` variable's
   default; if you allocate `:9000` you must also set the `Port` variable to
   `9000` on the server's Startup tab so `EXPOSE`/`--host 0.0.0.0` match).
4. Resources: 256 MB RAM / 0.5 CPU is enough for a small deployment; bump to
   1 GB / 1 CPU if you index the full GameTracking-CS2 tree (hundreds of
   thousands of files).
5. Disk: allow **at least 3 GB** — GameTracking-CS2 alone is ~1 GB shallow-cloned.
6. **Create Server** and let the install script finish.

---

## 4. First boot

Hit **Start**. On the console you'll see:

```
[entrypoint] /home/container/docs is empty — send the console command
[entrypoint]   update-docs
[entrypoint] to fetch swiftlys2 / source2 / GameTracking-CS2 now,
[entrypoint] or upload your own markdown via the File Manager.
Documentation MCP server ready on port 8080
```

Pterodactyl marks the server **Running** as soon as it sees
`Documentation MCP server ready on port`. Send `update-docs` in the console
to populate `/home/container/docs/` for the first time — the initial run
takes a few minutes because the GameTracking-CS2 clone is large. Subsequent
runs do delta fetches and take seconds.

Any markdown you drop into `/home/container/docs/<category>/*.md` via the
File Manager becomes browsable after a `reindex` command (or the next
`update-docs`).

---

## 5. Daily 04:00 refresh — Pterodactyl Schedule

Pterodactyl **schedules** are per-server config, not baked into the egg
export. Set the schedule up once per server:

1. Server → **Schedules** tab → **Create Schedule**.
2. Fill in:
   - **Name:** `Daily docs refresh`
   - **Cron:** minute `0`, hour `4`, day `*`, month `*`, weekday `*`
   - **Only when server is online:** ✔
3. Save, then **Create Task** on the new schedule:
   - **Action:** `Send command`
   - **Payload:** `update-docs`
   - **Time offset:** `0`
4. That's it. At 04:00 every day, wings writes `update-docs\n` to the
   container's stdin, the update scripts run, and the index hot-reloads
   inline — no restart needed.

Want a belt-and-braces fallback (e.g. if the reindex ever wedges)?
Add a **second task** on the same schedule:

- **Action:** `Send power action`
- **Payload:** `Restart`
- **Time offset:** `900` (15 minutes — long enough for the updates to
  finish on a slow first-run day)

---

## 6. Point MCP clients at it

The server speaks SSE on `http://<node-ip>:<PORT>/sse`. Add to your client
config exactly as the top-level [README](../README.md#configuration)
describes — the URL is the only thing that changes.

---

## 7. Troubleshooting

| Symptom                                     | Fix                                                                                                                                 |
| ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Server stuck on `Starting`                  | The `done` string isn't printing. Check console for a Python traceback — usually a missing dependency (rebuild the image).          |
| `update-docs` says "script not found"       | Verify `/app/update-all.sh` exists in the image. If you built from a fork that renamed it, set the `UPDATE_SCRIPT` env var.         |
| `update-docs` runs but no new docs show up  | Check the console for errors from the individual `update-*.sh` scripts. `git clone` often fails on tight disk quotas — bump disk.   |
| Console shows `[console] unknown command`   | Only `update-docs` and `reindex` are recognised. Typos won't do anything harmful, just get logged.                                  |
| MCP clients see stale content after upload  | The `_load_content` LRU cache holds file bodies. Send `reindex` — it clears the cache as well as rebuilding the metadata index.     |
| Stop button times out to SIGKILL            | Only happens if you replaced `entrypoint.sh` with one that doesn't `exec` the python process. Keep the `exec` on the last line.     |
| Two update runs at the same time            | The stdin handler serialises `update-docs` with a lock — a second invocation logs "another update is already running; ignoring".    |
