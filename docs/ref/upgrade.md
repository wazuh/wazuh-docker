# Upgrading Wazuh in Docker

An upgrade replaces the images and keeps everything else. The named volumes hold what each component stored on its first start: the indexer security configuration and data, the manager's Wazuh API user database, keystore, configuration and cluster key, and the dashboard keystore. The deployment directory holds the certificates and `config/credentials/*.env`, which are used as they are. None of them is created again, so do not run `certificates-conf.sh` or `credentials-conf.sh` for an upgrade.

These steps apply between 5.x releases. Upgrading from 4.x, or from 5.0.0 RC 1 or an earlier pre-release, is not supported: see [From 4.x](#from-4x).

## From 4.x

A 4.x deployment cannot be upgraded in place. The 5.0 manager uses other paths (`/var/wazuh-manager` and `/etc/wazuh-manager` instead of `/var/ossec`), a new configuration format and a new agent protocol, so it does not read the 4.x volumes. A deployment of 5.0.0 RC 1 or an earlier pre-release cannot be upgraded either (wazuh/wazuh#40338): deploy 5.0 again with new volumes.

Deploy 5.0 as a new deployment and carry the agents' identity across with the manager's migration tool, `wazuh-migrate-identity.py`. It keeps the agent ids, names and keys, the group membership and the group folders and, optionally, the API users and the enrollment password, so the 4.x agents reconnect without enrolling again. The Wazuh manager guide [Migrating a Wazuh manager from 4.x to 5.0](https://github.com/wazuh/wazuh/blob/v5.0.0/docs/guide/migration/manager-4x-to-5x.md) covers everything else: the configuration, the rules and decoders, upgrading the agents, retiring the legacy channel, and the historical data. The steps below are the Docker part of it, for the single-node deployment. On multi-node, use the volumes and the service of the master (`master-wazuh-etc`, `master-wazuh-queue`, `master-wazuh-api-configuration` and `wazuh.master`), and the override of step 3 for multi-node. [Configuration and content](#configuration-and-content) says where the input of the rest of the guide is in a 4.x Docker deployment and where 5.0 takes it.

Run the tool with the Python the manager bundles, as the steps below do: the 5.0 manager image has no `python3` on its `PATH`, so `./wazuh-migrate-identity.py` fails with `env: 'python3': No such file or directory`. The image has no `sqlite3` or `ssh` either; the manual procedure of the manager guide does not apply to Docker.

To keep the 4.x alerts available in 5.0, take the snapshot of [Historical data](#historical-data) before step 1.

1. **Stop the 4.x deployment**, keeping its volumes, and list them:
   ```bash
   cd <4.x checkout>/single-node
   docker compose down
   docker volume ls --filter name=wazuh_
   ```
   Compose prefixes each volume with the project name, which is the directory name by default (`single-node_wazuh_etc`, `single-node_wazuh_queue` and `single-node_wazuh_api_configuration`).

2. **Export the identity** with a one-off container of your 4.x manager image, which runs the tool with the Python it bundles. Use the tag of your 4.x deployment:
   ```bash
   curl -fsSLo wazuh-migrate-identity.py https://raw.githubusercontent.com/wazuh/wazuh/v5.0.0/tools/migration/wazuh-migrate-identity.py
   mkdir wazuh-4x-bundle
   sudo docker run --rm --entrypoint /var/ossec/framework/python/bin/python3 \
     -v single-node_wazuh_etc:/var/ossec/etc:ro \
     -v single-node_wazuh_queue:/var/ossec/queue:ro \
     -v single-node_wazuh_api_configuration:/var/ossec/api/configuration:ro \
     -v "$PWD/wazuh-migrate-identity.py:/wazuh-migrate-identity.py:ro" \
     -v "$PWD/wazuh-4x-bundle:/bundle" \
     wazuh/wazuh-manager:4.14.9 /wazuh-migrate-identity.py export /bundle/identity --with-rbac
   ```
   `--with-rbac` carries the API users, roles and policies, and `--with-password` the enrollment password, which only 4.x agents that still have to enroll need. The bundle holds agent keys and password hashes: handle it like a credential.

3. **Deploy 5.0 under another Compose project name.** The 5.0 Compose files use the same volume names as 4.x, so a 5.0 deployment in another `single-node` directory would mount the 4.x volumes. Follow [Single-node deployment](getting-started/deployment/single-node.md) in a new checkout, give the manager node the address the 4.x agents connect to, and before the first `docker compose` command set another project name:
   ```bash
   echo "COMPOSE_PROJECT_NAME=wazuh-5" > .env
   ```
   Start it without publishing the manager ports, so no agent reaches the manager before its registry is restored. This needs Docker Compose 2.24 or later:
   ```bash
   printf 'services:\n  wazuh.manager:\n    ports: !reset []\n' > docker-compose.migration.yml
   docker compose -f docker-compose.yml -f docker-compose.migration.yml up -d
   ```
   On multi-node, the agent ports `1514` and `1517` are published by `nginx`, not by the managers, so the override resets both services; start the deployment with the same `docker compose` command:
   ```bash
   printf 'services:\n  wazuh.master:\n    ports: !reset []\n  nginx:\n    ports: !reset []\n' > docker-compose.migration.yml
   ```
   With the override, `docker compose ps` shows no published port on `wazuh.master` or `nginx`.

   Until step 5, the 4.x agents log `(1216): Unable to connect` and keep retrying.

4. **Import the identity** into the 5.0 manager, through its API on loopback, with the `wazuh` password of the 5.0 deployment:
   ```bash
   sudo docker compose cp <4.x checkout>/single-node/wazuh-4x-bundle/identity wazuh.manager:/tmp/identity
   sudo docker compose cp <4.x checkout>/single-node/wazuh-migrate-identity.py wazuh.manager:/tmp/
   sudo sed -n 's/^WAZUH_MANAGER_API_PASSWORD=//p' config/credentials/manager.env | \
     docker compose exec -T wazuh.manager /var/wazuh-manager/framework/python/bin/python3 \
       /tmp/wazuh-migrate-identity.py import /tmp/identity --with-rbac --api-password-file -
   ```
   Run it with `--dry-run` first. The API certificate is verified against `/etc/wazuh-manager/certs/root-ca.pem`, which the deployment mounts. The import ends with `Inserted N of N agent(s)`.

5. **Open the manager to the agents**: start the deployment without the override. This recreates the manager with its ports published, and removes the copies from `/tmp`:
   ```bash
   docker compose up -d
   ```
   With `--with-rbac`, the `wazuh` and `wazuh-internal-client` users now have their 4.x passwords, and the dashboard, which uses the one in `config/credentials`, cannot log in. Set both back:
   ```bash
   sudo sed -n 's/^WAZUH_MANAGER_API_PASSWORD=//p' config/credentials/manager.env | \
     docker compose exec -T wazuh.manager /var/wazuh-manager/bin/rbac_control change-password -u wazuh -p -
   sudo sed -n 's/^WAZUH_MANAGER_WUI_PASSWORD=//p' config/credentials/manager.env | \
     docker compose exec -T wazuh.manager /var/wazuh-manager/bin/rbac_control change-password -u wazuh-internal-client -p -
   ```
   Your own API users keep their 4.x passwords.

6. **Check the result**, then delete the bundle:
   ```bash
   sudo docker compose cp <4.x checkout>/single-node/wazuh-4x-bundle/identity wazuh.manager:/tmp/identity
   sudo docker compose cp <4.x checkout>/single-node/wazuh-migrate-identity.py wazuh.manager:/tmp/
   sudo sed -n 's/^WAZUH_MANAGER_API_PASSWORD=//p' config/credentials/manager.env | \
     docker compose exec -T wazuh.manager /var/wazuh-manager/framework/python/bin/python3 \
       /tmp/wazuh-migrate-identity.py check /tmp/identity --api-password-file -
   docker compose exec wazuh.manager rm -rf /tmp/identity /tmp/wazuh-migrate-identity.py
   sudo rm -rf <4.x checkout>/single-node/wazuh-4x-bundle
   ```
   `check` reports `The target matches the bundle.` The manager logs `Loaded N agent key(s)` in `/var/wazuh-manager/logs/wazuh-manager.log` (`docker compose exec wazuh.manager grep 'agent key' /var/wazuh-manager/logs/wazuh-manager.log`), and the 4.x agents connect on `1514` with their existing keys and show as `active`, with their ids, names and groups. The registration date is the date of the import. On multi-node, the worker logs `claims agent ID '<id>', which is not registered` for a few seconds after this step, until it receives the keys from the master. Keep the 4.x volumes until the migration is complete. The 4.x indexer data stays in them, but the 5.0 indexer does not read it: see [Historical data](#historical-data).

### Configuration and content

5.0 does not read any 4.x configuration file: each one is rewritten following the manager guide, and none of the 4.x mounted files is mounted again. Read the running 4.x configuration from the `etc` volume, not from `config/wazuh_cluster/`: the mounted `ossec.conf` is not always applied to `/var/ossec/etc/ossec.conf`. A one-off container with the 4.x image and the volumes mounted read-only, as in step 2, gives access to them while 4.x is stopped.

| 4.x source | 4.x path | 5.0 destination |
|---|---|---|
| `wazuh_etc` volume | `/var/ossec/etc/ossec.conf`, `local_internal_options.conf` | `wazuh-manager.conf` and `wazuh-manager-internal-options.conf`, rewritten as the [Manager configuration migration](https://github.com/wazuh/wazuh/blob/v5.0.0/docs/guide/migration/manager-configuration-migration.md) guide says. Mount the new `wazuh-manager.conf` at `/wazuh-config-mount/etc/wazuh-manager.conf` |
| `wazuh_etc` volume | `/var/ossec/etc/rules`, `decoders`, `lists` | Rewritten as detection rules, engine decoders and KVDBs: [rules](https://github.com/wazuh/wazuh/blob/v5.0.0/docs/guide/migration/rules-4x-to-5x.md), [decoders](https://github.com/wazuh/wazuh/blob/v5.0.0/docs/guide/migration/xml-decoders-migration.md), [CDB lists](https://github.com/wazuh/wazuh/blob/v5.0.0/docs/guide/migration/cdb-to-kvdb-migration.md) |
| `wazuh_etc` volume | `/var/ossec/etc/shared/<group>/` | Carried by `wazuh-migrate-identity.py`. Each `agent.conf` must be valid for 5.0 |
| `wazuh_api_configuration` volume | `/var/ossec/api/configuration/api.yaml` | `/var/wazuh-manager/api/configuration/api.yaml`, through `/wazuh-config-mount/api/configuration/api.yaml` |
| `config/wazuh_indexer/wazuh.indexer.yml` | `/usr/share/wazuh-indexer/config/opensearch.yml` | Environment variables with the setting name on the indexer service, or a 5.0 `opensearch.yml`. The 4.x file names other certificate files and cannot be reused |
| `config/wazuh_indexer/internal_users.yml` | `.../opensearch-security/internal_users.yml` | Not mounted. The shipped accounts take their passwords from `config/credentials/indexer.env` (see [Credentials](credentials.md)); create your own users through the security API |
| `config/wazuh_dashboard/opensearch_dashboards.yml` | `/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml` | Environment variables on the dashboard service, or a 5.0 file mounted at the same path |
| `config/wazuh_dashboard/wazuh.yml` | `/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml` | None: there is no `wazuh.yml` in 5.x. The API URL is `WAZUH_API_URL` |

On multi-node, the manager files are on `master-wazuh-etc` and `master-wazuh-api-configuration`, and the indexer files are `wazuh1.indexer.yml` to `wazuh3.indexer.yml`.

A file mounted into the 5.0 indexer or dashboard must be owned by `root`, group `101`, mode `0640`; with the owner and mode a 4.x file had on the host, the container stops with `UNSAFE <path>: ...`. See the note in [Configuration files](configuration/configuration-files.md). Validate the manager configuration before restarting the manager:

```bash
docker compose exec wazuh.manager /var/wazuh-manager/bin/wazuh-manager-conf validate
```

### Historical data

The 5.0 indexer does not read the 4.x indices, and the 4.x indexer is stopped in step 1. To consult the 4.x alerts from 5.0, take a snapshot of them into a host folder while 4.x is still running, and restore it into the 5.0 indexer after step 6.

1. **Before step 1**, in the 4.x deployment, add `path.repo` to the indexer configuration and mount a folder at that path. The 4.x indexer does not read settings from environment variables, and the shipped single-node `wazuh.indexer.yml` has no newline at the end, so the setting starts with one:
   ```bash
   cd <4.x checkout>/single-node
   printf '\npath.repo: ["/mnt/snapshots"]\n' >> config/wazuh_indexer/wazuh.indexer.yml
   mkdir wazuh-4x-snapshots
   sudo chown 1000:1000 wazuh-4x-snapshots
   printf 'services:\n  wazuh.indexer:\n    volumes:\n      - ./wazuh-4x-snapshots:/mnt/snapshots\n' > docker-compose.snapshot.yml
   docker compose -f docker-compose.yml -f docker-compose.snapshot.yml up -d wazuh.indexer
   ```
   Register the folder and take the snapshot, with the 4.x `admin` password:
   ```bash
   curl -sk -u admin:<4.x admin password> -X PUT https://localhost:9200/_snapshot/wazuh-4x \
     -H 'Content-Type: application/json' -d '{"type":"fs","settings":{"location":"/mnt/snapshots"}}'
   curl -sk -u admin:<4.x admin password> -X PUT 'https://localhost:9200/_snapshot/wazuh-4x/alerts-4x?wait_for_completion=true' \
     -H 'Content-Type: application/json' -d '{"indices":"wazuh-alerts-4.x-*","include_global_state":false}'
   ```
   The snapshot ends with `"state":"SUCCESS"`. Add `wazuh-states-*` to `indices` to keep the 4.x inventory too.

2. **After step 6**, in the 5.0 deployment, mount the same folder in the indexer, read-only, and set `path.repo` as an environment variable:
   ```bash
   printf 'services:\n  wazuh.indexer:\n    environment:\n      - path.repo=/mnt/snapshots\n    volumes:\n      - <4.x checkout>/single-node/wazuh-4x-snapshots:/mnt/snapshots:ro\n' > docker-compose.restore.yml
   docker compose -f docker-compose.yml -f docker-compose.restore.yml up -d wazuh.indexer
   ```
   When the indexer is `healthy`, register the folder read-only and restore the snapshot under another name:
   ```bash
   ADMIN_PASSWORD=$(sudo sed -n 's/^WAZUH_INDEXER_ADMIN_PASSWORD=//p' config/credentials/indexer.env)
   docker compose exec -T wazuh.indexer curl -sk -u "admin:$ADMIN_PASSWORD" -X PUT https://localhost:9200/_snapshot/wazuh-4x \
     -H 'Content-Type: application/json' -d '{"type":"fs","settings":{"location":"/mnt/snapshots","readonly":true}}'
   docker compose exec -T wazuh.indexer curl -sk -u "admin:$ADMIN_PASSWORD" -X POST 'https://localhost:9200/_snapshot/wazuh-4x/alerts-4x/_restore?wait_for_completion=true' \
     -H 'Content-Type: application/json' -d '{"indices":"wazuh-alerts-4.x-*","include_global_state":false,"rename_pattern":"(.+)","rename_replacement":"restored-$1"}'
   docker compose exec -T wazuh.indexer curl -sk -u "admin:$ADMIN_PASSWORD" 'https://localhost:9200/_cat/indices/restored-*?v&h=health,index,docs.count'
   ```
   Then run `docker compose up -d` without the override. The restored indices stay in the 5.0 indexer volume.

On multi-node, add `path.repo` to `wazuh1.indexer.yml`, `wazuh2.indexer.yml` and `wazuh3.indexer.yml`, and mount the folder in the three indexer services on both sides: a snapshot repository has to be reachable from every node. Run the `curl` commands against `wazuh1.indexer`.

## Between 5.x releases

1. **Stop the current deployment**:
   Stop and remove the existing containers.
   ```bash
   docker compose down
   ```

   > **Important**: Do not add the `-v` flag. It removes the named volumes, and with them the stored credentials, the indexer data and the dashboard keystore. The next start would take the passwords from `config/credentials/*.env` again and generate a new `wazuh_ai_assistant.encryptionKey`, which makes the data previously encrypted by the AI assistant unreadable.

2. **Update the image tags**:
   Edit your `docker-compose.yml` file and update the `image` field for all Wazuh services to the desired version.
   If the new release also changes `docker-compose.yml`, take the new file and apply your own changes to it again, rather than only changing the tags.

   ### Single-node configuration
   Update the image tag for the following services in `single-node/docker-compose.yml`:
   - `wazuh.manager`
   - `wazuh.indexer`
   - `wazuh.dashboard`

   Example (update to 5.0.0):

   ```yaml
   services:
     wazuh.manager:
       image: wazuh/wazuh-manager:5.0.0
       ...

     wazuh.indexer:
       image: wazuh/wazuh-indexer:5.0.0
       ...

     wazuh.dashboard:
       image: wazuh/wazuh-dashboard:5.0.0
       ...
   ```

   ### Multi-node configuration
   Update the image tag for the following services in `multi-node/docker-compose.yml`:
   - `wazuh.master`
   - `wazuh.worker`
   - `wazuh1.indexer`, `wazuh2.indexer`, and `wazuh3.indexer`
   - `wazuh.dashboard`

   Example (update to 5.0.0):

   ```yaml
   services:
     wazuh.master:
       image: wazuh/wazuh-manager:5.0.0
       ...

     wazuh.worker:
       image: wazuh/wazuh-manager:5.0.0
       ...

     wazuh1.indexer:
       image: wazuh/wazuh-indexer:5.0.0
       ...

     wazuh2.indexer:
       image: wazuh/wazuh-indexer:5.0.0
       ...

     wazuh3.indexer:
       image: wazuh/wazuh-indexer:5.0.0
       ...

     wazuh.dashboard:
       image: wazuh/wazuh-dashboard:5.0.0
       ...
   ```

3. **Start the updated deployment**:
   Start the containers again. Docker will automatically pull the new images.
   ```bash
   docker compose up -d
   ```

4. **Check the deployment**:
   ```bash
   docker compose ps
   ../tools/tests/check-default-credentials.sh
   ```
   Every service is `healthy` and the check passes. The accounts keep the passwords they had: see [Credentials](credentials.md).

## Dashboard verification of the indexer

From 5.0.0 the dashboard verifies the indexer hostname (`OPENSEARCH_SSL_VERIFICATION_MODE` defaults to `full`; it was `certificate`). The dashboard writes the setting on every start, so an upgraded deployment uses it even though `opensearch_dashboards.yml` is kept on the `wazuh-dashboard-config` volume. A deployment that keeps the shipped `OPENSEARCH_HOSTS` needs no change. If you changed it, check before upgrading that every host it lists is in the certificate your indexer service mounts as `indexer.pem`. On the shipped single-node deployment:

```bash
openssl x509 -in config/wazuh_indexer/certs/wazuh.indexer.pem -noout -ext subjectAltName
```

On multi-node, check `config/wazuh1_indexer/certs/wazuh1.indexer.pem` to `config/wazuh3_indexer/certs/wazuh3.indexer.pem` the same way. See [Dashboard verification of the indexer](security.md#dashboard-verification-of-the-indexer) for what to do when a host is missing.
