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

   Example (update to 5.0.1):

   ```yaml
   services:
     wazuh.manager:
       image: wazuh/wazuh-manager:5.0.1
       ...

     wazuh.indexer:
       image: wazuh/wazuh-indexer:5.0.1
       ...

     wazuh.dashboard:
       image: wazuh/wazuh-dashboard:5.0.1
       ...
   ```

   ### Multi-node configuration
   Update the image tag for the following services in `multi-node/docker-compose.yml`:
   - `wazuh.master`
   - `wazuh.worker`
   - `wazuh1.indexer`, `wazuh2.indexer`, and `wazuh3.indexer`
   - `wazuh.dashboard`

   Example (update to 5.0.1):

   ```yaml
   services:
     wazuh.master:
       image: wazuh/wazuh-manager:5.0.1
       ...

     wazuh.worker:
       image: wazuh/wazuh-manager:5.0.1
       ...

     wazuh1.indexer:
       image: wazuh/wazuh-indexer:5.0.1
       ...

     wazuh2.indexer:
       image: wazuh/wazuh-indexer:5.0.1
       ...

     wazuh3.indexer:
       image: wazuh/wazuh-indexer:5.0.1
       ...

     wazuh.dashboard:
       image: wazuh/wazuh-dashboard:5.0.1
       ...
   ```

3. **Start the updated deployment**:
   Start the containers again. Docker will automatically pull the new images.
   ```bash
   docker-compose up -d
   ```

## Credentials on existing deployments

The Wazuh indexer image no longer ships the OpenSearch demo accounts (`kibanaro`, `logstash`, `readall`, `snapshotrestore`, `anomalyadmin`), but taking them out of the image does not take them out of a deployment that already exists: those accounts live in the security index, which is on a volume and is not rewritten by an upgrade. Delete them from the running cluster one by one, with the security API, and then change every password as on a new deployment:

```bash
# 1. Remove the OpenSearch demo accounts from the cluster. <admin password> is
#    the one this deployment is using, which is 'admin' if it was never changed.
for user in kibanaro logstash readall snapshotrestore anomalyadmin; do
  docker compose exec wazuh.indexer curl -sk -u admin:'<admin password>' \
    -X DELETE "https://localhost:9200/_plugins/_security/api/internalusers/${user}"
done

# 2. Change every password.
docker compose exec wazuh.indexer /password-tool.sh --all
docker compose exec wazuh.manager /password-tool.sh --all
```

Both steps are targeted: they change the accounts they name and leave every other account, role and role mapping alone. In multi-node, run them on `wazuh1.indexer`; the security configuration is cluster-wide. Then write the service passwords into `docker-compose.yml` and recreate the stack, as described in [Credentials](credentials.md).

> **Do not use `/securityadmin.sh` on its own for this.** With no arguments it uploads the whole security configuration of the image, which replaces the one the cluster is running: every internal user that is not in the image is deleted, custom role mappings are reverted, and every password goes back to the default of the image.

Also note that the Compose files no longer publish the Wazuh indexer port `9200` on the host. A deployment that reached the indexer directly from the host has to add the mapping back, preferably bound to the loopback address.

## Manager detection content on existing deployments

The Compose files now mount a named volume on `/var/wazuh-manager/data` (`wazuh_data` in single-node; `master-wazuh-data` and `worker-wazuh-data` in multi-node), so the detection content the manager downloads survives recreating the container. A deployment created before this change did not have it, and nothing carries the old content over: it only ever existed in the writable layer of a container that is now gone.

Take the volume by using the updated `docker-compose.yml` and recreating the stack. Docker creates the volume, fills it from the image, and the manager downloads the ruleset again on that first start. Until it finishes — a few minutes on a healthy indexer — the manager runs with no decoders, exactly as it did on every recreation before. From then on the content is kept.

A deployment that keeps its own `docker-compose.yml` has to add the mount and the volume declaration by hand:

```yaml
services:
  wazuh.manager:
    volumes:
      - wazuh_data:/var/wazuh-manager/data

volumes:
  wazuh_data:
```

In multi-node, add it to both `wazuh.master` and `wazuh.worker`, each with its own volume.
