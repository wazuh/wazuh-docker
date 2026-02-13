# Configuration files

### 1. Wazuh Manager Configuration

* **`ossec.conf`**: The main configuration file for the Wazuh manager. It controls rules, decoders, agent enrollment, active responses, clustering, and more.
    * **Customization**: Mount a custom `ossec.conf` or specific configuration snippets (e.g., local rules in `local_rules.xml`) into the manager container at `/wazuh-mount-point/`, which will be copied to the path `/var/ossec` (e.g., the file `/var/ossec/etc/ossec.conf` must be mounted at `/wazuh-mount-point/etc/ossec.conf`) .

### 2. Wazuh Indexer Configuration

* **`opensearch.yml`**: The primary configuration file for OpenSearch. Controls cluster settings, network binding, path settings, discovery, memory allocation, etc.
    * **Customization**: Mount a custom `opensearch.yml` into the indexer container(s) at `/usr/share/wazuh-indexer/config/opensearch.yml`.
* **JVM Settings (`jvm.options`)**: Manages Java Virtual Machine settings, especially heap size (`-Xms`, `-Xmx`). Critical for performance and stability.
    * **Customization**: Mount a custom `jvm.options` file or set `OPENSEARCH_JAVA_OPTS` environment variable.

### 3. Wazuh Dashboard (OpenSearch Dashboards) Configuration

* **`opensearch_dashboards.yml`**: The main configuration file for OpenSearch Dashboards. Controls server host/port, OpenSearch connection URL, SSL settings, and Wazuh plugin settings.
    * **Customization**: Mount a custom `opensearch_dashboards.yml` into the dashboard container at `/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml` and custom `wazuh.yml` into the dashboard container at `/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml` .
* **Wazuh Plugin Settings**: The Wazuh plugin for the dashboard has its own configuration, often within `opensearch_dashboards.yml` or managed through environment variables, specifying the Wazuh API URL and credentials.

## Applying Configuration Changes

1.  **Modify `docker-compose.yml`**:
    * For changes to environment variables, port mappings, or volume mounts.
    * After changes, you typically need to stop and restart the containers:
        ```bash
        docker compose down
        docker compose up -d
        ```

Consult the official Wazuh documentation for version 5.0.0 for detailed information on all possible configuration parameters for each component.

## Persistence configuration

When customizing your Wazuh Docker deployment, certain files and directories must be persisted to retain your changes across container restarts and recreations. This is critical for maintaining custom configurations, user credentials, and security settings.

### Volumes and Bind Mounts

Docker volumes allow you to persist data outside of container lifecycles. When a container is removed or recreated, data stored in volumes remains intact. This is essential for maintaining configuration files, user data, and other persistent state. While, bind mounts allow you to mount a file or directory from the host into the container.

To persist files or directories in your Wazuh deployment, you can mount them as volumes or bind mounts in your `docker-compose.yml` file.

> **Important**: Ensure that files exist on the host before starting the containers. If the file doesn't exist, Docker will create a directory instead, which may cause startup failures.

For more information on Docker volumes and bind mounts, refer to the official Docker documentation:
- [Use volumes](https://docs.docker.com/storage/volumes/)
- [Bind mounts](https://docs.docker.com/storage/bind-mounts/)
