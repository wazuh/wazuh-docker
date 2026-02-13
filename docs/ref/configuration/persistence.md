# Persistence configuration

When customizing your Wazuh Docker deployment, certain files and directories must be persisted to retain your changes across container restarts and recreations. This is critical for maintaining custom configurations, user credentials, and security settings.

## General Instructions

Docker volumes allow you to persist data outside of container lifecycles. When a container is removed or recreated, data stored in volumes remains intact. This is essential for maintaining configuration files, user data, and other persistent state.

### Using Docker Volumes for Persistence

To persist files or directories in your Wazuh deployment, you can mount them as volumes in your `docker-compose.yml` file. The general syntax is:

```yaml
services:
  service_name:
    volumes:
      - /host/path/to/file:/container/path/to/file
      - /host/path/to/directory:/container/path/to/directory
```

**Example**: To persist a specific configuration file:

```yaml
services:
  wazuh.indexer:
    volumes:
      - ./config/custom-config.yml:/usr/share/wazuh-indexer/config/custom-config.yml
```

> **Important**: Ensure that files exist on the host before starting the containers. If the file doesn't exist, Docker will create a directory instead, which may cause startup failures.

For more information on Docker volumes and bind mounts, refer to the official Docker documentation:
- [Use volumes](https://docs.docker.com/storage/volumes/)
- [Bind mounts](https://docs.docker.com/storage/bind-mounts/)

## Wazuh Indexer

### Internal Users

The `internal_users.yml` file contains the initial users and passwords for the Wazuh Indexer. This file is not included by default in the repository and must be created manually if you wish to customize internal users or update passwords.

#### Creating the Configuration File

1. Create the directory:
    ```bash
    mkdir -p ./config/wazuh_indexer/
    ```

2. Create the file: Create `./config/wazuh_indexer/internal_users.yml` with your user definitions. Here is a basic example:
    ```yaml
    ---
    # This is the internal user database
    # The hash value is a bcrypt hash and can be generated with /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh

    _meta:
      type: "internalusers"
      config_version: 2

    # Default users

    admin:
      hash: "$2a$12$VcCDgh2NDk07JGN0rjGbM.Ad41qVR/YFJcgHp0UGns5JDymv..TOG"
      reserved: true
      backend_roles:
      - "admin"
      description: "Admin user"

    kibanaserver:
      hash: "$2a$12$4AcgAt3xwOWadA5s5blL6ev39OXDNhmOesEoo33eZtrq2N0YrU3H."
      reserved: true
      description: "Kibana server user"
    ```

> **Important**: This example includes the default `admin` and `kibanaserver` users with their default passwords (hashed). These users are required for the standard `docker-compose.yml` configuration (e.g., `INDEXER_USERNAME=admin` and `DASHBOARD_USERNAME=kibanaserver`) to function correctly. If you change these passwords, you must also update the corresponding environment variables in your `docker-compose.yml`.

#### Docker Compose Configuration

To persist the `internal_users.yml` file, add a volume mount to your `docker-compose.yml` for the `wazuh.indexer` service:

```yaml
services:
  wazuh.indexer:
    volumes:
      - ./config/wazuh_indexer/internal_users.yml:/usr/share/wazuh-indexer/opensearch-security/securityconfig/internal_users.yml
```

#### Applying Changes

After modifying `internal_users.yml`, restart the stack to apply the changes:

```bash
docker-compose down
```

```bash
docker-compose up -d
```

## Other Components

For other components like the Wazuh Manager and Wazuh Dashboard, persistence is typically handled by mounting their respective configuration directories or using Docker volumes for data storage.

-   **Wazuh Manager**: Persist `/var/ossec/data` and `/var/ossec/etc` (or specific files like `ossec.conf`) to retain rules, decoders, and logs.
-   **Wazuh Dashboard**: Persist `/usr/share/wazuh-dashboard/data` to retain tenants, dashboards, and visualizations.

Refer to the [Configuration Files](configuration-files.md) section for more details on mapping specific configuration files.
