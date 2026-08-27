# Wazuh Docker Deployment

## Deploying the Wazuh Agent

Follow these steps to deploy the Wazuh agent using Docker.

1.  Navigate to the `wazuh-agent` directory within your repository:
    ```bash
    cd wazuh-agent
    ```

2.  Edit the `docker-compose.yml` file. You need to update the `WAZUH_MANAGER_ENDPOINT` environment variable with the IP address or hostname of your Wazuh manager.

    Locate the `environment` section for the agent service and update it as follows:
    ```yaml
    # Inside your docker-compose.yml file
    # services:
    #   wazuh-agent:
    #     ...
    environment:
      - WAZUH_MANAGER_ENDPOINT=<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>:1517/wazuh-manager/
      - WAZUH_AGENT_NAME=<YOUR_AGENT_NAME>
      - WAZUH_REGISTRATION_PASSWORD=<authd.pass-PASSWORD>
    #     ...
    ```
    **Note:** Replaces `<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>` with the actual IP address or hostname of your Wazuh manager.
    **Note:** Replaces `<authd.pass-PASSWORD>` with the password configured in the `/var/wazuh-manager/etc/authd.pass` file of the Wazuh manager server where you will connect.

    The container rewrites `/var/ossec/etc/ossec.conf` on every start with the
    following variables:

    | Variable | Default | Configuration set |
    | - | - | - |
    | `WAZUH_MANAGER_ENDPOINT` | None | `<agent><manager><endpoint>` |
    | `WAZUH_AGENT_NAME` | `wazuh-agent-<container hostname>` | `<agent><enrollment><agent_name>` |
    | `WAZUH_REGISTRATION_PASSWORD` | None | `/var/ossec/etc/authd.pass` |

    **Note:** The agent addresses the manager through a single endpoint,
    `host[:port][/prefix]`. Components left out fall back to port `1517` and
    prefix `/wazuh-manager/`, which is what the dockerized manager serves, so
    `<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>` on its own describes the same
    connection as the full form above.

    **Note:** The port must match the `<remote><https><port>` of your Wazuh
    manager, `1517` in the default configuration. Since 5.0.0 the agent enrolls
    over that same HTTPS connection, so this port covers both agent
    communication and registration: there is no separate enrollment port.

    **Note:** `WAZUH_MANAGER_ENDPOINT` is required. Without it the container
    logs the reason and exits, rather than starting an agent that could only
    retry against an unconfigured manager.

    **Note:** For an IPv6 manager, bracket the literal whenever a port follows
    it, and percent-encode the `%` of a zone id as `%25`:

    ```yaml
    environment:
      - WAZUH_MANAGER_ENDPOINT=[fe80::1%25eth0]:1517/wazuh-manager/
    ```

    **Note:** `WAZUH_MANAGER_SERVER`, `WAZUH_MANAGER_PORT`,
    `WAZUH_REGISTRATION_SERVER` and `WAZUH_REGISTRATION_PORT` are not supported
    and configure nothing. A deployment carried over from an earlier version
    has to move them into `WAZUH_MANAGER_ENDPOINT`, which carries the address,
    the port and the path prefix as one value. The container logs a warning
    naming the replacement when one of them is set.

    **Note:** To use a configuration of your own instead of these variables,
    mount your `ossec.conf` at `/wazuh-config-mount/etc/ossec.conf`. It is
    copied over the packaged one before the substitutions run, so a mounted
    file is used as it is.

3.  Start the environment using `docker compose`:

    * To run in the foreground (logs will be displayed in your current terminal, and you can stop it with `Ctrl+C`):
        ```bash
        docker compose up
        ```

    * To run in the background (detached mode, allowing the container to run independently of your terminal):
        ```bash
        docker compose up -d
        ```