# Reference Manual - Requirements

Before deploying Wazuh-Docker (version 4.13.1), it's essential to ensure your environment meets the necessary hardware and software requirements. Meeting these prerequisites will help ensure a stable and performant Wazuh deployment.

## Host System Requirements

These are general recommendations. Actual needs may vary based on the number of agents, data volume, and usage patterns.

### Hardware:

* **CPU**:
    * **Minimum**: 2 CPU cores.
    * **Recommended**: 4 CPU cores or more, especially for production environments or deployments with a significant number of agents.
* **RAM**:
    * **Minimum (Single-Node Test/Small Environment)**: 4 GB RAM. This is a tight minimum; 6 GB is safer.
        * Wazuh Indexer (OpenSearch): Typically requires at least 1 GB RAM allocated to its JVM heap.
        * Wazuh Manager: Resource usage depends on the number of agents.
        * Wazuh Dashboard (OpenSearch Dashboards): Also consumes memory.
    * **Recommended (Production/Multiple Agents)**: 8 GB RAM or more.
* **Disk Space**:
    * **Minimum**: 50 GB of free disk space.
    * **Recommended**: 100 GB or more, particularly for the Wazuh Indexer data. Disk space requirements will grow over time as more data is collected and indexed.
    * **Disk Type**: SSDs (Solid State Drives) are highly recommended for the Wazuh Indexer data volumes for optimal performance.
* **Network**:
    * A stable network connection with sufficient bandwidth, especially if agents are reporting from remote locations.

### Software:

* **Operating System**:
    * A 64-bit Linux distribution is preferred (e.g., Ubuntu, CentOS, RHEL, Debian).
* **Docker Engine**:
    * Version `20.10.0` or newer.
    * Install Docker by following the official instructions: [Install Docker Engine](https://docs.docker.com/engine/install/).
* **Git Client**:
    * Required for cloning the `wazuh-docker` repository.
* **Web Browser**:
    * A modern web browser (e.g., Chrome, Firefox, Edge, Safari) for accessing the Wazuh Dashboard.
* **`vm.max_map_count` (Linux Hosts for Wazuh Indexer/OpenSearch)**:
    * The Wazuh Indexer (OpenSearch) requires a higher `vm.max_map_count` setting than the default on most Linux systems.
    * Set it permanently:
        1.  Edit `/etc/sysctl.conf` and add/modify the line:
            ```
            vm.max_map_count=262144
            ```
        2.  Apply the change without rebooting:
            ```bash
            sudo sysctl -p
            ```
    * This is crucial for the stability of the Wazuh Indexer.

## Network Ports

Ensure that the necessary network ports are open and available on the Docker host and any firewalls:

* **Wazuh Manager**:
    * `1514/UDP`: For agent communication (syslog).
    * `1514/TCP`: For agent communication (if using TCP).
    * `1515/TCP`: For agent enrollment.
    * `55000/TCP`: For Wazuh API (default).
* **Wazuh Indexer**:
    * `9200/TCP`: For HTTP REST API.
    * `9300/TCP`: For inter-node communication (if clustered).
* **Wazuh Dashboard**:
    * `5601/TCP` (or `443/TCP` if HTTPS is configured via a reverse proxy): For web access.

Port mappings in `docker-compose.yml` will expose these container ports on the host. Adjust host ports if defaults cause conflicts.

## Important Considerations

* **Production Environments**: For production, it's highly recommended to follow best practices for securing Docker and your host system. Consider using a multi-node setup for resilience.
* **Resource Allocation**: Monitor resource usage after deployment and adjust allocations (CPU, RAM for Docker, JVM heap for Wazuh Indexer) as necessary.

Meeting these requirements will pave the way for a smoother deployment and a more stable Wazuh-Docker experience.
