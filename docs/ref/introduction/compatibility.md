# Compatibility

This section provides information about the compatibility of the Wazuh Docker stack with different platforms.

## Supported platforms

### Host operating system and architecture

- Linux hosts are recommended for running the stack.
- Windows and macOS are supported when using Docker Desktop. On Windows, the WSL 2 backend is recommended.
- When building images, the build process supports `linux/amd64` and `linux/arm64`.

### Privileged ports and rootless Docker

The default Compose deployments publish some privileged ports on the host (for example, the Dashboard on `443/tcp` and syslog on `514/udp`).

- If you run Docker in rootless mode or under restrictive policies, publishing ports below `1024` may fail.
- In such environments, map the services to non-privileged host ports in the corresponding `docker-compose.yml` file.

### Resource constraints

For detailed information on resource requirements and recommendations, please refer to the [Requirements](../getting-started/requirements.md) section.
