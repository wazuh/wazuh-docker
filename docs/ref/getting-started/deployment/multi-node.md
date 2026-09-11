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
    curl -o wazuh-certs-tool.sh https://packages.wazuh.com/5.0/wazuh-certs-tool-5.0.1-1.sh
    curl -o config.yml https://packages.wazuh.com/5.0/config-5.0.1-1.yml
    ```

4.  Edit the `config.yml` file with the configuration of the Wazuh components to be deployed

    ```yaml
    nodes:
      # Wazuh indexer server nodes
      indexer:
        - name: wazuh1.indexer
          dns: "wazuh1.indexer"
        - name: wazuh2.indexer
          dns: "wazuh2.indexer"
        - name: wazuh3.indexer
          dns: "wazuh3.indexer"

      # Wazuh manager nodes
      # Use node_type only with more than one Wazuh manager
      manager:
        - name: wazuh.master
          dns: "wazuh.master"
          node_type: master
        - name: wazuh.worker
          dns: "wazuh.worker"
          node_type: worker

      # Wazuh dashboard node
      dashboard:
        - name: wazuh.dashboard
          dns: "wazuh.dashboard"
    ```

5.  Run the certificate creation script:

    ```bash
    sudo bash ../tools/utils/deployment/certificates-conf.sh --cert --copy --priv
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

7.  **Change the default passwords.** The deployment comes up on the passwords documented in [Credentials](../../credentials.md), and changing them is the first thing to do:

    ```bash
    docker compose exec wazuh1.indexer /password-tool.sh --all
    docker compose exec wazuh.master /password-tool.sh --all
    ```

    Each command prints the new passwords once and names the ones that have to be written into `docker-compose.yml`. Copy the output, edit the file, and then recreate the stack with `docker compose down` followed by `docker compose up -d` (without `-v`). The full procedure, including how to verify it, is in [Credentials](../../credentials.md).

    The indexer change reaches the three indexer nodes, but the Wazuh API user database is local to each manager node, so the worker needs the passwords the master printed:

    ```bash
    printf '%s\n' '<the wazuh password it printed>' | \
      docker compose exec -T wazuh.worker /password-tool.sh --user wazuh --stdin
    printf '%s\n' '<the wazuh-wui password it printed>' | \
      docker compose exec -T wazuh.worker /password-tool.sh --user wazuh-wui --stdin
    ```

8.  **Optionally, run an agent alongside the deployment.** The `wazuh.agent` service is defined but not part of the default startup, so bring it up explicitly:

    ```bash
    docker compose exec wazuh.master cat /var/wazuh-manager/etc/authd.pass
    ```

    Put that password in the `WAZUH_REGISTRATION_PASSWORD` line of the `wazuh.agent` service in `docker-compose.yml` — `authd` generates it at the manager's first start — and then:

    ```bash
    docker compose --profile agent up -d
    ```

    The service already mounts `config/root-ca/certs/root-ca.pem` and points `WAZUH_MANAGER_CA` at it, which is what the agent verifies the manager with. An agent running anywhere else needs the same file; see [Wazuh agent](wazuh-agent.md).

Please allow some time for the environment to initialize, especially on the first run. A multi-node setup can take a few minutes (depending on your host resources and network) as the Wazuh Indexer cluster forms, and the necessary indexes and index patterns are generated.
