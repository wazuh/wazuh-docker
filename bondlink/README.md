# BondLink overlay for wazuh-docker 4.14.0 (interim stopgap)

Branch `4.10-align`, checked out as a separate git worktree from the main
repo (`/Volumes/Sources/wazuh-docker`, branch `5.0-align`) so the two efforts'
untracked `bondlink/` content never mixes — both worktrees share one `.git`.

Purpose: `wazuh/wazuh-manager:5.1.0` and `wazuh/wazuh-indexer:5.1.0` aren't
published yet, so the 5.0 port (`5.0-align` branch) can't run live. This
branch is a deployable, upstream-mergeable stopgap on the version actually
running today (v4.14.0), carrying forward BondLink's customizations from
`/src/wazuh-docker-4.10` with the bugs the audit found fixed, meant to be
retired once the 5.0 port is validated.

Unlike the 5.0 port, stock 4.14.0 already mounts full config files via
`/wazuh-config-mount` (that mechanism isn't new to 5.0), so this overlay is
much more direct: full replacement config files layered on top of the base
compose file, matching how the current production fork already works.

## Usage

Run from this worktree's root:

```
docker compose \
  -f multi-node/docker-compose.yml \
  -f bondlink/docker-compose.override.yml \
  up -d
```

Cert generation (run once, before `up`, after adding wazuh-warm1.indexer to
bondlink/config/certs.yml):

```
docker compose \
  -f multi-node/generate-indexer-certs.yml \
  -f bondlink/docker-compose.certs.override.yml \
  run --rm generator
```

Warm-tier indexer (on the separate warm host, once certs are copied there —
see below):

```
docker compose -f docker-compose-warm.yml up -d
```

Always sanity-check a merged config before applying changes:

```
docker compose -f multi-node/docker-compose.yml -f bondlink/docker-compose.override.yml config
```

**Gotcha** (same as the 5.0 port): Compose resolves relative bind-mount paths
in *all* merged files against the first `-f` file's directory (`multi-node/`),
not each file's own — hence `../bondlink/config/...` throughout.

**Gotcha**: `volumes:` and `ports:` are true lists, concatenated across merged
files — declaring a new mount at a path the base file already mounts
produces *two* mounts to the same container target, not a clean override.
Every service here that swaps an existing file (the manager confs, indexer
opensearch.yml, dashboard config, dashboard's port mapping) uses the
`!override` YAML merge tag on that key with the *complete* desired list.
`environment:`, by contrast, merges as a map (key-by-key) — no `!override`
needed there, redeclaring a key just replaces its value. Verified live via
`docker compose config` for every service below.

## What's ported, and what was fixed along the way

- **Warm indexer tier**: `docker-compose-warm.yml` + `config/wazuh_indexer/wazuh-warm1.indexer.yml`. **Fixed**: the 4.10 source's compose file referenced `wazuh-warm1.indexer.yml` and `wazuh-warm1.indexer*.pem`, but the actual tracked files were named without the "1" (`wazuh-warm.indexer.yml`) — as committed, that compose file would have failed to start. Standardized on the "1" suffix everywhere, matching `certs.yml` and every hot node's `NODES_DN` entry.
- **ISM hot/warm/delete lifecycle policy**: `config/wazuh_indexer/ism-policies/` — ported as-is (pure OpenSearch API calls via `apply-ism-policy.sh`, no host-specific assumptions beyond the target indexer host you pass it).
- **Hot-indexer tuning**: `node.attr.temp: hot`, `path.repo: /mnt/backups`, `plugins.security.ssl.transport.enabled_protocols: ["TLSv1.2"]`, `plugins.query.datasources.encryption.masterkey`, and the warm node's DN added to `plugins.security.nodes_dn` — all in `config/wazuh_indexer/wazuh{1,2,3}.indexer.yml`. Dropped a stray commented-out `discovery.type: "single-node"` line and fixed inconsistent list indentation found in the source (cosmetic, not behavioral).
- **Manager/worker `ossec.conf`**: full replacement files in `config/wazuh_cluster/`, carried forward from the source verbatim (SMTP relay, email alerting, CIS-CAT wodle, active-response CIDR whitelist, cluster key, indexer host list including the warm node on master only) — these are your real production values as agreed, to be rotated later (see Secrets below). **Fixed**: the worker conf's source had a stray `<key>` element directly inside `<global>` (not a valid ossec.conf setting, just a copy-paste artifact) — dropped; the real cluster key is in `<cluster><key>` on both files, matching.
- **Dashboard HTTP-only behind HAProxy**: `config/wazuh_dashboard/opensearch_dashboards.yml` — port 80, `server.ssl.enabled: false`, matching the source (which also intentionally dropped the stock file's `opensearch_security.cookie.ttl`/`session.ttl`/`session.keepalive` overrides — carried forward as-is here too).
- **Cert topology**: `config/certs.yml` — added `wazuh-warm1.indexer`, and `wazuh.master`'s `ip:` set to the real prod hostname (`prodops02.bondlink.vpc`), matching the source.
- **`/mnt/backups` shared mount + `/var/wazuh/imports`**: added to manager, dashboard, and all 3 hot indexers.
- **`host.docker.internal`/`wazuh-warm1.indexer` extra_hosts + static IP** on master/worker, for the warm node running on a separate host/compose project.
- **CloudWatch-agent / cron-backup sidecars**: `build/cloudwatch-agent/`, `build/cron-backup/`. **Fixed three real bugs**: (1) cron-backup's `ENTRYPOINT` was commented out in the source, so the container fell back to alpine's default shell and exited immediately — with `restart: always` it crash-looped forever and the daily S3 backup never actually ran; restored. (2) cloudwatch-agent's `jq` filter wrapped `${VAR}` in single quotes, so the build args for log group/stream/region were never actually interpolated and the agent silently used hardcoded template values instead; switched to `jq --arg`. (3) Both images were built to shadow the public `amazon/cloudwatch-agent` and `alpine:latest` tags — fragile on any host running unrelated containers under those names; renamed to `bondlink/wazuh-cwagent:4.10-align` and `bondlink/wazuh-cron-backup:4.10-align`, built directly via `build:` in the override (no separate `build-images.yml`/`build-images.sh` needed — that file's own bug, silently wiping the sidecar env vars from `.env` on rebuild, is sidestepped entirely by putting the build args directly in the compose override).

## Not ported (deliberately out of scope for this stopgap)

- `index_scripts/` (reindex/legacy-agent-ID remap) and `volume-migrator.sh` — one-time historical data-migration tools tied to a specific past cutover (the `prodmonitor` → `wazuh.master` migration), not general features.
- Secrets rotation — the cluster key, dashboard password, and API password are still plaintext in tracked files here (carried forward from production values as agreed). Since this is an interim stopgap expected to retire once 5.0 ships, this wasn't prioritized, but don't let this branch live long-term without addressing it.
- `internal_users.yml` — unmodified from stock; the source fork never touched it either, so nothing to port.

## Warm-host deployment note

`docker-compose-warm.yml` expects `./config/wazuh_indexer_ssl_certs/{root-ca,wazuh-warm1.indexer,wazuh-warm1.indexer-key,admin,admin-key}.pem`, `./config/wazuh_indexer/wazuh-warm1.indexer.yml`, and `./config/wazuh_indexer/internal_users.yml` relative to wherever it's run. Since the warm node deploys on a separate host, copy those specific files there alongside this compose file — the cert-generator step above produces the `.pem` files on the main host under `multi-node/config/wazuh_indexer_ssl_certs/`.
