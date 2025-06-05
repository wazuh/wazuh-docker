# Environment Variables in Wazuh Docker Deployment

This document outlines the environment variables applicable to the Wazuh Docker deployment, covering the Wazuh Manager, Indexer, Dashboard, and Agent components. It also explains how to override configuration settings using environment variables.

## Table of Contents

- [Wazuh Manager](#wazuh-manager)
- [Wazuh Indexer](#wazuh-indexer)
- [Wazuh Dashboard](#wazuh-dashboard)
- [Wazuh Agent](#wazuh-agent)
- [Overriding Configuration Files with Environment Variables](#overriding-configuration-files-with-environment-variables)

---

## Wazuh Manager

The Wazuh Manager container accepts the following environment variables, which can be set in the `docker-compose.yml` file under the `environment` section:

```yaml
environment:
  - INDEXER_USERNAME=admin
  - INDEXER_PASSWORD=SecretPassword
  - WAZUH_API_URL=https://wazuh.manager
  - DASHBOARD_USERNAME=kibanaserver
  - DASHBOARD_PASSWORD=kibanaserver
  - API_USERNAME=wazuh-wui
  - API_PASSWORD=MyS3cr37P450r.*-
```

**Variable Descriptions:**

- `INDEXER_USERNAME` / `INDEXER_PASSWORD`: Credentials for accessing the Wazuh Indexer with `admin` user or a user with the same permissions.
- `WAZUH_API_URL`: URL of the Wazuh API, used by other services for communication.
- `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD`: Credentials for the Wazuh Dashboard to authenticate with the Indexer.
- `API_USERNAME` / `API_PASSWORD`: Credentials for the Wazuh API user, utilized by the Dashboard for API interactions.

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
  - INDEXER_USERNAME=admin
  - INDEXER_PASSWORD=SecretPassword
  - WAZUH_API_URL=https://wazuh.manager
  - DASHBOARD_USERNAME=kibanaserver
  - DASHBOARD_PASSWORD=kibanaserver
  - API_USERNAME=wazuh-wui
  - API_PASSWORD=MyS3cr37P450r.*-
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
  - WAZUH_MANAGER_PORT=1514
  - WAZUH_REGISTRATION_SERVER=wazuh.manager
  - WAZUH_REGISTRATION_PORT=1515
  - WAZUH_AGENT_NAME=my-agent
  - WAZUH_REGISTRATION_PASSWORD=StrongPassword
```

These variables are used by the `set_manager_conn()` function in the entrypoint script to replace placeholder values in `ossec.conf` and set the enrollment password.

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
