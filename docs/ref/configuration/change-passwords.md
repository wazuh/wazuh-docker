# Change passwords

This section describes how to rotate the credentials used by the provided Docker Compose deployments.

## Scope

The Compose files include the following password-controlled integrations:

- **Wazuh Indexer access (Manager and Dashboard clients)**: `INDEXER_USERNAME`, `INDEXER_PASSWORD`
- **Wazuh Dashboard login**: `DASHBOARD_USERNAME`, `DASHBOARD_PASSWORD`
- **Wazuh API access (Dashboard client)**: `API_USERNAME`, `API_PASSWORD`

For variable descriptions, see [Environment variables](environment-variables.md).

## Rotate credentials

1. Navigate to your deployment directory:

    - `single-node/` (single-node stack)
    - `multi-node/` (multi-node stack)

2. Edit the deployment `docker-compose.yml` and update the required values under `environment`:

    - Single-node: update `wazuh.manager` and `wazuh.dashboard`.
    - Multi-node: update `wazuh.master`, `wazuh.worker`, and `wazuh.dashboard`.

    Ensure `INDEXER_USERNAME` and `INDEXER_PASSWORD` are consistent anywhere they are defined.

3. Recreate the containers to apply the new values:

    ```bash
    docker compose down
    docker compose up -d
    ```

4. Validate access:

    - Log in to the Dashboard with the updated credentials.
    - Confirm the Dashboard can query data (indirectly validating the Indexer and API credentials).

## Notes

- The Manager applies `API_USERNAME` / `API_PASSWORD` at startup by creating or updating the API user.
- The Dashboard regenerates its OpenSearch Dashboards keystore on startup; changes take effect after the container is recreated.
- Rotating Indexer credentials requires updating both the Indexer user configuration and the Compose client variables (`INDEXER_*`).
