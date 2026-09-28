# Wazuh Docker Deployment

## Deploying the Wazuh Agent

Follow these steps to deploy the Wazuh agent using Docker.

1.  Navigate to the `wazuh-agent` directory within your repository:
    ```bash
    cd wazuh-agent
    ```

2.  Edit the `docker-compose.yml` file. You need an enrollment token, minted by
    your Wazuh manager, in the `WAZUH_ENROLLMENT_TOKEN` environment variable —
    this is the only way to enroll, there is no password-based path any more.

    Mint one against the manager's API (`wazuh`/`wazuh` on a deployment that has
    not been through [Credentials](../../credentials.md) yet):

    ```bash
    curl -k -u wazuh:wazuh -X POST "https://<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>:55000/security/user/authenticate"
    # -> {"data": {"token": "<JWT>"}}

    curl -k -X POST "https://<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>:55000/agents/enrollment-tokens" \
      -H "Authorization: Bearer <JWT>" -H "Content-Type: application/json" \
      -d '{"address": "<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>", "embed_ca": true}'
    # -> {"data": {"token": "<ENROLLMENT TOKEN>", ...}}
    ```

    `embed_ca: true` puts the manager's own CA inside the token, so the agent
    trusts it without any `WAZUH_MANAGER_CA`/`WAZUH_AGENT_SSL_VERIFICATION`
    configuration below — the token supplies its own trust anchor. Omit it for a
    token that only pins the CA's fingerprint instead of carrying the whole
    certificate; see the manager's `POST /agents/enrollment-tokens` reference for
    the rest of the fields (`ttl`, `max_uses`, `prefix`, `description`).

    Locate the `environment` section for the agent service and update it as follows:
    ```yaml
    # Inside your docker-compose.yml file
    # services:
    #   wazuh-agent:
    #     ...
    environment:
      - WAZUH_ENROLLMENT_TOKEN=<ENROLLMENT TOKEN MINTED ABOVE>
      - WAZUH_AGENT_NAME=<YOUR_AGENT_NAME>
    #     ...
    ```

    The container writes `/var/ossec/etc/ossec.conf` with the following
    variables the first time it starts. `/var/ossec/etc` is persisted in the
    `wazuh_agent_etc` volume (see the note below), so on later starts the
    agent's identity and configuration are kept as they are instead of being
    rewritten:

    | Variable | Default | Configuration set |
    | - | - | - |
    | `WAZUH_ENROLLMENT_TOKEN` | None | `<agent><manager><endpoint>`, decoded from the token; the token itself staged at `/var/ossec/etc/enrollment_token` (`0600 root:root`) for the agent to bootstrap from at its first start |
    | `WAZUH_MANAGER_ENDPOINT` | None | `<agent><manager><endpoint>`, whole — without a token, see the note below |
    | `WAZUH_MANAGER_SERVER` | None | Host of `<agent><manager><endpoint>` — without a token |
    | `WAZUH_MANAGER_PORT` | `1517` | Port of `<agent><manager><endpoint>` — without a token |
    | `WAZUH_AGENT_NAME` | `wazuh-agent-<container hostname>` | `<agent><enrollment><agent_name>` |
    | `WAZUH_MANAGER_CA` | None | `<agent><ssl><certificate_authorities>` — without a token; a token that embeds the CA needs none of this |
    | `WAZUH_AGENT_SSL_VERIFICATION` | Inferred | `<agent><ssl><verification_mode>` |
    | `WAZUH_AGENT_SSL_CERT` / `WAZUH_AGENT_SSL_KEY` | None | `<agent><ssl><certificate>` / `<key>` |

    **Note:** A rejected token (expired, revoked, already at `max_uses`, or
    malformed) makes the container exit before writing anything, naming the
    reason:

    ```text
    ERROR: WAZUH_ENROLLMENT_TOKEN was refused by the token decoder (wazuh-agentd --show-token exited 2):
    wazuh-agentd: invalid enrollment token: malformed token.
    ```

    **Note:** `WAZUH_MANAGER_ENDPOINT`/`WAZUH_MANAGER_SERVER` are for an agent
    that does *not* need to enroll here — one already carrying its own
    `client.keys` and trust anchor (mounted, or kept in `wazuh_agent_etc` from a
    previous container) that just needs to be told where to connect. They are
    refused alongside `WAZUH_ENROLLMENT_TOKEN`, which already carries the
    address.

    **Note:** The agent addresses the manager through a single endpoint,
    `host[:port][/prefix]`. A component left out is filled in with its default,
    port `1517` and prefix `/wazuh-manager/`, which is what the dockerized
    manager serves, so `<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>` on its own is
    written out as the full form above. The endpoint always lands in
    `ossec.conf` complete, as `host:port/prefix`.

    **Note:** The port must match the `<remote><https><port>` of your Wazuh
    manager, `1517` in the default configuration. Since 5.0.0 the agent enrolls
    over that same HTTPS connection, so this port covers both agent
    communication and registration: there is no separate enrollment port.

    **Note:** The connection may be given either way. `WAZUH_MANAGER_ENDPOINT`
    carries it as one value, and `WAZUH_MANAGER_SERVER` with
    `WAZUH_MANAGER_PORT` split it into an address and a port:

    ```yaml
    environment:
      - WAZUH_MANAGER_SERVER=<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>
      - WAZUH_MANAGER_PORT=1517
    ```

    `WAZUH_MANAGER_ENDPOINT` wins when both are set, and the other two are then
    not read at all. One of `WAZUH_ENROLLMENT_TOKEN`, `WAZUH_MANAGER_ENDPOINT` or
    `WAZUH_MANAGER_SERVER` is required: with none of them, the container logs the
    reason and exits rather than starting an agent that could only retry against
    an unconfigured manager.

    Either way the single `<endpoint>` is the only configuration written, and it
    is written in full. The `<address>` and `<port>` tags it replaced are never
    touched, so a package that still ships them predates the change and the
    container says so on start.

    **Note:** For an IPv6 manager, bracket the literal whenever a port follows
    it, and percent-encode the `%` of a zone id as `%25`:

    ```yaml
    environment:
      - WAZUH_MANAGER_ENDPOINT=[fe80::1%25eth0]:1517/wazuh-manager/
    ```

    **Note:** `WAZUH_REGISTRATION_SERVER`, `WAZUH_REGISTRATION_PORT` and
    `WAZUH_REGISTRATION_PASSWORD` are not supported and configure nothing: the
    first two because enrollment reuses the agent connection instead of reaching
    `authd` separately, the third because there is no password-based enrollment
    any more — see [Environment Variables](../../configuration/environment-variables.md#wazuh-agent).
    The container logs a warning when any of them is set.

    **Note:** Without a token, the agent verifies the manager's TLS certificate
    itself. Left unconfigured it verifies against the operating system trust
    store, which covers a manager whose certificate chains to a publicly trusted
    CA and nothing else: a manager presenting a certificate of its own, which is
    what a Wazuh manager does by default, is refused. Give the agent the CA that
    signs it:

    ```yaml
    environment:
      - WAZUH_MANAGER_ENDPOINT=<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>:1517/wazuh-manager/
      - WAZUH_MANAGER_CA=/etc/ssl/wazuh/root-ca.pem
    volumes:
      - ./root-ca.pem:/etc/ssl/wazuh/root-ca.pem:ro
    ```

    **Note:** Replaces `./root-ca.pem` with the CA that signs the certificate on
    your manager's `1517` listener. For a manager deployed from this repository
    it is `single-node/config/root-ca/certs/root-ca.pem`, or the `multi-node`
    one. For any other manager, ask whoever runs it. The CA may also be dropped
    at `/var/ossec/etc/certs/manager-ca.pem` instead, in which case the variable
    is not needed — deliberately not `root-ca.pem`, which is reserved for the
    trust anchor a token enrollment writes.

    **Note:** A CA on its own means the certificate chain is verified but the
    hostname is not, which is what lets one agent reach a manager through a name
    the certificate does not carry, such as a load balancer.
    `WAZUH_AGENT_SSL_VERIFICATION` overrides that with `full`, `certificate`,
    `system` or `none`. `WAZUH_AGENT_SSL_CERT` and `WAZUH_AGENT_SSL_KEY` add a
    client certificate, which only a manager configured with
    `<remote><https><ca>` asks for. The full table is in
    [Environment Variables](../../configuration/environment-variables.md#wazuh-agent).

    **Note:** With `full`, the address in `WAZUH_MANAGER_ENDPOINT` also has to be
    in the Subject Alternative Name of the certificate the manager presents on
    `1517`. For a manager deployed from this repository that address is listed
    when the certificates are created, on the manager node of `config.yml` or
    with `--agent-san`; see [single-node](single-node.md) and
    [multi-node](multi-node.md). An address that is not there fails with
    `no alternative certificate subject name matches target`.

    **Note:** To use a configuration of your own instead of these variables,
    mount your `ossec.conf` at `/wazuh-config-mount/etc/ossec.conf`. It is
    copied over the packaged one before the substitutions run, so a mounted
    file is used as it is.

    **Note:** The compose file mounts `/var/ossec/etc` on the `wazuh_agent_etc`
    volume, so `client.keys` and the resolved configuration survive the
    container being recreated (an image upgrade, a host reboot, `docker
    compose down && up`). Without it, every recreation would enroll as a new
    agent, since the container gets a new hostname-derived
    `WAZUH_AGENT_NAME` and loses its previous `client.keys` each time, leaving
    the old registration on the manager with nothing to remove it.

3.  Start the environment using `docker compose`:

    * To run in the foreground (logs will be displayed in your current terminal, and you can stop it with `Ctrl+C`):
        ```bash
        docker compose up
        ```

    * To run in the background (detached mode, allowing the container to run independently of your terminal):
        ```bash
        docker compose up -d
        ```