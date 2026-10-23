# Backup and restore

For backup and restore, refer to the documentation for each component:

- [Wazuh manager](https://github.com/wazuh/wazuh/blob/v5.0.1/docs/ref/backup-restore.md), including [container deployments](https://github.com/wazuh/wazuh/blob/v5.0.1/docs/ref/backup-restore.md#container-deployments)
- [Wazuh agent](https://github.com/wazuh/wazuh/blob/v5.0.1/docs/ref/backup-restore.md#agent-backup-and-restore)

## What a Docker deployment keeps outside the containers

Back up these together with the component procedures above. Stop the stack (`docker compose stop`) before copying the volumes, so the databases are consistent.

- **Named volumes** (`docker volume ls`; names are prefixed with the Compose project, for example `single-node_wazuh_etc`):
  - Wazuh manager: `wazuh_etc` (configuration, `client.keys`, `local.env`, `export/`, `certs/`), `wazuh_api_configuration` (`rbac.db`), `wazuh_queue` (`global.db`, keystore), `wazuh_var_multigroups`, `wazuh_data` and `wazuh_logs`. In multi-node, the `master-wazuh-*` and `worker-wazuh-*` volumes, and `wazuh-cluster-key` (the cluster key shared by the manager nodes).
  - Wazuh indexer: `wazuh-indexer-data` (`wazuh-indexer-data-1` to `-3` in multi-node).
  - Wazuh dashboard: `wazuh-dashboard-config` (configuration and keystore) and `wazuh-dashboard-custom`.
- **Files on the host**, in the deployment directory:
  - `config/credentials/*.env`: the deployment's passwords.
  - `config/*/certs/`: the certificates the containers mount.
  - `wazuh-ca/` next to `wazuh-certs-tool.sh` (or the directory set in `WAZUH_CA_DIR`): the root CA and its private key, needed to issue certificates for new nodes.

These files are owned by root, so copy them with `sudo` and keep the backup as restricted as the originals.
