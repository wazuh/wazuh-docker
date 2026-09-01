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
       image: wazuh/wazuh-manager:5.0.0-beta5
       ...

     wazuh.indexer:
       image: wazuh/wazuh-indexer:5.0.0-beta5
       ...

     wazuh.dashboard:
       image: wazuh/wazuh-dashboard:5.0.0-beta5
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
       image: wazuh/wazuh-manager:5.0.0-beta5
       ...

     wazuh.worker:
       image: wazuh/wazuh-manager:5.0.0-beta5
       ...

     wazuh1.indexer:
       image: wazuh/wazuh-indexer:5.0.0-beta5
       ...

     wazuh2.indexer:
       image: wazuh/wazuh-indexer:5.0.0-beta5
       ...

     wazuh3.indexer:
       image: wazuh/wazuh-indexer:5.0.0-beta5
       ...

     wazuh.dashboard:
       image: wazuh/wazuh-dashboard:5.0.0-beta5
       ...
   ```

3. **Start the updated deployment**:
   Start the containers again. Docker will automatically pull the new images.
   ```bash
   docker-compose up -d
   ```

## Manager self-signed certificate on existing deployments

Manager images built before the per-container certificate change shipped `etc/certs/remoted.pem` and `etc/certs/remoted-key.pem` inside the image, so the pair was copied into the manager `etc` volume the first time the deployment started and is the same in every deployment created from that image.

Upgrading the image tag does not replace it: the volume already holds a pair, and the container never overwrites an existing one. To move an existing deployment onto a certificate of its own, remove both files and restart the manager after the upgrade:

```bash
docker compose exec wazuh.manager rm -f /var/wazuh-manager/etc/certs/remoted.pem \
                                        /var/wazuh-manager/etc/certs/remoted-key.pem
docker compose restart wazuh.manager
```

In multi-node, repeat it for `wazuh.master` and `wazuh.worker`. Agents do not validate this certificate by default, so the rotation does not require any change on the agents.
