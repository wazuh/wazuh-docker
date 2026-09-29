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

3.  Download the certificate creation script, `config.yml` and the credentials library:

    ```bash
    curl -o wazuh-certs-tool.sh https://packages.wazuh.com/5.0/wazuh-certs-tool-5.0.0-1.sh
    curl -o config.yml https://packages.wazuh.com/5.0/config-5.0.0-1.yml
    curl -o wazuh-credentials.sh https://packages.wazuh.com/5.0/wazuh-credentials-5.0.0-1.sh
    ```

    `wazuh-credentials.sh` is the library `credentials-conf.sh` uses in step 6 to
    generate the passwords. Use the same version as the images.

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

6.  Create the deployment's passwords:

    ```bash
    sudo bash ../tools/utils/deployment/credentials-conf.sh
    ```

    This writes `config/credentials/indexer.env`, `manager.env` and
    `dashboard.env`, with a random password for each account. The Compose file
    gives each service only its own file, as a secret rather than in its
    environment, and **the deployment does not start without them**. Keep the files: they are the only record of the passwords.
    To choose a password instead of having one generated, and for the rules a
    password has to meet, see [Credentials](../../credentials.md#creating-the-credentials).

7.  Start the Wazuh environment using `docker compose`:

    * To run in the foreground (logs will be displayed in your current terminal; press `Ctrl+C` to stop):

        ```bash
        docker compose up
        ```

    * To run in the background (detached mode, allowing the containers to run independently of your terminal):

        ```bash
        docker compose up -d
        ```

8.  **Log in.** Open `https://<DOCKER_HOST_ADDRESS>` and log in as `admin`, with the password from `indexer.env`:

    ```bash
    grep '^WAZUH_INDEXER_ADMIN_PASSWORD=' config/credentials/indexer.env | cut -d= -f2-
    ```

    The three indexer nodes share `indexer.env`, and the two manager nodes share `manager.env`, so every node starts with the same passwords. To change a password later, use `password-tool.sh` as described in [Credentials](../../credentials.md#multi-node-deployments). Editing the env files after the first start changes nothing.

9.  **Connect agents.** This deployment runs the Wazuh manager cluster, indexer cluster and dashboard; agents run wherever the endpoints they monitor are. An agent needs an enrollment token, minted against the master's API:

    ```bash
    printf 'user = "wazuh:%s"\n' "$(grep '^WAZUH_MANAGER_API_PASSWORD=' config/credentials/manager.env | cut -d= -f2-)" | \
      curl -k -K - -X POST "https://<the address nginx publishes>:55000/security/user/authenticate"
    # -> {"data": {"token": "<JWT>"}}

    curl -k -X POST "https://<the address nginx publishes>:55000/agents/enrollment-tokens" \
      -H "Authorization: Bearer <JWT>" -H "Content-Type: application/json" \
      -d '{"address": "<the address nginx publishes>", "embed_ca": true}'
    # -> {"data": {"token": "<ENROLLMENT TOKEN>", ...}}
    ```

    The `wazuh` password is read from `manager.env` and handed to `curl` on standard input, which keeps it off the command line. The address is the one `nginx` publishes, one of the `--agent-san` values from step 5, and it covers both manager nodes. `embed_ca: true` embeds `config/root-ca/certs/root-ca.pem` in the token, so a token-enrolled agent needs no separate CA configuration. See [Wazuh agent](wazuh-agent.md) for a containerized agent, and [Environment Variables](../../configuration/environment-variables.md#wazuh-agent) for the variables that carry it.

Please allow some time for the environment to initialize, especially on the first run. A multi-node setup can take a few minutes (depending on your host resources and network) as the Wazuh Indexer cluster forms, and the necessary indexes and index patterns are generated.
