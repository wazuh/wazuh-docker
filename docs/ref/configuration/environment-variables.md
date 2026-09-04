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
  - WAZUH_API_URL=https://wazuh.manager
  - DASHBOARD_USERNAME=kibanaserver
  - DASHBOARD_PASSWORD=kibanaserver
```

**Variable Descriptions:**

- `INDEXER_USERNAME` / `INDEXER_PASSWORD`: Credentials for accessing the Wazuh Indexer with `wazuh-manager` user or a user with the same permissions.
- `WAZUH_API_URL`: URL of the Wazuh API, used by other services for communication.
- `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD`: Credentials for the Wazuh Dashboard to authenticate with the Indexer.
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
  - INDEXER_USERNAME=wazuh-manager
  - INDEXER_PASSWORD=wazuh-manager
  - WAZUH_API_URL=https://wazuh.manager
  - DASHBOARD_USERNAME=kibanaserver
  - DASHBOARD_PASSWORD=kibanaserver
```

**Variable Descriptions:**

- `INDEXER_USERNAME` / `INDEXER_PASSWORD`: Credentials used by the Dashboard to authenticate with the Wazuh Indexer.
- `WAZUH_API_URL`: Base URL of the Wazuh API, used for querying and visualizing security data.
- `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD`: User credentials for the Dashboard interface.
- `API_USERNAME` / `API_PASSWORD`: API user credentials for authenticating Wazuh API requests initiated by the Dashboard.

These variables are critical for enabling communication between the Wazuh Dashboard, the Wazuh Indexer, and the Wazuh API.

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
