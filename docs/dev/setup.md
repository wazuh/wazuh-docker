# Development Guide - Setup Environment

This section outlines the steps required to set up your local development environment for working with the Wazuh-Docker project (version 4.13.1). A proper setup is crucial for building images, running tests, and contributing effectively.

## Prerequisites

Before you begin, ensure your system meets the following requirements:

1.  **Operating System**:
    * A Linux-based distribution is recommended (e.g., Ubuntu, RedHat).
    * macOS or Windows with WSL 2 can also be used, but some scripts might require adjustments.

2.  **Docker and Docker Compose**:
    * **Docker Engine**: Install the latest stable version of Docker Engine. Refer to the [official Docker documentation](https://docs.docker.com/engine/install/) for installation instructions specific to your OS.

3.  **Git**:
    * Install Git for cloning the repository and managing versions. Most systems have Git pre-installed. If not, visit [https://git-scm.com/downloads](https://git-scm.com/downloads).

5.  **Sufficient System Resources**:
    * **RAM**: At least 8GB of RAM is recommended, especially if you plan to run multiple Wazuh components locally. 16GB or more is ideal.
    * **CPU**: A multi-core processor (2+ cores) is recommended.
    * **Disk Space**: Ensure you have sufficient disk space (at least 20-30GB) for Docker images, containers, and Wazuh data.

## Setting Up the Environment

Follow these steps to prepare your development environment:

1.  **Clone the Repository**:
    Clone the `wazuh-docker` repository from GitHub. It's important to check out the specific branch you intend to work with, in this case, `4.13.1`.

    ```bash
    git clone [https://github.com/wazuh/wazuh-docker.git](https://github.com/wazuh/wazuh-docker.git)
    cd wazuh-docker
    git checkout 4.13.1
    ```

2.  **Verify Docker Installation**:
    Ensure Docker is running and accessible by your user (you might need to add your user to the `docker` group or use `sudo`).

    ```bash
    docker --version
    docker info
    ```
    These commands should output the versions of Docker and information about your Docker setup without errors.

3.  **Review Project Structure**:
    Familiarize yourself with the directory structure of the cloned repository. Key directories often include:
    * `build-docker-images/wazuh-manager/`: Dockerfile and related files for the Wazuh manager.
    * `build-docker-images/wazuh-indexer/`: Dockerfile and related files for the Wazuh indexer.
    * `build-docker-images/wazuh-dashboard/`: Dockerfile and related files for the Wazuh dashboard.
    * `build-docker-images/wazuh-agent/` : Dockerfile and related files for Wazuh agents.
    * `single-node/` : Compose and configuration files for Wazuh deployment with 1 container of each Wazuh component.
    * `multi-node/` : Compose and configuration files for Wazuh deployment with 1 container of Wazuh dashboardm 2 containers of Wazuh manager (1 master and 1 worker) and 3 containers of Wazuh indexer.
    * `wazuh-agent/` : Compose and configuration files for Wazuh agent deployment.

