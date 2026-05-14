# Deploy Wazuh Docker in single node configuration

This deployment is defined in the `docker-compose.yml` file with one Wazuh manager containers, one Wazuh indexer containers, and one Wazuh dashboard container. It can be deployed by following these steps: 

1) Increase max_map_count on your host (Linux). This command must be run with root permissions:
```
$ sysctl -w vm.max_map_count=262144
```
2) Run the certificate creation script:
```
$ docker compose -f generate-indexer-certs.yml run --rm generator
```
3) Start the environment with docker compose:

- In the foregroud:
```
$ docker compose up
```
- In the background:
```
$ docker compose up -d
```

The environment takes about 1 minute to get up (depending on your Docker host) for the first time since Wazuh Indexer must be started for the first time and the indexes and index patterns must be generated.

## Loki / Alloy (optional)

The manager service bind-mounts **`./wazuh-alerts-export`** to **`/var/ossec/logs/alerts`** so `alerts.json` is visible on the host for **Grafana Alloy** in `grafana-loki-alloy` (labeled `job=wazuh` in Loki). That directory is gitignored.

**Permissions (required):** Docker usually creates the host directory as **root**. Inside the container, **`wazuh-analysisd` runs as uid 999** and must create paths such as `logs/alerts/2026/`. If ownership is wrong, `wazuh-analysisd` exits, the Wazuh **API returns 500**, and the dashboard shows errors (for example `getUserPolicies`, `check-stored-api`).

After the directory exists (first `docker compose up` is enough to create it), run:

```bash
cd single-node
chmod +x scripts/ensure-alerts-export-perms.sh
./scripts/ensure-alerts-export-perms.sh   # uses sudo if not already root-owned by 999
# if the script tells you to run sudo chown, do that, then:
docker compose restart wazuh.manager
```

Confirm: `docker exec "$(docker compose ps -q wazuh.manager)" /var/ossec/bin/wazuh-control status` should show **`wazuh-analysisd is running`**.
