# Wazuh Docker Deployment

## Deploying Wazuh Docker in a Multi-Node Configuration

This deployment utilizes the `multi-node/docker-compose.yml` file, which defines a cluster setup with two Wazuh Manager, three Wazuh Indexer, and one Wazuh Dashboard containers. Follow these steps to deploy this configuration:

1.  Increase `vm.max_map_count` on each Docker host that will run a Wazuh Indexer container (Linux). This setting is crucial for Wazuh Indexer to operate correctly. This command requires root permissions:

    ```bash
    sudo sysctl -w vm.max_map_count=262144
    ```

    **Note:** This change is temporary and will revert upon reboot. To make it permanent on each relevant host, you'll need to edit the `/etc/sysctl.conf` file, add `vm.max_map_count=262144`, and then apply the change with `sudo sysctl -p`.

2.  Navigate to the `multi-node` directory within your repository:

    ```bash
    cd multi-node
    ```

3.  Download the certificate creation script and config.yml file:

    ```bash
    curl -o wazuh-certs-tool.sh https://packages.wazuh.com/5.0/wazuh-certs-tool-5.0.0-1.sh
    curl -o config.yml https://packages.wazuh.com/5.0/config-5.0.0-1.yml
    ```

4.  Edit the `config.yml` file with the configuration of the Wazuh components to be deployed

    ```bash
    nodes:
      # Wazuh indexer server nodes
      indexer:
        - name: wazuh1.indexer
          ip: wazuh1.indexer
        - name: wazuh2.indexer
          ip: wazuh2.indexer
        - name: wazuh3.indexer
          ip: wazuh3.indexer

      # Wazuh manager nodes
      # Use node_type only with more than one Wazuh manager
      manager:
        - name: wazuh.master
          ip: wazuh.master
          node_type: master
        - name: wazuh.worker
          ip: wazuh.worker
          node_type: worker

      # Wazuh dashboard node
      dashboard:
        - name: wazuh.dashboard
          ip: wazuh.dashboard
    ```

5.  Run the certificate creation script:

    ```bash
    bash ./wazuh-certs-tool.sh -A
    ```

6.  Start the Wazuh environment using `docker compose`:

    * To run in the foreground (logs will be displayed in your current terminal; press `Ctrl+C` to stop):

        ```bash
        docker compose up
        ```

    * To run in the background (detached mode, allowing the containers to run independently of your terminal):

        ```bash
        docker compose up -d
        ```

Please allow some time for the environment to initialize, especially on the first run. A multi-node setup can take a few minutes (depending on your host resources and network) as the Wazuh Indexer cluster forms, and the necessary indexes and index patterns are generated.
