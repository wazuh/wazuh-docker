# Configuration files

### 1. Wazuh Manager Configuration

* **`ossec.conf`**: The main configuration file for the Wazuh manager. It controls rules, decoders, agent enrollment, active responses, integrations, clustering, and more.
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


Consult the official Wazuh documentation for version 4.13.1 for detailed information on all possible configuration parameters for each component.