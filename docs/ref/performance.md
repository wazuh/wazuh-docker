# Performance

This section provides practical recommendations to improve performance for Wazuh Docker deployments (single-node and multi-node). Apply the controls that match your workload and environment.

## Performance drivers

- **Wazuh Indexer** is typically the main bottleneck (JVM heap, disk I/O, and CPU).
- **Wazuh Manager** load grows with the number of connected agents and event throughput.
- **Wazuh Dashboard** mainly affects interactive usage and depends on Indexer responsiveness.

For baseline host sizing and prerequisites, see [Requirements](getting-started/requirements.md).

## Storage and host

- Use low-latency storage for the Indexer data volume (see [Requirements](getting-started/requirements.md)).
- Avoid slow or inconsistent storage for the Indexer (for example, network filesystems) unless you have validated latency and durability for your use case.
- Monitor disk space growth. Index data and persistent volumes can grow quickly in high-ingest environments.

## Wazuh Indexer (OpenSearch)

- Set the JVM heap explicitly using `OPENSEARCH_JAVA_OPTS` (documented in [Environment variables](configuration/environment-variables.md)).
- Keep heap sizing conservative relative to available memory so the OS can cache filesystem data; oversized heap commonly degrades disk-heavy workloads.
- Ensure the Linux host meets the required `vm.max_map_count` prerequisite (documented in [Requirements](getting-started/requirements.md)).
- Prioritize heap sizing and GC stability.
- Prioritize disk throughput/latency for the Indexer data volume.
- Prioritize CPU availability during ingest peaks.

## Wazuh Manager

- If you observe ingestion backpressure or delayed processing, validate that the Manager has sufficient CPU and memory and that persistent volumes are not constrained by slow storage.
- For multi-node deployments, distribute agent load appropriately (for example, by separating responsibilities between master/worker nodes) to avoid overloading.

## Dashboard

- Dashboard responsiveness depends on Indexer health. Address Indexer resource constraints first when troubleshooting slow UI queries.
- Avoid exposing the Dashboard to excessive concurrent users on small hosts; scale the host or deployment model if needed.

## Observability and troubleshooting

- Start with container-level signals: `docker stats`, container logs, and host disk utilization.
- For Indexer issues, validate basic cluster health and look for sustained CPU saturation, JVM memory pressure, and disk I/O contention.
- For Manager issues, review Manager logs for queue growth and repeated connection retries.
