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

    Each manager node keeps its own name here. The address agents dial is not one
    of them: agents reach the cluster through `nginx`, which publishes `1517` and
    hands each connection to either manager node, so that address belongs to both
    nodes at once and is given in the next step instead.

5.  Run the certificate creation script, naming the address agents dial:

    ```bash
    sudo bash ../tools/utils/deployment/certificates-conf.sh --cert --copy --priv \
        --agent-san nginx --agent-san <DOCKER_HOST_ADDRESS>
    ```

    This issues every certificate the deployment mounts, including
    `wazuh.master-remoted.pem` and `wazuh.worker-remoted.pem`, the pair each
    manager node presents to agents. **A manager node does not start without its
    pair**, so this step has to run before `docker compose up`.

    `--agent-san` puts an address in the agent listener certificate of **every**
    manager node, which is what the `nginx` entry point needs: whichever node
    answers presents a certificate that names the address the agent dialed, so
    one agent can verify both. Repeat the option for each address. Use `nginx`
    for agents inside the Compose network, and the Docker host's IP address or
    DNS name — replacing `<DOCKER_HOST_ADDRESS>` — for agents anywhere else.

    Addresses given this way reach the agent listener certificates only. The
    `<node>.pem` each manager presents to the Wazuh indexer keeps its own name,
    and the certificate creation script rejects an address repeated across
    manager nodes in `config.yml`, which is why the entry point is not written
    there.

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

8.  **Connect agents.** This deployment runs the Wazuh manager cluster, indexer cluster and dashboard; agents run wherever the endpoints they monitor are. An agent needs two things from here: the enrollment password, which `authd` generates at the master's first start, and the root CA it verifies the manager nodes with.

    ```bash
    docker compose exec wazuh.master cat /var/wazuh-manager/etc/authd.pass
    ```

    The CA is `config/root-ca/certs/root-ca.pem`, and it covers both manager nodes. Agents connect to the address `nginx` publishes, one of the `--agent-san` values from step 5. See [Wazuh agent](wazuh-agent.md) for a containerized agent, and [Environment Variables](../../configuration/environment-variables.md#wazuh-agent) for the variables that carry them.

Please allow some time for the environment to initialize, especially on the first run. A multi-node setup can take a few minutes (depending on your host resources and network) as the Wazuh Indexer cluster forms, and the necessary indexes and index patterns are generated.
