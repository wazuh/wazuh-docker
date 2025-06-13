# Reference Manual - Introduction

Welcome to the Reference Manual for Wazuh-Docker, version 4.13.1. This manual provides comprehensive information about deploying, configuring, and managing your Wazuh environment using Docker.

## Purpose of This Manual

This Reference Manual is designed to be your go-to resource for understanding the intricacies of Wazuh-Docker. It aims to cover:

-   The core concepts and architecture of Wazuh when deployed with Docker.
-   Step-by-step guidance for getting started, from requirements to various deployment scenarios.
-   Detailed explanations of configuration options, including environment variables and persistent data management.
-   Procedures for common operational tasks like upgrading your deployment.
-   A glossary of terms to help you understand Wazuh and Docker-specific terminology.

## Who Should Use This Manual?

This manual is intended for:

-   **System Administrators** responsible for deploying and maintaining Wazuh.
-   **Security Analysts** who use Wazuh and need to understand its Dockerized deployment.
-   **DevOps Engineers** integrating Wazuh into their CI/CD pipelines or containerized infrastructure.
-   Anyone seeking detailed technical information about Wazuh-Docker.

## How This Manual is Organized

This manual is structured to help you find information efficiently:

-   **[Description](description.md)**: Provides a detailed overview of Wazuh-Docker, its components, and how they work together in a containerized setup.
-   **[Getting Started](getting-started/getting-started.md)**: Guides you through the initial setup, from prerequisites to deploying your first Wazuh stack.
    -   **[Requirements](getting-started/requirements.md)**: Lists the necessary hardware and software.
    -   **[Deployment](getting-started/deployment/README.md)**: Offers instructions for different deployment models:
        -   [Single Node Wazuh Stack](getting-started/deployment/single-node.md)
        -   [Multi Node Wazuh Stack](getting-started/deployment/multi-node.md)
        -   [Wazuh Agent](getting-started/deployment/wazuh-agent.md)
-   **[Configuration](configuration/configuration.md)**: Explains how to customize your Wazuh-Docker deployment.
    -   [Environment Variables](configuration/environment-variables.md)
    -   [Configuration Files](configuration/configuration-files.md)
-   **[Upgrade](upgrade.md)**: Provides instructions for upgrading your Wazuh-Docker deployment to a newer version.
-   **[Glossary](glossary.md)**: Defines key terms and concepts.

## Using This Manual

-   If you are new to Wazuh-docker, we recommend starting with the [Description](description.md) and then proceeding to the [Getting Started](getting-started/getting-started.md) section.
-   If you need to customize your deployment, refer to the [Configuration](configuration/configuration.md) section.
-   For specific terms or concepts, consult the [Glossary](glossary.md).

This manual refers to version 4.13.1 of Wazuh-Docker. Ensure you are using the documentation that corresponds to your deployed version.
