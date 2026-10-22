# Upgrading Wazuh in Docker

An upgrade replaces the images and keeps everything else. The named volumes hold what each component stored on its first start: the indexer security configuration and data, the manager's Wazuh API user database, keystore, configuration and cluster key, and the dashboard keystore. The deployment directory holds the certificates and `config/credentials/*.env`, which are used as they are. None of them is created again, so do not run `certificates-conf.sh` or `credentials-conf.sh` for an upgrade.

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
