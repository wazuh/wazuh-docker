# Security

This section summarizes security recommendations for Wazuh Docker deployments (single-node and multi-node). Apply the controls that match your environment and risk profile.

## Credentials and secrets

- Do not use default credentials. The Compose examples include placeholder values for the Wazuh API, Dashboard, and Indexer access.
- Prefer injecting secrets at runtime (for example, via your CI/CD secret store or an external secrets manager) instead of hardcoding them in `docker-compose.yml`.
- Rotate credentials regularly and after any suspected exposure.
- The Wazuh dashboard keeps its secrets in `opensearch_dashboards.keystore`, persisted in the `wazuh-dashboard-config` volume. It stores the Indexer credentials and the `wazuh_ai_assistant.encryptionKey`, generated at random on the first start and unique per deployment. Restrict access to that volume and to `docker compose exec` on the dashboard container, and do not copy the keystore between deployments.

### Manager cluster key

`<cluster><key>` authenticates the communication between manager nodes on port `1516`, and it is the only credential in that exchange. The manager image ships an empty key, so nothing usable for it is published inside the image:

- **A single manager** generates its own key on its first start, so no two deployments of the same image tag share a cluster secret.
- **The manager nodes of one cluster** need the same value. The multi-node Compose file gives both managers the `wazuh-cluster-key` volume on `/wazuh-cluster-key`: the first node to start creates a random key there and the others read it, so the cluster comes up on a secret that is unique to the deployment and is stored neither in the image nor in the repository. Nodes starting at the same time cannot disagree on it, and the value never appears in the container environment, so `docker inspect` and `/proc/<pid>/environ` do not expose it.
- **Manager nodes on separate hosts** cannot share that volume. Set `WAZUH_CLUSTER_KEY` to the same value on every node instead (`openssl rand -hex 16` generates one); it takes precedence over both the shared volume and the node's own configuration.

The key in use is written to `etc/wazuh-manager.conf` in each manager `etc` volume, so it is stable across restarts and container recreation.

- Treat the `wazuh-cluster-key` volume as a secret of the deployment: restrict access to it as you do for the certificates, and do not copy it, or the manager `etc` volumes, between deployments.
- To rotate the key of a multi-node deployment, remove the shared volume and start again. The first node to come up creates a new one and the rest of the nodes adopt it:
  ```bash
  docker compose down
  docker volume rm multi-node_wazuh-cluster-key
  docker compose up -d
  ```
- A deployment created with an older image is still running on the key that image shipped. Moving it to this Compose file and image is enough to leave that key behind: the shared volume starts out empty, so the first manager node to come up creates a new key and the others adopt it. A deployment that keeps an older Compose file, without the shared volume, goes on using the key already stored in its manager `etc` volumes until you set `WAZUH_CLUSTER_KEY`.

## Certificates and TLS

- Protect the generated `wazuh-certificates/` directory. Limit filesystem permissions and do not publish it.
- Regenerate certificates if private keys are leaked or if nodes are re-provisioned.
- Use certificates and TLS settings appropriate for production (trusted CA, correct DNS names, and key protection).

### Manager self-signed certificate

The Wazuh manager image ships no self-signed certificate. Each manager container generates its own `etc/certs/remoted.pem` and `etc/certs/remoted-key.pem` on its first start, so no two containers share a private key. That pair serves both the HTTPS agent listener and the agent enrollment service (`authd`), and it is stored in the manager `etc` volume (`wazuh_etc` in single-node; `master-wazuh-etc` and `worker-wazuh-etc` in multi-node), which keeps it stable across restarts and container recreation.

- Do not copy or share the manager `etc` volume between deployments, and do not bake the pair into a derived image: either reintroduces a shared private key.
- To rotate the certificate, remove both files and restart the manager. The next start generates a new pair:
  ```bash
  docker compose exec wazuh.manager rm -f /var/wazuh-manager/etc/certs/remoted.pem \
                                          /var/wazuh-manager/etc/certs/remoted-key.pem
  docker compose restart wazuh.manager
  ```
- To use your own certificate instead, mount the pair at those paths owned by `101:101` (`wazuh-manager:wazuh-manager`) with mode `640`. The container detects it and does not overwrite it. The manager opens these files after dropping privileges, so any other ownership prevents the HTTPS listener from starting.
- The Wazuh API certificate (`etc/certs/apid.pem` and `apid-key.pem`) is generated by the API on its first start, and is also unique per container.

## Network exposure

- Restrict access to exposed service ports at the host firewall and security group level.
- Do not expose internal-only endpoints to untrusted networks. In particular, limit access to the Indexer API port (`9200`) and the Wazuh API port (`55000`) to administrative networks.

## Host and runtime hardening

- Run Docker on a hardened host (patched OS, minimal installed packages, restricted SSH access).
- Limit access to the Docker daemon. Docker socket access grants administrative control over the host.
- Ensure persistent volumes and bind-mounted configuration files are backed by secure storage and appropriate permissions.
