# Reference Manual - Deployment

This section provides detailed instructions for deploying Wazuh-Docker (version 4.13.1) in various configurations. Choose the deployment model that best suits your needs, from simple single-node setups for testing to more robust multi-node configurations for production environments.

## Overview of Deployment Options

Wazuh-Docker offers flexibility in how you can deploy the Wazuh stack. The primary methods covered in this documentation are:

1.  **[Single Node Wazuh Stack](single-node.md)**:
    * **Description**: Deploys all core Wazuh components (Wazuh manager, Wazuh indexer, Wazuh dashboard) as Docker containers on a single host machine.
    * **Use Cases**: Ideal for development, testing, demonstrations, proof-of-concepts, and small-scale production environments where simplicity is prioritized and high availability is not a critical concern.
    * **Pros**: Easiest and quickest to set up.
    * **Cons**: Single point of failure; limited scalability compared to multi-node.

2.  **[Multi Node Wazuh Stack](multi-node.md)**:
    * **Description**: This typically refers to deploying a Wazuh Indexer cluster and potentially multiple Wazuh managers for improved scalability and resilience. While true multi-host orchestration often uses tools like Kubernetes, this section may cover configurations achievable with Docker Compose, possibly across multiple Docker hosts or with clustered services on a single powerful host.
    * **Use Cases**: Production environments requiring higher availability, data redundancy (for Wazuh Indexer), and the ability to handle a larger number of agents.
    * **Pros**: Improved fault tolerance (for clustered components like the Indexer), better performance distribution.
    * **Cons**: More complex to set up and manage than a single-node deployment.

## Before You Begin Deployment

Ensure you have:

-   Met all the [System Requirements](ref/getting-started/requirements.md).
-   Installed Docker and Docker Compose on your host(s).
-   Cloned the `wazuh-docker` repository (version `4.13.1`) or downloaded the necessary deployment files.
    ```bash
    git clone [https://github.com/wazuh/wazuh-docker.git](https://github.com/wazuh/wazuh-docker.git)
    cd wazuh-docker
    git checkout v4.13.1
    ```
-   Made a backup of any existing Wazuh data if you are migrating or upgrading.

## Choosing the Right Deployment

Consider the following factors when choosing a deployment model:

-   **Scale**: How many agents do you plan to connect?
-   **Availability**: What are your uptime requirements?
-   **Resources**: What hardware resources (CPU, RAM, disk) are available?
-   **Complexity**: What is your team's familiarity with Docker and distributed systems?

For most new users, starting with the [Single Node Wazuh Stack](single-node.md) is recommended to familiarize themselves with Wazuh-Docker. You can then explore more complex setups as your needs grow.

Navigate to the specific deployment guide linked above for detailed, step-by-step instructions.
