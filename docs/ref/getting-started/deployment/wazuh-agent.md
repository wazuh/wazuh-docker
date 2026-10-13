# Wazuh Docker Deployment

## Deploying the Wazuh Agent

Follow these steps to deploy the Wazuh agent using Docker.

1.  **Mint an enrollment token.** The agent enrolls with a token minted by your
    Wazuh manager; there is no password-based enrollment. Open a terminal in the
    directory of the manager deployment (`single-node/` or `multi-node/`) and
    set the address agents connect to:

    ```bash
    WAZUH_MANAGER_ADDRESS=192.168.1.10
    ```

    It has to be one of the addresses of the manager's agent certificate. To
    list them:

    ```bash
    for cert in config/wazuh_*/certs/*-remoted.pem; do sudo openssl x509 -noout -ext subjectAltName -in "$cert"; done
    ```

    ```text
    X509v3 Subject Alternative Name:
        IP Address:192.168.1.10, DNS:wazuh.manager
    ```

    Use the Docker host's address for an agent on another machine. The names
    (`wazuh.manager`, `nginx`) only resolve inside the deployment's Compose
    network.

    Then run this block as it is, in the same terminal:

    ```bash
    WAZUH_API_TOKEN=$(printf 'user = "wazuh:%s"\n' "$(grep '^WAZUH_MANAGER_API_PASSWORD=' config/credentials/manager.env | cut -d= -f2-)" | \
      curl -sk -K - -X POST "https://${WAZUH_MANAGER_ADDRESS}:55000/security/user/authenticate?raw=true")

    RESPONSE=$(curl -sk -X POST "https://${WAZUH_MANAGER_ADDRESS}:55000/agents/enrollment-tokens" \
      -H "Authorization: Bearer ${WAZUH_API_TOKEN}" -H "Content-Type: application/json" \
      -d "{\"address\": \"${WAZUH_MANAGER_ADDRESS}\", \"embed_ca\": true}")
    WAZUH_ENROLLMENT_TOKEN=$(printf '%s' "${RESPONSE}" | sed -n 's/.*"token": *"\([^"]*\)".*/\1/p')
    [ -n "${WAZUH_ENROLLMENT_TOKEN}" ] && echo "WAZUH_ENROLLMENT_TOKEN=${WAZUH_ENROLLMENT_TOKEN}" || echo "${RESPONSE}"
    ```

    It prints the line to paste in the next step:

    ```text
    WAZUH_ENROLLMENT_TOKEN=eyJ2ZXIi...
    ```

    If it prints an error instead, the message says what is wrong. `address not
    in certificate SAN` means that `WAZUH_MANAGER_ADDRESS` is not one of the
    addresses listed above.

    The token carries the manager's address and its CA (`embed_ca`), so the
    agent needs no other connection or certificate settings. See the manager's
    `POST /agents/enrollment-tokens` reference for the optional fields (`ttl`,
    `max_uses`, `prefix`, `description`).

2.  **Put the token in the agent's Compose file.** Edit
    `wazuh-agent/docker-compose.yml` and replace the whole
    `WAZUH_ENROLLMENT_TOKEN=...` line with the line printed above, as it is,
    without quotes. Optionally, uncomment `WAZUH_AGENT_NAME` and give the agent
    a name:

    ```yaml
    environment:
      - WAZUH_ENROLLMENT_TOKEN=eyJ2ZXIi...
      - WAZUH_AGENT_NAME=my-agent
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
    ERROR: WAZUH_ENROLLMENT_TOKEN was refused by the token decoder:
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
    written out as `<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>:1517/wazuh-manager/`.
    The endpoint always lands in `ossec.conf` complete, as `host:port/prefix`.

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
    is written in full.

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

    **Note:** Without a token and without a CA, the agent connects to the
    manager **without verifying its TLS certificate** (`verification_mode`
    `none`) and logs `TLS verification is DISABLED`. To verify it, give the
    agent the CA that signs it:

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
    hostname is not. `WAZUH_AGENT_SSL_VERIFICATION` overrides that with `full`,
    `certificate`, `system` or `none`. `WAZUH_AGENT_SSL_CERT` and
    `WAZUH_AGENT_SSL_KEY` add a client certificate, which only a manager
    configured with `<remote><https><ca>` asks for. The full table is in
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

3.  **Start the agent**, from the `wazuh-agent` directory:

    ```bash
    cd ../wazuh-agent
    docker compose up -d
    ```

    Use `docker compose up`, without `-d`, to keep the logs in the terminal
    (`Ctrl+C` stops the agent).

4.  **Check that it connected.** Back in the manager deployment's directory, in
    the same terminal as step 1:

    ```bash
    cd -
    curl -sk -H "Authorization: Bearer ${WAZUH_API_TOKEN}" \
      "https://${WAZUH_MANAGER_ADDRESS}:55000/agents?select=name,status&pretty=true"
    ```

    The agent is listed with `"status": "active"`. The API token lasts 15
    minutes: if the answer is `Invalid token`, run the `WAZUH_API_TOKEN=...`
    command of step 1 again.

    Once enrolled, the agent keeps its identity in the `wazuh_agent_etc` volume.
    Recreating the container does not enroll it again, and the token line can
    stay in the Compose file: a used token is not read again.
