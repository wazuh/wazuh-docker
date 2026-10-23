# Upgrading Wazuh in Docker

An upgrade replaces the images and keeps everything else. The named volumes hold what each component stored on its first start: the indexer security configuration and data, the manager's Wazuh API user database, keystore, configuration and cluster key, and the dashboard keystore. The deployment directory holds the certificates and `config/credentials/*.env`, which are used as they are. None of them is created again, so do not run `certificates-conf.sh` or `credentials-conf.sh` for an upgrade.

These steps apply between 5.x releases. Upgrading from 4.x, or from 5.0.0 RC 1 or an earlier pre-release, is not supported: see [From 4.x](#from-4x).

## From 4.x

A 4.x deployment cannot be upgraded in place. The 5.0 manager uses other paths (`/var/wazuh-manager` and `/etc/wazuh-manager` instead of `/var/ossec`), a new configuration format and a new agent protocol, so it does not read the 4.x volumes. A deployment of 5.0.0 RC 1 or an earlier pre-release cannot be upgraded either (wazuh/wazuh#40338): deploy 5.0 again with new volumes.

Deploy 5.0 as a new deployment and carry the agents' identity across with the manager's migration tool, `wazuh-migrate-identity.py`. It keeps the agent ids, names and keys, the group membership and the group folders and, optionally, the API users and the enrollment password, so the 4.x agents reconnect without enrolling again. The Wazuh manager guide [Migrating a Wazuh manager from 4.x to 5.0](https://github.com/wazuh/wazuh/blob/v5.0.0/docs/guide/migration/manager-4x-to-5x.md) covers everything else: the configuration, the rules and decoders, upgrading the agents, retiring the legacy channel, and the historical data. The steps below are the Docker part of it, for the single-node deployment. On multi-node, use the volumes and the service of the master (`master-wazuh-etc`, `master-wazuh-queue`, `master-wazuh-api-configuration` and `wazuh.master`).

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
   `check` reports `The target matches the bundle.` The manager logs `Loaded N agent key(s)`, and the 4.x agents connect on `1514` with their existing keys and show as `active`, with their ids, names and groups. The registration date is the date of the import. Keep the 4.x volumes until the migration is complete; the 4.x indexer data stays in them for consultation.

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
