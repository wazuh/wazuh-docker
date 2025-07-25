# Wazuh Docker Deployment

## Deploying Wazuh Docker in a Multi-Node Configuration

This deployment utilizes the `multi-node/docker-compose.yml` file, which defines a cluster setup with two Wazuh manager containers, three Wazuh indexer containers, and one Wazuh dashboard container. Follow these steps to deploy this configuration:

1.  Navigate to the `multi-node` directory within your repository:
    ```bash
    cd multi-node
    ```

2.  Increase `vm.max_map_count` on each Docker host that will run a Wazuh Indexer container (Linux). This setting is crucial for Wazuh Indexer to operate correctly. This command requires root permissions:
    ```bash
    sudo sysctl -w vm.max_map_count=262144
    ```
    **Note:** This change is temporary and will revert upon reboot. To make it permanent on each relevant host, you'll need to edit the `/etc/sysctl.conf` file, add `vm.max_map_count=262144`, and then apply the change with `sudo sysctl -p`.

3.  Run the script to generate the necessary certificates for the Wazuh Stack. This ensures secure communication between the nodes:
    ```bash
    docker compose -f generate-indexer-certs.yml run --rm generator
    ```

4.  Start the Wazuh environment using `docker compose`:

    * To run in the foreground (logs will be displayed in your current terminal; press `Ctrl+C` to stop):
        ```bash
        docker compose up
        ```
    * To run in the background (detached mode, allowing the containers to run independently of your terminal):
        ```bash
        docker compose up -d
        ```

Please allow some time for the environment to initialize, especially on the first run. A multi-node setup can take a few minutes (depending on your host resources and network) as the Wazuh Indexer cluster forms, and the necessary indexes and index patterns are generated.
