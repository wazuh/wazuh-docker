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

The Wazuh indexer image no longer ships the OpenSearch demo accounts (`kibanaro`, `logstash`, `readall`, `snapshotrestore`, `anomalyadmin`), but taking them out of the image does not take them out of a deployment that already exists: those accounts live in the security index, which is on a volume and is not rewritten by an upgrade. Removing them takes one extra step, before the password change:

```bash
# 1. Load the user database of the new image into the cluster. The demo
#    accounts are not in it, so they stop existing. Every account is left on
#    the default password of the image, which the next step replaces.
docker compose exec wazuh.indexer /securityadmin.sh

# 2. Change every password, as on a new deployment.
docker compose exec wazuh.indexer /password-tool.sh --all
docker compose exec wazuh.manager /password-tool.sh --all
```

Step 1 puts the cluster on the default passwords for as long as step 2 takes, so run the two together. In multi-node, run both on `wazuh1.indexer`, the node that mounts the admin certificate; the security configuration is cluster-wide. Then write the service passwords into `docker-compose.yml` and recreate the stack, as described in [Credentials](credentials.md).

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
