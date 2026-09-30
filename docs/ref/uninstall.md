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

3. Remove the generated and downloaded files, including the deployment's passwords in `config/credentials/`. They are owned by root or by the service users, hence `sudo`:

    ```bash
    sudo rm -rf wazuh-certificates/ wazuh-certificates-tool.log config.yml wazuh-certs-tool.sh wazuh-credentials.sh \
        config/*/certs config/credentials
    ```

    The root CA that signed the certificates stays on the host, in `/etc/wazuh/ca` (or the directory set in `WAZUH_CA_DIR`). Remove it only if no other deployment issued on this host uses it: `sudo rm -rf /etc/wazuh/ca`.

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
