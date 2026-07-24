# Security

This section summarizes security recommendations for Wazuh Docker deployments (single-node and multi-node). Apply the controls that match your environment and risk profile.

## Credentials and secrets

- Do not use default credentials. The Compose examples include placeholder values for the Wazuh API, Dashboard, and Indexer access.
- Prefer injecting secrets at runtime (for example, via your CI/CD secret store or an external secrets manager) instead of hardcoding them in `docker-compose.yml`.
- Rotate credentials regularly and after any suspected exposure.

## Certificates and TLS

- Protect the generated `wazuh-certificates/` directory. Limit filesystem permissions and do not publish it.
- Regenerate certificates if private keys are leaked or if nodes are re-provisioned.
- Use certificates and TLS settings appropriate for production (trusted CA, correct DNS names, and key protection).

## Network exposure

- Restrict access to exposed service ports at the host firewall and security group level.
- Do not expose internal-only endpoints to untrusted networks. In particular, limit access to the Indexer API port (`9200`) and the Wazuh API port (`55000`) to administrative networks.

## Host and runtime hardening

- Run Docker on a hardened host (patched OS, minimal installed packages, restricted SSH access).
- Limit access to the Docker daemon. Docker socket access grants administrative control over the host.
- Ensure persistent volumes and bind-mounted configuration files are backed by secure storage and appropriate permissions.
