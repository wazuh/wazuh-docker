# BondLink overlay for wazuh-docker

**Status: live, secrets rotated, not yet merged.** This overlay is the
actual, currently-running production Wazuh deployment — cut over from the
old ad-hoc `/src/wazuh-docker-4.10` fork on 2026-09-17, checked out on this
branch, `4.10-align` (see the History section below for how it got here).
The checkout path is whatever `salt/wazuh-docker/init.sls`'s `checkout_dir`
currently targets (renamed at least once already — check that file rather
than trusting a specific path written here). The PR into
`mblink/wazuh-docker`'s `main` has **not** been opened yet, but its last
precondition — rotating the secrets tracked in this repo *and* the live
cluster's actual passwords/keys to match — is now done (see "Not ported"
below and "Rotating live secrets"). The checked-out production host still
tracks this branch directly until the PR merges and it can be pointed at
`main`.

Purpose: `bondlink/` is a pure compose-overlay carrying forward BondLink's
production customizations (email alerting, warm indexer tier + ISM lifecycle
policy, HTTP-only dashboard behind HAProxy, CloudWatch/cron-backup sidecars,
etc.) on top of this repo's own upstream-tracked `multi-node/docker-compose.yml`
— without ever editing that file directly, which is what keeps this
upstream-mergeable. Stock wazuh-docker (since 4.x) already mounts full
config files via `/wazuh-config-mount`, so the overlay is direct: full
replacement config files layered on top of the base compose file via `-f`.

A separate worktree/branch, `5.0-align` (`/Volumes/Sources/wazuh-docker`,
sharing this same `.git`), is doing the analogous port for the unreleased
5.1.0 line — still blocked on `wazuh/wazuh-manager:5.1.0` and
`wazuh/wazuh-indexer:5.1.0` not being published yet. That'll be the next real
migration once those images ship; this overlay isn't going anywhere until then.

**Next steps** (not yet done, tracked here so they aren't lost):

- Open the PR into `mblink/wazuh-docker`'s `main` — the secrets-rotation
  precondition is done (see "Not ported" below).
- Sync the ~75 commits `4.10-align`'s base is currently behind
  `wazuh/wazuh-docker`'s `main` — the next real chunk of work on this line
  after the PR lands, likely its own branch following the same
  validate-then-cut-over pattern this one did.

## History

This overlay was developed and validated on a branch named `4.10-align` —
not because it ran Wazuh 4.10, but because that name was carried over from
the old ad-hoc fork's directory (`/src/wazuh-docker-4.10`), which had itself
been manually upgraded over time to actually run 4.14.0 in production
without ever being renamed. The branch's base commit *was* upstream's
`v4.14.0` tag exactly, plus the commits that added, live-validated, and
eventually cut production over to this overlay on 2026-09-17 (see "Live
validation results" below for the pre-cutover validation). Production runs
this branch directly (see `salt/wazuh-docker/init.sls`'s `checkout_dir` for
the current path — it's been renamed at least once, most recently on
2026-09-18 while chasing the bind-mount/git-checkout conflict described in
"Rotating live secrets"); the branch has not yet been merged into `main` or
opened as a PR against `mblink/wazuh-docker`, but the secrets rotation that
was the last blocker for that is now done, live, and validated (cluster
green, dashboard login, API connectivity, agent data flowing).

## Repository structure

This repo is a real fork of `wazuh/wazuh-docker` (`git remote -v` shows
`origin` = `mblink/wazuh-docker`, `upstream` = `wazuh/wazuh-docker`) with full,
non-squashed shared history — not a copied/vendored snapshot. `bondlink/` is
a pure compose-overlay (see Usage below) that never edits upstream-tracked
files, which is what keeps this "upstream-mergeable": there is nothing in the
overlay design that upstream releases can conflict with, short of upstream
relocating a file path this overlay hardcodes (has happened once, see the
sync section below).

Keeping this as one repo with `upstream` as a remote (rather than splitting
the overlay into its own repo that vendors `wazuh-docker` via a submodule or
subtree) is the deliberate choice: it gives clean 3-way merges against real
upstream tags, avoids submodule detached-HEAD foot-guns, and matches
`bondlink/`'s own design goal of staying a non-invasive layer on top of
upstream's own compose-override extension point. `main` and the `5.0-align`
branch (`/Volumes/Sources/wazuh-docker`, tracking unreleased 5.1.0) are
separate git worktrees sharing this one `.git`, specifically so each
branch's own `bondlink/` content never mixes with the other's.

## Usage

Run from this worktree's root:

```
docker compose \
  --env-file /etc/wazuh-docker-runtime/bondlink/.env.secrets \
  -f multi-node/docker-compose.yml \
  -f bondlink/docker-compose.override.yml \
  up -d
```

`--env-file` is required, not optional, and points at `/etc/wazuh-docker-
runtime/` (salt-rendered, outside this git checkout — see "Rotating live
secrets" for why it lives there rather than at `bondlink/.env.secrets`
directly), not this checkout. It's what resolves the
`${API_PASSWORD}`/`${INDEXER_PASSWORD}`/etc. `${VAR}` substitutions in
`bondlink/docker-compose.override.yml`'s `environment:` blocks (salt-rendered
by `salt/wazuh-docker/init.sls`'s `wazuh-docker-env-secrets` state) --
deliberately *not* `env_file:` on those services, since
`multi-node/docker-compose.yml` already sets these same keys via its own
`environment:` entries, and Compose's `environment:` always wins over
`env_file:` for a shared key regardless of which merged file it came from.
Without `--env-file`, the `${VAR}` references resolve to empty strings, not
silently to the upstream stock example values.

Cert generation (run once per checkout, before `up`, after adding
wazuh-warm1.indexer to bondlink/config/certs.yml). **Certs are gitignored
and live under `multi-node/config/wazuh_indexer_ssl_certs/`, inside this
checkout** — they do not survive a move to a different checkout directory
(confirmed live 2026-09-18, moving to a renamed checkout: every missing
`.pem` bind-mount source got silently auto-created by Docker as an empty
*directory* instead of erroring, which then made the generator's own `cp`
step fail with `cannot overwrite directory ... with non-directory` for
whichever certs it reached first). If you ever move or recreate this
checkout, clear any such empty-directory stubs first
(`find multi-node/config/wazuh_indexer_ssl_certs -mindepth 1 -maxdepth 1
-type d -empty -exec rmdir {} +`), then generate fresh:

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

Always sanity-check a merged config before applying changes (include
`--env-file` here too, or the API/DASHBOARD/INDEXER credential fields will
show as empty rather than reflecting what actually gets passed to `up`):

```
docker compose --env-file /etc/wazuh-docker-runtime/bondlink/.env.secrets -f multi-node/docker-compose.yml -f bondlink/docker-compose.override.yml config
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
- **`root-ca.pem`, not `root-ca-manager.pem`**, mounted into `wazuh.master`/`wazuh.worker`'s `/etc/ssl/root-ca.pem`. **Fixed**: both the source and upstream's own stock `multi-node/docker-compose.yml` reference `root-ca-manager.pem` there, but nothing — not the cert-generator, not any README, not upstream's own docs — ever produces a file by that name. It's the same cluster-wide root CA every other service already mounts under its real name; confirmed live that there's no actual second cert, just an undocumented manual-copy step from some earlier setup that broke the first time a fresh checkout needed certs generated from scratch.
- **CloudWatch-agent / cron-backup sidecars**: `build/cloudwatch-agent/`, `build/cron-backup/`. **Fixed three real bugs**: (1) cron-backup's `ENTRYPOINT` was commented out in the source, so the container fell back to alpine's default shell and exited immediately — with `restart: always` it crash-looped forever and the daily S3 backup never actually ran; restored. (2) cloudwatch-agent's `jq` filter wrapped `${VAR}` in single quotes, so the build args for log group/stream/region were never actually interpolated and the agent silently used hardcoded template values instead; switched to `jq --arg`. (3) Both images were built to shadow the public `amazon/cloudwatch-agent` and `alpine:latest` tags — fragile on any host running unrelated containers under those names; renamed to `bondlink/wazuh-cwagent:4.10-align` and `bondlink/wazuh-cron-backup:4.10-align`, built directly via `build:` in the override (no separate `build-images.yml`/`build-images.sh` needed — that file's own bug, silently wiping the sidecar env vars from `.env` on rebuild, is sidestepped entirely by putting the build args directly in the compose override).

## Not ported (deliberately out of scope for this overlay)

- `index_scripts/` (reindex/legacy-agent-ID remap) and `volume-migrator.sh` — one-time historical data-migration tools tied to a specific past cutover (the `prodmonitor` → `wazuh.master` migration), not general features.
- **Secrets rotation — done, tracked files and the live cluster.**
  The real Wazuh cluster key and indexer datasources masterkey used to be
  plaintext in tracked files here (`config/wazuh_cluster/*.conf`,
  `config/wazuh_indexer/*.yml`), reused as the *same* value across two
  unrelated purposes on top of the exposure itself. Both are now an obvious
  placeholder (`__WAZUH_CLUSTER_KEY__` / `__WAZUH_INDEXER_DATASOURCES_KEY__`)
  in every tracked copy (including `local-test-only/`); the Wazuh API,
  dashboard (`kibanaserver`), and indexer (`admin`) credentials now live in
  the salt `wazuh-cluster-configuration` pillar instead of an unset/stock
  compose override. The salt state (`salt/wazuh-docker/init.sls` in the salt
  repo) renders the real values into `/etc/wazuh-docker-runtime/` on every
  highstate — two new, distinct random values for the cluster key/masterkey
  (they no longer share one value), plus a gitignored `bondlink/.env.secrets`
  (also rendered there) consumed via `${VAR}` substitution in
  `bondlink/docker-compose.override.yml`'s `environment:` blocks (requires
  `--env-file /etc/wazuh-docker-runtime/bondlink/.env.secrets` on every
  `docker compose` invocation — see Usage above; `env_file:` doesn't work
  here since `multi-node/docker-compose.yml` already sets these same keys
  directly) — so none of it is tracked in git going forward. The live
  production cluster was rotated to match on 2026-09-18 and validated:
  cluster green, dashboard login with the new credentials, API connectivity,
  agent data flowing. See "Rotating live secrets" below for how, including
  two real bugs hit and fixed along the way (a bind-mount/git-checkout
  conflict, and a username mismatch on the dashboard's backend account).
- `internal_users.yml` — unmodified from stock; the source fork never touched it either, so nothing to port.

## Rotating live secrets

Rendering new credentials to disk (via the salt state) and restarting a
service are **not** the same thing for every credential here. Some take
effect immediately on restart; the indexer's own `admin`/`kibanaserver`
passwords don't, and skipping this step breaks Filebeat/vulnerability-
detection auth and dashboard login the moment you restart with new values.

**Where the rendered files actually live**: `wazuh_manager.conf`,
`wazuh_worker.conf`, the indexer ymls, and `wazuh.yml` are all bind-mounted
into a container *by file*, not by directory. Docker's file-level bind
mount turns that host path into a real mount point for as long as the
container holding it is running (confirmed directly via
`/proc/1/mountinfo`), and you can't `unlink` a mount point — which is
exactly what `git`'s own checkout mechanism needs to do on every
`force_reset`. Pointing a live bind mount straight at a path inside this
checkout means the checkout step itself randomly fails ("device or
resource busy") any time the corresponding container happens to be running
when salt applies — confirmed live on production. So the salt state
renders these files into `/etc/wazuh-docker-runtime/` instead (outside the
git checkout entirely) and `docker-compose.override.yml`/
`docker-compose-warm.yml` mount from there — the checkout itself is never
bind-mounted into anything, so it can always be freely refreshed.

**Why**: `INDEXER_USERNAME`/`INDEXER_PASSWORD` and `DASHBOARD_USERNAME`/
`DASHBOARD_PASSWORD` only configure what `wazuh.master`/`wazuh.worker`/
`wazuh.dashboard` *present* when authenticating to the indexer. The
indexer's own security index — what it actually *accepts* — is seeded once
from `multi-node/config/wazuh_indexer/internal_users.yml` at first bootstrap
and is never touched again by an env var change or a config re-render. On
any indexer that's already bootstrapped (which is every real deployment
except a genuinely fresh volume), changing `INDEXER_PASSWORD`/
`DASHBOARD_PASSWORD` and restarting does nothing but break auth until the
live security index is updated to match.

**How**: `bondlink/scripts/rotate-indexer-secrets.sh` pushes the new
`admin`/`kibanaserver` passwords (read from `/etc/wazuh-docker-runtime/
bondlink/.env.secrets`, already salt-rendered) into the *live* security
index via the OpenSearch Security
REST API, authenticated with the `admin_dn` client cert — the same mTLS
bypass `snapshot_index.py`'s `restore_snapshot()`/`delete_snapshot()` already
use for the same reason (it works regardless of what the *current* password
is, so the script never needs to know it):

```
bondlink/scripts/rotate-indexer-secrets.sh                  # localhost:9200
bondlink/scripts/rotate-indexer-secrets.sh wazuh1.indexer:9200
```

**Full rollout order** (staging or production — the only difference is
whether production needs the master/worker/indexer/dashboard restarts done
one host at a time to avoid a full outage):

1. Apply the salt `wazuh-docker` state — renders `.env.secrets` and the
   cluster key/masterkey-substituted conf/yml files into
   `/etc/wazuh-docker-runtime/`. Nothing is restarted yet, and nothing in
   this checkout's own tracked files changes.
2. Run `bondlink/scripts/rotate-indexer-secrets.sh` against a running
   indexer — pushes the new `admin`/`kibanaserver` passwords live, before
   anything else changes. Do this *before* step 3, or there's a window where
   the manager/dashboard already expect the new password but the indexer
   doesn't accept it yet.
3. `wazuh-wui`'s password now keeps itself in sync automatically — no
   manual step needed here. Salt's `wazuh-docker-wazuh-yml-api-password`
   state rewrites `wazuh.yml`'s password field (in `/etc/wazuh-docker-
   runtime/`, not this checkout — see below) to match `API_PASSWORD` on
   every highstate, and the manager's own `create_user.py` unconditionally
   re-applies `API_PASSWORD` to the real `wazuh-wui` account on every boot.
   As long as step 4 restarts `wazuh.master` and step 6 restarts
   `wazuh.dashboard`, both sides land on the same password with nothing
   manual required.

   The one thing that still has to hold: the target password must satisfy
   the Wazuh API's own complexity policy (8–64 chars, upper/lower/digit,
   and a symbol from its allowed set) — confirmed live, a manager whose
   `create_user.py` rejects the configured password with `WazuhError 5007`
   never actually applies it, silently leaving the *previous* real
   password in place while everything else proceeds as if the rotation
   succeeded. Nothing in that path surfaces as an obvious error later; it
   just shows up as unexplained `401`s the next time something tries to
   log in.

   If you need the new password live *without* restarting `wazuh.master`
   (an emergency rotation, say), push it directly via the Wazuh Manager
   API instead, authenticated with the *current* `wazuh-wui` credentials —
   no restart needed for this path, but it only updates the manager's
   real password, not `wazuh.yml`'s copy, so the dashboard will still need
   a restart afterward to pick it up:

   ```
   TOKEN=$(curl -sk -u "wazuh-wui:${OLD_API_PASSWORD}" \
     -X POST "https://wazuh.master:55000/security/user/authenticate" \
     | jq -r .data.token)

   USER_ID=$(curl -sk -H "Authorization: Bearer ${TOKEN}" \
     "https://wazuh.master:55000/security/users?search=wazuh-wui" \
     | jq -r '.data.affected_items[0].id')

   curl -sk -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' \
     -X PUT "https://wazuh.master:55000/security/users/${USER_ID}" \
     -d "{\"password\": \"${API_PASSWORD}\"}"
   ```
4. Restart `wazuh.master` + `wazuh.worker` together — new cluster key (must
   match on both) and new `INDEXER_USERNAME`/`PASSWORD`, which the indexer
   now actually accepts from step 2.
5. Restart the indexer nodes — new
   `plugins.query.datasources.encryption.masterkey`. Low risk: confirm no
   configured datasources exist first (`_plugins/_query/_datasources`)
   before rotating, since nothing here currently appears to use OpenSearch's
   external-datasources feature.
6. Restart `wazuh.dashboard` — new `API_PASSWORD`/`DASHBOARD_PASSWORD`, both
   already live from steps 2-3.
7. Validate: `_cluster/health` green, dashboard login with the new admin
   password, API connectivity, Filebeat shipping resumes, agent data still
   flowing.

On a genuinely fresh volume wipe (`docker compose down -v`, e.g. disposable
staging), `internal_users.yml`'s stock hash is still what the indexer boots
with — step 2 is exactly as necessary there as it is on a live, never-wiped
cluster, since nothing about a fresh bootstrap changes what's baked into
that file. That makes a wiped staging bring-up a faithful rehearsal of the
real production sequence above, not a shortcut around it.

## Warm-host deployment note

`docker-compose-warm.yml` expects `./config/wazuh_indexer_ssl_certs/{root-ca,wazuh-warm1.indexer,wazuh-warm1.indexer-key,admin,admin-key}.pem` and `./config/wazuh_indexer/internal_users.yml` relative to wherever it's run, plus `/etc/wazuh-docker-runtime/wazuh-warm1.indexer.yml` (an absolute path, not relative to this compose file). Since the warm node deploys on a separate host — one this salt state doesn't manage — copy these over manually: the certs and `internal_users.yml` alongside this compose file as before (the cert-generator step above produces the `.pem` files on the main host under `multi-node/config/wazuh_indexer_ssl_certs/`), and `wazuh-warm1.indexer.yml` from the main host's `/etc/wazuh-docker-runtime/wazuh-warm1.indexer.yml` (already salt-rendered with the real masterkey) to the same absolute path on the warm host. Re-copy that last file after any masterkey rotation.

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

**Initially misdiagnosed, corrected 2026-09-17**: our ported `ossec.conf` carried forward `<wodle name="cis-cat"><disabled>no</disabled>` from the source fork. The stock `wazuh-manager:4.14.0` image ships neither the CIS-CAT benchmark content (`wodles/ciscat`) nor a JRE (`wodles/java`) — confirmed both paths don't exist in the image, and also confirmed missing on production's real manager. Enabling it under this dev machine's QEMU x86_64-on-arm64 emulation appeared to segfault `wazuh-modulesd`, so it was disabled here for a while — but the very next paragraph (unchanged since the original testing) already showed that same segfault happens even with a completely bare, wodle-free config under this emulation, which in hindsight should have ruled out CIS-CAT as the cause from the start. Confirmed live on production's real x86_64 hardware: `wazuh-control status` shows `wazuh-modulesd` running fine with cis-cat enabled and the content missing — no crash, no cis-cat log activity at all (it just doesn't produce real scan results without the actual content, silently). Re-enabled for exact parity with production; see the comment in `config/wazuh_cluster/wazuh_manager.conf`.

**Could not fully validate manager-daemon startup here — environment limitation, not a port defect**: `wazuh-modulesd` segfaults under this Mac's QEMU x86_64-on-arm64 emulation during its own pre-flight config self-test (`wazuh-modulesd -t`), which blocks `wazuh-control` from starting *any* manager daemon (analysisd, remoted, etc. — confirmed via `wazuh-control status`). Isolated this by testing `wazuh-modulesd -t` against a bare-minimum config with no wodles at all — it segfaults identically regardless of cis-cat's state, confirming this is a pure emulation artifact, not caused by our config content. `wazuh-analysisd -t` and `wazuh-logcollector -t` both pass cleanly against our real config. `wazuh/wazuh-manager:4.14.0` is a single-platform (amd64-only) image (`docker manifest inspect` confirms no arm64 variant), so this emulation path is unavoidable on Apple Silicon and does not reproduce on real x86_64 hardware (confirmed on production). If you need to validate manager-daemon startup locally, do it on an amd64 host/VM rather than under QEMU emulation.

**Local-only test scaffolding** (not part of the actual port, kept for future testers on similar hardware): `bondlink/docker-compose.local-test-only.yml` + `bondlink/local-test-only/wazuh{1,2,3}.indexer.yml` disable `bootstrap.system_call_filter` for the indexer, working around this same host's kernel lacking `CONFIG_SECCOMP` (OrbStack's Linux VM). Also environment-only: `bootstrap.system_call_filter` is read directly from `opensearch.yml` at native bootstrap time, *before* the entrypoint's generic env-var-to-`-E`-flag passthrough runs — setting it as a plain `environment:` var reaches the container but has no effect, which is why this needed its own yml copy rather than a compose override.
