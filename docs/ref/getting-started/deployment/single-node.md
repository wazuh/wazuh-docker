# Wazuh Docker Deployment

## Deploying Wazuh Docker in a Single-Node Configuration

This deployment uses the `single-node/docker-compose.yml` file, which defines a setup with one Wazuh manager container, one Wazuh indexer container, and one Wazuh dashboard container. Follow these steps to deploy it:

1.  Navigate to the `single-node` directory within your repository:
    ```bash
    cd single-node
    ```

2.  Increase `vm.max_map_count` on each Docker host that will run a Wazuh Indexer container (Linux). This setting is crucial for Wazuh Indexer to operate correctly. This command requires root permissions:
    ```bash
    sudo sysctl -w vm.max_map_count=262144
    ```
    **Note:** This change is temporary and will revert upon reboot. To make it permanent, you'll need to edit the `/etc/sysctl.conf` file and add `vm.max_map_count=262144`, then apply with `sudo sysctl -p`.

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

Please allow some time for the environment to initialize, especially on the first run. It can take approximately a minute or two (depending on your host's resources) as the Wazuh Indexer starts up and generates the necessary indexes and index patterns.

