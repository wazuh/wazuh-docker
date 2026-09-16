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

## Version status

This branch is named `4.10-align`, but it is **not** running Wazuh 4.10 — the
name is a legacy label carried over from the old ad-hoc fork's directory
(`/src/wazuh-docker-4.10`), which had itself been manually upgraded over time
to actually run 4.14.0 in production without ever being renamed. This branch
tracks that reality: its base commit *is* upstream's `v4.14.0` tag
(`git describe` on `HEAD` reads `v4.14.0-<n>-g<sha>`), plus the two commits
that added and validated this `bondlink/` overlay.

So "should we upgrade from 4.10 to 4.14?" is not a live decision here — it
already happened, upstream of this branch even existing. The real question
going forward is when to move further: to newer 4.14.x patch tags now, or to
the 5.x line once `5.0-align` (see below) is validated and its blocking
images (`wazuh/wazuh-manager:5.1.0`, `wazuh/wazuh-indexer:5.1.0`) are
published. See "Syncing with upstream Wazuh releases" below for that process.

## Repository structure

This repo is a real fork of `wazuh/wazuh-docker` (`git remote -v` shows
`origin` = `mblink/wazuh-docker`, `upstream` = `wazuh/wazuh-docker`) with full,
non-squashed shared history — not a copied/vendored snapshot. `bondlink/` is
a pure compose-overlay (see Usage below) that never edits upstream-tracked
files, which is what keeps this branch "upstream-mergeable": there is nothing
in the overlay design that upstream releases can conflict with, short of
upstream relocating a file path this overlay hardcodes (has happened once,
see the sync section below).

Keeping this as one repo with `upstream` as a remote (rather than splitting
the overlay into its own repo that vendors `wazuh-docker` via a submodule or
subtree) is the deliberate choice: it gives clean 3-way merges against real
upstream tags, avoids submodule detached-HEAD foot-guns, and matches
`bondlink/`'s own design goal of staying a non-invasive layer on top of
upstream's own compose-override extension point. `4.10-align` and the
`5.0-align` branch (`/Volumes/Sources/wazuh-docker`, tracking unreleased
5.1.0) are separate git worktrees sharing this one `.git`, specifically so
each branch's own `bondlink/` content never mixes with the other's.

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

## Syncing with upstream Wazuh releases

To pull in a newer upstream release (a later 4.14.x patch, or eventually the
5.x line once it's viable) without disturbing `bondlink/`:

1. `git fetch upstream --tags`
2. Check `documentation.wazuh.com` release notes for the target version for
   breaking changes — especially anything touching indexer config/cert paths.
   Upstream has moved that layout before (the 4.13.x restructuring, from
   `/usr/share/wazuh-indexer/{certs,opensearch.yml,...}` to
   `/usr/share/wazuh-indexer/config/{...}`), which is exactly the kind of
   change that can silently break a hardcoded overlay path.
3. Run `bondlink/scripts/sync-upstream.sh <tag>` (omit the tag to list
   upstream tags newer than this branch's current base) to merge it in.
4. Resolve any conflicts. There should be none/rare, since `bondlink/` never
   touches upstream-tracked files — a real conflict here is a signal that
   upstream touched something this overlay assumes, not a normal occurrence.
5. Re-run `docker compose -f multi-node/docker-compose.yml -f
   bondlink/docker-compose.override.yml config` to confirm merged paths still
   resolve.
6. Bring the stack up against the new images and re-validate (cluster health,
   TLS pin, mounted config content actually present) the same way the "Live
   validation results" section below was produced, then update that section
   with the new version's results.
7. Re-pull and re-pin the image digests (see "Image pinning" below) as part
   of the same pass — don't assume the digest behind a version tag is stable
   from one sync to the next.

## Image pinning

`wazuh.master`/`wazuh.worker`, `wazuh1/2/3.indexer` (and the warm node in
`docker-compose-warm.yml`), and `wazuh.dashboard` are pinned by digest
(`image: wazuh/wazuh-<component>@sha256:...`) rather than by the floating
`4.14.0` tag. This isn't cosmetic: `docker pull` against all three
`wazuh/wazuh-*:4.14.0` tags on 2026-09-16 reported **"Downloaded newer
image"** for every one of them, confirming Docker Hub had already served
different content under the same tag than whatever was cached before —
this is exactly how production's indexer nodes ended up temporarily
suspected of running on a different internal config-path convention than
this overlay assumes (see "Version status" above and the git history for
the full investigation). An unpinned tag means a routine `docker compose
pull` can silently swap in a build with different internal behavior with
no changelog to check against.

Current pinned digests (captured 2026-09-16, from `docker pull
wazuh/wazuh-<component>:4.14.0` + `docker inspect ... --format
'{{.RepoDigests}}'`):
- `wazuh-manager`: `sha256:d2387a8304391600154c7b8604b390c8b798ec1403b5f1f707703bafdb230f84`
- `wazuh-indexer`: `sha256:0f1eb6c22912ca7948679cc3eca05346464678a42cab5cf5b1e17b99659e3582`
- `wazuh-dashboard`: `sha256:ee2bad5f799e29a2a1ba218a634749a3bcd823e6f1aa09482b5d81bdba886b6c`

To intentionally move to a newer build, re-pull the tag, re-run
`docker inspect wazuh/wazuh-<component>:4.14.0 --format
'{{.RepoDigests}}'`, update the digest here and in every `image:` line
above, and re-run the full validation pass before trusting it.

**Real-world confirmation (2026-09-16)**: this exact drift caused a live
production outage on the actual `prodops02` host running the old fork —
`docker compose up` implicitly re-pulled `wazuh/wazuh-indexer:4.14.0`
mid-troubleshooting, got a build that reads config from a different
internal path than the one production's compose file mounts to, and the
recreated indexer nodes came up on the image's baked-in
`discovery.type: single-node` default instead of the real cluster config —
which fatally conflicts with a node's on-disk voting state from actually
being a 3-node cluster member. Recovered cleanly (no data loss, cluster
back to green) by retagging the previously-cached good image back onto the
tag and force-recreating. Production's permanent fix there was
`pull_policy: never` on all 6 services, not a digest pin — its
already-running images had empty `RepoDigests` (no registry digest to pin
to), which is why this repo uses digest-pinning where possible (a fresh
`docker pull` here does return a real digest) and `pull_policy: never`
would be the fallback if that ever stops being true.

## Live validation results (real `v4.14.0` containers)

Brought the full stack up against real `wazuh/wazuh-manager`, `wazuh/wazuh-indexer`, and `wazuh/wazuh-dashboard` `4.14.0` images (not just `docker compose config`). Findings:

**Confirmed working, end to end:**
- 3-node hot indexer cluster reaches `"status": "green"`, all 3 nodes joined (`_cluster/health`, `_cat/nodes`).
- `node.attr.temp: hot` present on all 3 nodes (`_cat/nodeattrs`).
- TLS 1.2 transport pin actually takes effect (`Enabled TLS protocols for Transport layer : [TLSv1.2]` in indexer logs, vs. both 1.2/1.3 on the HTTP layer, which we didn't restrict).
- `OPENSEARCH_JAVA_OPTS=-Xms4g -Xmx4g` override reflected in the actual JVM args and reported heap size.
- Manager's mounted `ossec.conf` contains our email alerting, cluster key, and CIDR whitelist exactly as authored (`grep`-verified inside the running container).
- `cron-backup`'s `ENTRYPOINT` fix confirmed live — container runs `crond -f -d 8` and stays up, rather than crash-looping.
- Dashboard serves HTTP on port 80 (302 redirect to login, as expected for an unauthenticated request) — confirms the port/SSL-disable change works.

**Found and fixed one real bug during testing**: our ported `ossec.conf` carried forward `<wodle name="cis-cat"><disabled>no</disabled>` from the source fork, but the stock `wazuh-manager:4.14.0` image ships neither the CIS-CAT benchmark content (`wodles/ciscat`) nor a JRE (`wodles/java`) — confirmed both paths don't exist in the image. Disabled it in `config/wazuh_cluster/wazuh_manager.conf` (see the comment there) until those dependencies are actually provisioned (custom image layer or mounted volume) and re-verified.

**Could not fully validate here — environment limitation, not a port defect**: even with CIS-CAT disabled, `wazuh-modulesd` segfaults under this Mac's QEMU x86_64-on-arm64 emulation during its own pre-flight config self-test (`wazuh-modulesd -t`), which blocks `wazuh-control` from starting *any* manager daemon (analysisd, remoted, etc. — confirmed via `wazuh-control status`). Isolated this by testing `wazuh-modulesd -t` against a bare-minimum config with no wodles at all — it segfaults identically, so this is unrelated to our config content or the CIS-CAT fix. `wazuh-analysisd -t` and `wazuh-logcollector -t` both pass cleanly against our real config. `wazuh/wazuh-manager:4.14.0` is a single-platform (amd64-only) image (`docker manifest inspect` confirms no arm64 variant), so this emulation path is unavoidable on Apple Silicon and would very likely not reproduce on real x86_64 hardware (the actual production target). If you need to validate manager-daemon startup locally, do it on an amd64 host/VM rather than under QEMU emulation.

**Local-only test scaffolding** (not part of the actual port, kept for future testers on similar hardware): `bondlink/docker-compose.local-test-only.yml` + `bondlink/local-test-only/wazuh{1,2,3}.indexer.yml` disable `bootstrap.system_call_filter` for the indexer, working around this same host's kernel lacking `CONFIG_SECCOMP` (OrbStack's Linux VM). Also environment-only: `bootstrap.system_call_filter` is read directly from `opensearch.yml` at native bootstrap time, *before* the entrypoint's generic env-var-to-`-E`-flag passthrough runs — setting it as a plain `environment:` var reaches the container but has no effect, which is why this needed its own yml copy rather than a compose override.
