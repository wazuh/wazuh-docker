# Wazuh Multi-Node PoC with HAProxy SNI

This setup replaces the original NGINX stream load balancer with **HAProxy 2.9** running in TCP/SNI passthrough mode.

## Architecture

```
                        +----------------------------------+
                        |          HAProxy 2.9             |
                        |  port 443  -> wazuh.dashboard    |
                        |  port 1514 -> master / worker LB |
                        |  port 1515 -> master (enrollment)|
                        +----------------------------------+
                                       |
           +---------------------------+-------------------+
           v                           v                   v
   wazuh.master               wazuh.worker         wazuh.dashboard
   (wazuh-manager)            (wazuh-manager)      (wazuh-dashboard)
           |
           +--- wazuh1.indexer / wazuh2.indexer / wazuh3.indexer
```

## Changes from original

| Component | Before (nginx) | After (haproxy) |
|-----------|---------------|------------------|
| Port 443 | Not exposed | SNI passthrough to dashboard |
| Port 1514 | stream LB | TCP leastconn LB master+worker |
| Port 1515 | Not exposed | TCP passthrough to master |
| Dashboard port | Exposed on host 443 | Internal only (expose) |
| Manager ports | Exposed on host | Internal only (expose) |
| Cert generation | Manual | `certgen` service (profile tools) |

## Execution order

### 1) Generate certificates
```bash
docker compose --profile tools run --rm certgen
```

Generated certs will be placed in `./config/certs/`. The `certs.yml` defines all six nodes:
- `wazuh1.indexer`, `wazuh2.indexer`, `wazuh3.indexer`
- `wazuh.dashboard`
- `wazuh.master`, `wazuh.worker`

### 2) Start indexers
```bash
docker compose up -d wazuh1.indexer wazuh2.indexer wazuh3.indexer
```

### 3) Wait for indexers to be healthy
```bash
docker compose ps
```

### 4) Start managers
```bash
docker compose up -d wazuh.master
docker compose up -d wazuh.worker
```

### 5) Start dashboard and HAProxy
```bash
docker compose up -d wazuh.dashboard haproxy
```

### 6) Validate
```bash
docker compose ps
curl -k https://localhost/app/wazuh
```

## Agent configuration

Point agents to HAProxy on port 1514 (events) and 1515 (enrollment):

```xml
<client>
  <server>
    <address>IP_DO_HAPROXY</address>
    <port>1514</port>
    <protocol>tcp</protocol>
  </server>
</client>
```

## Notes

- HAProxy runs in **TCP mode** - TLS is not terminated at the proxy level.
- SNI inspection on port 443 routes traffic based on `req.ssl_sni`.
- Port 1514 uses `leastconn` to distribute agent connections between master and worker.
- Enrollment (1515) routes only to master.
- All certs are generated to and read from `./config/certs/` (single directory, no per-service subdirs).
