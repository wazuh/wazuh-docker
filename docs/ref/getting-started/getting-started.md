# Reference Manual - Getting Started

This section guides you through the initial steps to get your Wazuh-docker (version 4.13.1) environment up and running. We will cover the prerequisites and point you to the deployment instructions.

## Overview

Getting started with Wazuh-Docker involves the following general steps:

1.  **Understanding Requirements**: Ensuring your system meets the necessary hardware and software prerequisites.
2.  **Choosing a Deployment Type**: Deciding whether a single-node or multi-node deployment is suitable for your needs.
3.  **Setting up Docker**: Installing Docker and Docker Compose if you haven't already.
4.  **Obtaining Wazuh-Docker Files**: Cloning the `wazuh-docker` repository or downloading the necessary `docker-compose.yml` and configuration files.
5.  **Deploying the Stack**: Running `docker compose up` to launch the Wazuh components.
6.  **Initial Configuration & Verification**: Performing any initial setup steps and verifying that all components are working correctly.
7.  **Deploying Wazuh Agents**: Installing and configuring Wazuh agents on the endpoints you want to monitor and connecting them to your Wazuh manager.

## Before You Begin

Before diving into the deployment, please ensure you have reviewed:

-   The [Description](ref/Introduction/description.md) of Wazuh-docker to understand the components and architecture.
-   The [Requirements](ref/getting-started/requirements.md) to confirm your environment is suitable.

## Steps to Get Started

1.  **Meet the [Requirements](requirements.md)**:
    Verify that your host system has sufficient RAM, CPU, and disk space. Ensure Docker and Docker Compose are installed and functioning correctly.

2.  **Obtain Wazuh-docker Configuration**:
    You'll need the Docker Compose files and any associated configuration files from the `wazuh-docker` repository for version 4.13.1.
    ```bash
    git clone [https://github.com/wazuh/wazuh-docker.git](https://github.com/wazuh/wazuh-docker.git)
    cd wazuh-docker
    git checkout v4.13.1
    # Navigate to the specific docker-compose directory, e.g., single-node or multi-node
    # cd docker-compose/single-node/ (example path)
    ```
    Alternatively, you might download specific `docker-compose.yml` files if provided as part of a release package.

3.  **Choose Your [Deployment Strategy](deployment/deployment.md)**:
    Wazuh-docker supports different deployment models. Select the one that best fits your use case:
    * **[Single Node Wazuh Stack](deployment/single-node.md)**: Ideal for testing, small environments, or proof-of-concept deployments. All main components (Wazuh manager, Wazuh indexer, Wazuh dashboard) run on a single Docker host.
    * **[Multi Node Wazuh Stack](deployment/multi-node.md)**: Suitable for production environments requiring high availability and scalability. Components might be distributed across multiple hosts or configured in a clustered mode. (Note: True multi-host orchestration often involves Kubernetes, but multi-node within Docker Compose typically refers to clustered Wazuh Indexer/Manager setups on one or more Docker hosts managed carefully).
    * **[Wazuh Agent Deployment](deployment/wazuh-agent.md)**: Instructions for deploying Wazuh agents on your endpoints and connecting them to the Wazuh manager running in Docker.

4.  **Follow Deployment Instructions**:
    Once you've chosen a deployment strategy, follow the detailed instructions provided in the respective sections linked above. This will typically involve:
    * Configuring environment variables (if necessary).
    * Initializing persistent volumes.
    * Starting the services.

5.  **Post-Deployment**:
    After the stack is running:
    * Access the Wazuh Dashboard via your web browser.
    * Verify that all services are healthy.
    * Begin enrolling Wazuh agents.

This Getting Started guide provides a high-level overview. For detailed, step-by-step instructions, please refer to the specific pages linked within this section.
