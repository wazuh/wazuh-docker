# Upgrading Wazuh in Docker

To upgrade your Wazuh deployment when using Docker, the process primarily involves updating the image tags in your `docker-compose.yml` file to the desired version.

Below is a step-by-step example of how to perform this update:

1. **Stop the current deployment**:
   Stop and remove the existing containers.
   ```bash
   docker-compose down
   ```

   > **Important**: Do not add the `-v` flag. It removes the named volumes, including `wazuh-dashboard-config`, which holds the Wazuh dashboard keystore. Losing that keystore regenerates the `wazuh_ai_assistant.encryptionKey` on the next start and makes the data previously encrypted by the AI assistant unreadable.

2. **Update the image tags**:
   Edit your `docker-compose.yml` file and update the `image` field for all Wazuh services to the desired version.

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
   docker-compose up -d
   ```

## Credentials on existing deployments

A deployment created before this change is running on the passwords the images shipped: the OpenSearch demo hashes in the Wazuh indexer, and `wazuh` / `wazuh-wui` in the Wazuh API. Upgrading the image tag does not replace them on its own, because both are stored outside the images, in the security index and in the RBAC database.

- **The Wazuh API accounts are replaced on the first start of the new manager image**, on the master and on each worker. Nothing else is needed.
- **The Wazuh indexer accounts stay as they are.** The new image generates a password for each of them and records it, but the cluster reads its user database only when the security index is created. Load the recorded passwords into the running cluster once, after the upgrade:

  ```bash
  docker compose exec wazuh.indexer /password-tool.sh --all
  docker compose restart wazuh.manager wazuh.dashboard
  ```

  `--all` rotates every account, applies it to the cluster and prints the new passwords. In multi-node, run it on `wazuh1.indexer`, the node that mounts the admin certificate; the change is cluster-wide, and restart every manager node and the dashboard. The restart is what makes those containers read the new service credentials; `docker compose up -d` does not, because nothing in the Compose file changed.

  Until that is done, the deployment still answers to the demo credentials. [Credentials](credentials.md) describes the tool and the rest of the mechanism.

Also note that the Compose files no longer publish the Wazuh indexer port `9200` on the host. A deployment that reached the indexer directly from the host has to add the mapping back, preferably bound to the loopback address.

## Manager self-signed certificate on existing deployments

Manager images built before the per-container certificate change shipped `etc/certs/remoted.pem` and `etc/certs/remoted-key.pem` inside the image, so the pair was copied into the manager `etc` volume the first time the deployment started and is the same in every deployment created from that image.

Upgrading the image tag does not replace it: the volume already holds a pair, and the container never overwrites an existing one. To move an existing deployment onto a certificate of its own, remove both files and restart the manager after the upgrade:

```bash
docker compose exec wazuh.manager rm -f /var/wazuh-manager/etc/certs/remoted.pem \
                                        /var/wazuh-manager/etc/certs/remoted-key.pem
docker compose restart wazuh.manager
```

In multi-node, repeat it for `wazuh.master` and `wazuh.worker`. Agents do not validate this certificate by default, so the rotation does not require any change on the agents.
