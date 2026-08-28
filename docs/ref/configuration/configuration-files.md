# Configuration files

### 1. Wazuh Manager Configuration

* **`wazuh-manager.conf`**: The main configuration file for the Wazuh manager. It controls rules, decoders, agent enrollment, active responses, clustering, and more.
    * **Customization**: Mount a custom `wazuh-manager.conf` or specific configuration snippets (e.g., local rules in `local_rules.xml`) into the manager container at `/wazuh-mount-point/`, which will be copied to the path `/var/wazuh-manager` (e.g., the file `/var/wazuh-manager/etc/wazuh-manager.conf` must be mounted at `/wazuh-mount-point/etc/wazuh-manager.conf`) .

### 2. Wazuh Indexer Configuration

* **`opensearch.yml`**: The primary configuration file for OpenSearch. Controls cluster settings, network binding, path settings, discovery, memory allocation, etc.
    * **Customization**: Mount a custom `opensearch.yml` into the indexer container(s) at `/usr/share/wazuh-indexer/config/opensearch.yml`.
* **JVM Settings (`jvm.options`)**: Manages Java Virtual Machine settings, especially heap size (`-Xms`, `-Xmx`). Critical for performance and stability.
    * **Customization**: Mount a custom `jvm.options` file or set `OPENSEARCH_JAVA_OPTS` environment variable.

### 3. Wazuh Dashboard (OpenSearch Dashboards) Configuration

* **`opensearch_dashboards.yml`**: The main configuration file for OpenSearch Dashboards. Controls server host/port, OpenSearch connection URL, SSL settings, and Wazuh plugin settings.
    * **Customization**: Mount a custom `opensearch_dashboards.yml` into the dashboard container at `/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml` and custom `wazuh.yml` into the dashboard container at `/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml` .
* **Wazuh Plugin Settings**: The Wazuh plugin for the dashboard has its own configuration, often within `opensearch_dashboards.yml` or managed through environment variables, specifying the Wazuh API URL and credentials.
* **`opensearch_dashboards.keystore`**: Secure storage for the dashboard secrets, located at `/usr/share/wazuh-dashboard/config/opensearch_dashboards.keystore`. The image is shipped without a keystore; the container entrypoint creates it on the first start and adds a randomly generated `wazuh_ai_assistant.encryptionKey`, which the AI assistant uses to encrypt its data. The `opensearch.username` and `opensearch.password` entries are set on every start from the `DASHBOARD_USERNAME` and `DASHBOARD_PASSWORD` environment variables.
    * **Customization**: To set your own key, add it through the keystore tool inside the dashboard container and restart the service:
        ```bash
        echo "<your-encryption-key>" | docker compose exec -T wazuh.dashboard \
          /usr/share/wazuh-dashboard/bin/opensearch-dashboards-keystore add wazuh_ai_assistant.encryptionKey --stdin --allow-root -f
        docker compose restart wazuh.dashboard
        ```
    * **Important**: The keystore is created only when it does not already exist, so the encryption key stays stable across restarts as long as the `/usr/share/wazuh-dashboard/config` volume is kept. If the keystore is deleted, the entrypoint generates a new key on the next start and any data encrypted with the previous one becomes unreadable.

## Applying Configuration Changes

1.  **Modify `docker-compose.yml`**:
    * For changes to environment variables, port mappings, or volume mounts.
    * After changes, you typically need to stop and restart the containers:
        ```bash
        docker compose down
        docker compose up -d
        ```

Consult the official Wazuh documentation for version 5.0.1 for detailed information on all possible configuration parameters for each component.

## Persistence configuration

When customizing your Wazuh Docker deployment, certain files and directories must be persisted to retain your changes across container restarts and recreations. This is critical for maintaining custom configurations, user credentials, and security settings.

### Volumes and Bind Mounts

Docker volumes allow you to persist data outside of container lifecycles. When a container is removed or recreated, data stored in volumes remains intact. This is essential for maintaining configuration files, user data, and other persistent state. While, bind mounts allow you to mount a file or directory from the host into the container.

To persist files or directories in your Wazuh deployment, you can mount them as volumes or bind mounts in your `docker-compose.yml` file.

> **Important**: Ensure that files exist on the host before starting the containers. If the file doesn't exist, Docker will create a directory instead, which may cause startup failures.

### Wazuh manager self-signed certificate

The `docker-compose.yml` files mount a named volume on `/var/wazuh-manager/etc` (`wazuh_etc` in single-node; `master-wazuh-etc` and `worker-wazuh-etc` in multi-node). That volume holds `certs/remoted.pem` and `certs/remoted-key.pem`, the self-signed pair each manager container generates on its first start and reuses on every later start. It is used by the HTTPS agent listener and by agent enrollment (`authd`), and it is unique per deployment and per cluster node.

Removing the volume (for example, with `docker compose down -v`) deletes the pair, and the next start generates a new one. Agents do not validate this certificate by default, so a new pair does not break already enrolled agents. Do not copy the volume between deployments: that reuses the same private key in both. See [Security](../security.md) for rotation and for using your own certificate.

### Wazuh Dashboard keystore

The `docker-compose.yml` files mount the named volume `wazuh-dashboard-config` on `/usr/share/wazuh-dashboard/config`, which is where `opensearch_dashboards.keystore` is stored. Keeping this volume preserves the `wazuh_ai_assistant.encryptionKey` generated on the first start.

Removing the volume (for example, with `docker compose down -v`) deletes the keystore. The next start creates a new one with a different encryption key, and data encrypted by the AI assistant with the previous key can no longer be decrypted.

For more information on Docker volumes and bind mounts, refer to the official Docker documentation:
- [Use volumes](https://docs.docker.com/storage/volumes/)
- [Bind mounts](https://docs.docker.com/storage/bind-mounts/)
