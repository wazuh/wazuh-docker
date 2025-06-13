# Reference Manual - Configuration

This section details how to configure your Wazuh-Docker deployment (version 4.13.1). Proper configuration is key to tailoring the Wazuh stack to your specific needs, managing data persistence, and integrating with your environment.

## Overview of Configuration Methods

Configuring Wazuh components within a Docker environment typically involves several methods:

1.  **[Environment Variables](environment-variables.md)**:
    * Many container settings are controlled by passing environment variables at runtime (e.g., via the `docker-compose.yml` file or `docker run` commands).
    * These are often used for setting up initial passwords, component versions, cluster names, or basic operational parameters.

2.  **[Configuration Files](configuration-files.md)**:
    * Core Wazuh components (manager, indexer, dashboard) rely on their traditional configuration files (e.g., `ossec.conf`, `opensearch.yml`, `opensearch_dashboards.yml`).
    * To customize these, you typically mount your custom configuration files into the containers, replacing or supplementing the defaults. This is managed using Docker volumes in your `docker-compose.yml`.

3.  **Docker Compose File (`docker-compose.yml`)**:
    * The `docker-compose.yml` file itself is a primary configuration tool. It defines:
        * Which services (containers) to run.
        * The Docker images to use.
        * Port mappings.
        * Volume mounts for persistent data and custom configurations.
        * Network configurations.
        * Resource limits (CPU, memory).
        * Dependencies between services.

4.  **Persistent Data Volumes**:
    * Configuration related to data storage (e.g., paths for Wazuh Indexer data, Wazuh manager logs and agent keys) is managed through Docker volumes. Persisting these volumes ensures your data and critical configurations survive container restarts or recreations.
