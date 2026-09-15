# Environment Variables in Wazuh Docker Deployment

This document outlines the environment variables applicable to the Wazuh Docker deployment, covering the Wazuh Manager, Indexer, Dashboard, and Agent components. It also explains how to override configuration settings using environment variables.

## Table of Contents

- [Environment Variables in Wazuh Docker Deployment](#environment-variables-in-wazuh-docker-deployment)
  - [Table of Contents](#table-of-contents)
  - [Wazuh Manager](#wazuh-manager)
  - [Wazuh Indexer](#wazuh-indexer)
  - [Wazuh Dashboard](#wazuh-dashboard)
  - [Wazuh Agent](#wazuh-agent)
  - [Overriding Configuration Files with Environment Variables](#overriding-configuration-files-with-environment-variables)
    - [Examples:](#examples)

---

## Wazuh Manager

The Wazuh Manager container accepts the following environment variables, which can be set in the `docker-compose.yml` file under the `environment` section:

```yaml
environment:
  - INDEXER_USERNAME=wazuh-manager
  - INDEXER_PASSWORD=wazuh-manager
  - WAZUH_NODE_NAME=wazuh.manager
  - WAZUH_NODE_TYPE=master
  - WAZUH_CLUSTER_KEY=
  - WAZUH_CLUSTER_NODES=
  - WAZUH_CLUSTER_BIND_ADDR=0.0.0.0
  - WAZUH_INDEXER_HOSTS=wazuh.indexer:9200
  - WAZUH_CONFIG_MOUNT=/wazuh-config-mount
```

**Variable Descriptions:**

- `INDEXER_USERNAME` / `INDEXER_PASSWORD`: Credentials for accessing the Wazuh Indexer with `wazuh-manager` user or a user with the same permissions. The value shown is the default the image ships; change it on the first start and write the new one here. See [Credentials](../credentials.md).
- `WAZUH_NODE_NAME`: This node's cluster name, written to `<cluster><node_name>`. Defaults to the container hostname.
- `WAZUH_NODE_TYPE`: Either `master` or `worker`, written to `<cluster><node_type>`. Any other value (including unset) is treated as `master`.
- `WAZUH_CLUSTER_KEY`: The cluster authentication key shared by every master/worker node, written to `<cluster><key>`. The public image ships a fixed default key; leaving this unset keeps that default, which is the same for every deployment using the published image and should be replaced in production. See [#263](https://github.com/wazuh/wazuh-docker/issues/263).
- `WAZUH_CLUSTER_NODES`: Space-separated list of worker node addresses/hostnames, written to `<cluster><nodes>`. Only meaningful on the master node.
- `WAZUH_CLUSTER_BIND_ADDR`: Address the cluster service binds to, written to `<cluster><bind_addr>`. Defaults to `0.0.0.0`.
- `WAZUH_INDEXER_HOSTS`: Comma-separated list of indexer nodes as `host:port` (for example `wazuh.indexer:9200`, or `host1:9200,host2:9200` for multiple nodes), written to `<indexer><hosts>`. Each entry must be exactly `host:port`: no scheme, no trailing slash, no other separator — any other shape either fails validation or produces a corrupt host. See [#2630](https://github.com/wazuh/wazuh-docker/issues/2630).
- `WAZUH_CONFIG_MOUNT`: Path, inside the container, where a directory mounted with the manager's own configuration files is looked for and copied over the packaged ones on start. Defaults to `/wazuh-config-mount`.
- `WAZUH_REMOTE_BIND_ADDR`: Address `remoted` listens on for agent traffic, written to `<remote><https><bind_addr>` and `<remote><legacy><local_ip>`. Defaults to `0.0.0.0`, since the packaged `127.0.0.1` would make the published `1517` and `1514` unreachable from outside the container.

---

## Wazuh Indexer

The Wazuh Indexer services (`single-node` and `multi-node`) use the following environment variable:

```yaml
environment:
  - "OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g"
```

**Variable Descriptions:**

- `OPENSEARCH_JAVA_OPTS`: Sets JVM heap size and other Java options.

---

## Wazuh Dashboard
The Wazuh Dashboard container accepts the following environment variables, which should be set in the `docker-compose.yml` file:
```yaml
environment:
  - WAZUH_API_URL=https://wazuh.manager
  - DASHBOARD_USERNAME=kibanaserver
  - DASHBOARD_PASSWORD=kibanaserver
  - API_USERNAME=wazuh-wui
  - API_PASSWORD=wazuh-wui
```
**Variable Descriptions:**
- `WAZUH_API_URL`: Base URL of the Wazuh API, used for querying and visualizing security data.
- `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD`: Credentials the Dashboard uses to authenticate with the Wazuh Indexer.
- `API_USERNAME` / `API_PASSWORD`: Wazuh API user credentials used by the Dashboard to query the manager's API.
These variables are critical for enabling communication between the Wazuh Dashboard, the Wazuh Indexer, and the Wazuh API.
The passwords shown are the defaults the images ship. `DASHBOARD_PASSWORD` and `API_PASSWORD` are two of the three that have to be replaced on the first start of the deployment, with the values `password-tool.sh` prints. See [Credentials](../credentials.md).
---
## Wazuh Agent

The Wazuh Agent container uses the following environment variables to dynamically update the `ossec.conf` configuration file at runtime:

```yaml
environment:
  - WAZUH_MANAGER_ENDPOINT=wazuh.manager:1517/wazuh-manager/
  - WAZUH_AGENT_NAME=my-agent
  - WAZUH_REGISTRATION_PASSWORD=my-authd-password
```

**Variable Descriptions:**

- `WAZUH_MANAGER_ENDPOINT`: The whole manager connection as one value, `host[:port][/prefix]`, written to `<agent><manager><endpoint>`. A component left out is filled in with its default, port `1517` and prefix `/wazuh-manager/`, so `wazuh.manager` is written out as `wazuh.manager:1517/wazuh-manager/`. A `https://` scheme is accepted and dropped.
- `WAZUH_AGENT_NAME`: Agent name used on enrollment, written to `<agent><enrollment><agent_name>`. Defaults to `wazuh-agent-<container hostname>`.
- `WAZUH_REGISTRATION_PASSWORD`: Enrollment password, written to `/var/ossec/etc/authd.pass`.
- `WAZUH_MANAGER_CA`: Path, inside the container, to the CA that signs the manager's HTTPS certificate. Written to `<agent><ssl><certificate_authorities>`. `WAZUH_REGISTRATION_CA`, the name the package installer uses for the same setting, is accepted as an alias.

**Verifying the manager**

The agent verifies the manager's TLS certificate. With no `<ssl>` configuration it
verifies against the operating system trust store, which covers a manager whose
certificate chains to a publicly trusted CA and nothing else — a manager
presenting a certificate of its own, which is what a Wazuh manager does by
default, is refused and the agent logs the reason and keeps retrying:

```text
wazuh-agentd: ERROR: Enrollment request could not be sent: (60) SSL peer certificate or SSH remote key was not OK: SSL certificate OpenSSL verify result: unable to get local issuer certificate (20).
```

Reaching such a manager means giving the agent the CA that signs it:

```yaml
environment:
  - WAZUH_MANAGER_ENDPOINT=wazuh.manager:1517/wazuh-manager/
  - WAZUH_MANAGER_CA=/etc/ssl/wazuh/root-ca.pem
volumes:
  - ./root-ca.pem:/etc/ssl/wazuh/root-ca.pem:ro
```

For a manager deployed from this repository that CA is
`single-node/config/root-ca/certs/root-ca.pem` (or the `multi-node` one), the same
root CA the rest of the deployment uses. For any other manager, ask whoever runs
it for the CA that signs the certificate on its `1517` listener.

The CA may also be dropped at `/var/ossec/etc/certs/root-ca.pem` instead of being
named, in which case the variable is not needed. That is what makes it mountable
through `WAZUH_CONFIG_MOUNT` the same way a whole `ossec.conf` is: a file mounted
at `/wazuh-config-mount/etc/certs/root-ca.pem` is copied there on start.

Whichever way it arrives, the file is copied into `/var/ossec/etc/certs/` and given
to the agent user. `wazuh-agentd` opens it after dropping privileges, so a bind
mount carrying the host's own ownership and mode is regularly unreadable to it;
copying it is what removes that from the deployment's concerns.

**Variable Descriptions (TLS):**

- `WAZUH_AGENT_SSL_VERIFICATION`: How strictly the manager certificate is verified, written to `<agent><ssl><verification_mode>`. `SSL_VERIFICATION`, the installer's name for it, is accepted as an alias. Optional — see the table below for what it defaults to.
- `WAZUH_AGENT_SSL_CERT` / `WAZUH_AGENT_SSL_KEY`: Client (mTLS) certificate and its private key, written to `<agent><ssl><certificate>` and `<key>`. Both or neither. Only needed by a manager configured with `<remote><https><ca>`, which asks agents for a certificate of their own; the shipped manager configuration does not.

| `WAZUH_AGENT_SSL_VERIFICATION` | Trust anchor | Checks the hostname | Needs a CA |
| - | - | - | - |
| unset, no CA given | Operating system trust store | Yes | — |
| unset, CA given | The given CA | No | — |
| `certificate` | The given CA | No | Yes |
| `full` | The given CA | Yes | Yes |
| `system` | Operating system trust store | Yes | Must not be given |
| `none` | No verification | No | — |

A CA with no verification mode stated means `certificate`, which verifies the
certificate chain but not the hostname. That is what lets an agent reach a manager
through a name the certificate does not carry — a load balancer, or the
`multi-node` NGINX entry point, where each cluster node answers with its own
certificate. Use `full` only when the manager certificate names the very host the
endpoint dials.

The container refuses to start on the combinations the agent itself rejects, so
they surface at start instead of as a connection that never succeeds: `system`
together with a CA, `certificate` or `full` without one, and a client certificate
without its key.

`host` is an IPv4 literal, a hostname, or a bracketed IPv6 literal. An IPv6
literal must be bracketed whenever a port follows it, as in `[fd00::1]:1517`, and
may carry a zone id naming the outgoing interface:

```yaml
environment:
  - WAZUH_MANAGER_ENDPOINT=[fe80::1%25eth0]:1517/wazuh-manager/
```

The `%` separating the zone id is percent-encoded as `%25`, which is what makes
the endpoint a valid URL. The container also accepts the plain `fe80::1%eth0`
form the system itself reports, encoding it on start and logging that it did so.
This zone id replaces the separate `<interface_index>` option used before.

These variables are used by the `set_manager_conn()` function in the entrypoint script to replace placeholder values in `ossec.conf`.

**Setting the connection with separate address and port:**

The connection may also be given as an address and a port instead of one value:

```yaml
environment:
  - WAZUH_MANAGER_SERVER=wazuh.manager
  - WAZUH_MANAGER_PORT=1517
  - WAZUH_AGENT_NAME=my-agent
  - WAZUH_REGISTRATION_PASSWORD=my-authd-password
```

- `WAZUH_MANAGER_SERVER`: Address of the Wazuh Manager. Becomes the host of `<endpoint>`.
- `WAZUH_MANAGER_PORT`: Manager HTTPS port. Defaults to `1517`, and must match the manager `<remote><https><port>`. Becomes the port of `<endpoint>`.

Whichever form is used, `<agent><manager><endpoint>` is the only configuration written: since wazuh/wazuh#38624 it holds the whole connection, and the `<address>` and `<port>` tags it replaced are never touched. It is always written in full, as `host:port/prefix`, with the defaults spelled out rather than left for the agent to infer.

`WAZUH_MANAGER_ENDPOINT` takes precedence over both. When it is set, they are not
read at all, not even to supply a component it left out: an endpoint without a
port falls back to `1517`, never to `WAZUH_MANAGER_PORT`. The container logs a
warning when both forms are set at once.

One of the two forms is required. With neither, the container has no manager to
connect to, so it logs the reason and exits instead of starting an agent that
could only retry against a placeholder. The one case where both may be omitted is
a deployment mounting its own `ossec.conf` at
`/wazuh-config-mount/etc/ossec.conf`, which already carries a manager of its own.

**Variables that are not supported:**

| Variable | Replaced by |
| - | - |
| `WAZUH_REGISTRATION_SERVER` | The manager variables, enrollment reuses the agent connection |
| `WAZUH_REGISTRATION_PORT` | The manager variables, enrollment reuses the agent connection |

Neither configures anything, and the container logs a warning when one is set.
They pointed enrollment at `authd` separately, which since 5.0.0 no longer
happens: the agent enrolls through the manager connection it already has, so
`<enrollment>` carries neither an address nor a port of its own.

---

## Overriding Configuration Files with Environment Variables
> **Note:** The rule below does not hold as written for either file it names.
> For the indexer, the literal lowercase dotted key is required instead (for
> example `discovery.type=single-node`, not `DISCOVERY_TYPE=single-node`) — see
> the indexer's own compose entries for working examples. For the dashboard,
> only a fixed set of keys handled by `wazuh_dashboard_config.sh` are read; any
> other key is silently ignored. This section is being revised — see
> [#2629](https://github.com/wazuh/wazuh-docker/issues/2629).


To override configuration values from files such as `opensearch.yml` and `opensearch_dashboards.yml` using environment variables:

1. Convert the configuration key to uppercase.
2. Replace any dots (`.`) in the key with underscores (`_`).
3. Assign the corresponding value.

### Examples:

| YAML Key                                | Environment Variable                       |
|-----------------------------------------|--------------------------------------------|
| `discovery.type: single-node`           | `DISCOVERY_TYPE=single-node`               |
| `opensearch.hosts: https://url:9200`    | `OPENSEARCH_HOSTS=https://url:9200`        |
| `server.port: 5601`                     | `SERVER_PORT=5601`                         |

This approach allows you to configure the services dynamically via Docker without modifying internal files.

---
