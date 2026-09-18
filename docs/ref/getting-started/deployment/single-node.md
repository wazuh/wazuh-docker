# Wazuh Docker Deployment

## Deploying Wazuh Docker in a Single-Node Configuration

This deployment uses the `single-node/docker-compose.yml` file, which defines a setup with one Wazuh Manager, one Wazuh Indexer, and one Wazuh Dashboard container. Follow these steps to deploy it:

1.  Increase `vm.max_map_count` on each Docker host that will run a Wazuh Indexer container (Linux). This setting is crucial for Wazuh Indexer to operate correctly. This command requires root permissions:

    ```bash
    sudo sysctl -w vm.max_map_count=262144
    ```

    **Note:** This change is temporary and will revert upon reboot. To make it permanent, you'll need to edit the `/etc/sysctl.conf` file and add `vm.max_map_count=262144`, then apply with `sudo sysctl -p`.

2.  Navigate to the `single-node` directory within your repository:

    ```bash
    cd single-node
    ```

3.  Download the certificate creation script and `config.yml` file:

    ```bash
    curl -o wazuh-certs-tool.sh https://packages.wazuh.com/5.0/wazuh-certs-tool-5.0.1-1.sh
    curl -o config.yml https://packages.wazuh.com/5.0/config-5.0.1-1.yml
    ```

4.  Edit the config.yml file with the configuration of the Wazuh components to be deployed

    ```yaml
    nodes:
      # Wazuh indexer server nodes
      indexer:
        - name: wazuh.indexer
          dns: "wazuh.indexer"

      # Wazuh manager nodes
      # Use node_type only with more than one Wazuh manager
      manager:
        - name: wazuh.manager
          ip: "<DOCKER_HOST_ADDRESS>"
          dns:
            - "wazuh.manager"

      # Wazuh dashboard node
      dashboard:
        - name: wazuh.dashboard
          dns: "wazuh.dashboard"
    ```

    The `ip` and `dns` entries of the manager node become the Subject Alternative
    Names of the certificate the manager presents on `1517`, the port agents
    connect to and enroll through. **List every address agents dial.**
    `wazuh.manager` only resolves inside the Compose network, so an agent on
    another host reaches the address that publishes `1517`, which is the Docker
    host: replace `<DOCKER_HOST_ADDRESS>` with that host's IP address, and add its
    DNS name to the `dns` list if agents use a name instead.

    An address left out is not refused until an agent verifies the hostname as
    well as the chain (`WAZUH_AGENT_SSL_VERIFICATION=full`), and adding one later
    means issuing the certificates again. `ip` and `dns` both take one value or a
    list. Node names are enough for the Wazuh indexer and the Wazuh dashboard,
    whose certificates are only used inside the Compose network.

5.  Run the certificate creation script:

    ```bash
    sudo bash ../tools/utils/deployment/certificates-conf.sh --cert --copy --priv
    ```

    This issues every certificate the deployment mounts, including
    `wazuh.manager-remoted.pem` and `wazuh.manager-remoted-key.pem`, the pair the
    manager presents to agents. **The manager does not start without that pair**,
    so this step has to run before `docker compose up`.

    `--agent-san` adds an address to the agent listener certificates without
    putting it on the manager node in `config.yml`, which is useful when agents
    reach the deployment through a name the host does not carry:

    ```bash
    sudo bash ../tools/utils/deployment/certificates-conf.sh --cert --copy --priv \
        --agent-san wazuh.example.com
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
    docker compose exec wazuh.indexer /password-tool.sh --all
    docker compose exec wazuh.manager /password-tool.sh --all
    ```

    Each command prints the new passwords once and names the ones that have to be written into `docker-compose.yml`. Copy the output, edit the file, and then recreate the stack with `docker compose down` followed by `docker compose up -d` (without `-v`). The full procedure, including how to verify it, is in [Credentials](../../credentials.md).

8.  **Connect agents.** This deployment runs the Wazuh manager, indexer and dashboard; agents run wherever the endpoints they monitor are. An agent needs two things from here: the enrollment password, which `authd` generates at the manager's first start, and the root CA it verifies the manager with.

    ```bash
    docker compose exec wazuh.manager cat /var/wazuh-manager/etc/authd.pass
    ```

    The CA is `config/root-ca/certs/root-ca.pem`. See [Wazuh agent](wazuh-agent.md) for a containerized agent, and [Environment Variables](../../configuration/environment-variables.md#wazuh-agent) for the variables that carry them.

Please allow some time for the environment to initialize, especially on the first run. It can take approximately a minute or two (depending on your host's resources) as the Wazuh Indexer starts up and generates the necessary indexes and index patterns.
