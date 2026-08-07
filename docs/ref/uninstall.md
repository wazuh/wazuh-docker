# Uninstall

This section describes how to uninstall a Wazuh Docker deployment by stopping and removing the resources created.

## Uninstalling single-node and multi-node deployments

1. Navigate to the deployment directory (`single-node` or `multi-node`):

    ```bash
    cd <deployment-directory>
    ```

2. Stop and remove the containers, persistent volumes and all stored data:

    ```bash
    docker compose down -v
    ```

3. Remove generated or downloaded files:

    ```bash
    rm -rf wazuh-certificates/ config.yml wazuh-certs-tool.sh config/*/certs
    ```

4. Verify that the deployment is removed:

    ```bash
    docker ps
    ```

## Wazuh agent deployment

1. Navigate to the agent deployment directory:

    ```bash
    cd wazuh-agent
    ```

2. Stop and remove the container:

    ```bash
    docker compose down
    ```

3. Verify that the deployment is removed:

    ```bash
    docker ps
    ```
