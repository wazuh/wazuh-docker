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
  - WAZUH_MANAGER_SERVER=wazuh.manager
  - WAZUH_MANAGER_PORT=1517
  - WAZUH_AGENT_NAME=my-agent
  - WAZUH_REGISTRATION_PASSWORD=my-authd-password
```

The manager connection can also be given as a single value instead of a host and
a port:

```yaml
environment:
  - WAZUH_MANAGER_ENDPOINT=wazuh.manager:1517/wazuh-manager/
  - WAZUH_AGENT_NAME=my-agent
  - WAZUH_REGISTRATION_PASSWORD=my-authd-password
```

**Variable Descriptions:**

- `WAZUH_MANAGER_ENDPOINT`: Full manager endpoint, `host[:port][/prefix]`, written to `<agent><manager><endpoint>`. Takes precedence over `WAZUH_MANAGER_SERVER` and `WAZUH_MANAGER_PORT`. The port defaults to `1517` and the path prefix to `/wazuh-manager/` when left out, so `wazuh.manager` and `wazuh.manager:1517/wazuh-manager/` describe the same connection. A `https://` scheme is accepted and dropped. An IPv6 literal must be bracketed when a port follows it, as in `[fd00::1]:1517`.
- `WAZUH_MANAGER_SERVER`: Address of the Wazuh Manager. Used as the host of the endpoint when `WAZUH_MANAGER_ENDPOINT` is not set.
- `WAZUH_MANAGER_PORT`: Manager HTTPS port. Defaults to `1517`, and must match the manager `<remote><https><port>`. Since 5.0.0 enrollment runs over the same connection, so this is also the registration port.
- `WAZUH_AGENT_NAME`: Agent name used on enrollment, written to `<agent><enrollment><agent_name>`. Defaults to `wazuh-agent-<container hostname>`.
- `WAZUH_REGISTRATION_PASSWORD`: Enrollment password, written to `/var/ossec/etc/authd.pass`.

These variables are used by the `set_manager_conn()` function in the entrypoint script to replace placeholder values in `ossec.conf`.

`WAZUH_REGISTRATION_SERVER` and `WAZUH_REGISTRATION_PORT` are no longer honored: since 5.0.0 the agent enrolls through the manager connection it already has instead of opening a separate connection to `authd`, so `<enrollment>` carries neither an address nor a port of its own. The container logs a warning when either variable is set.

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
