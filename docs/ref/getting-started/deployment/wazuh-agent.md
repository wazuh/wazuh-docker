# Wazuh Docker Deployment

## Deploying the Wazuh Agent

Follow these steps to deploy the Wazuh agent using Docker.

1.  Navigate to the `wazuh-agent` directory within your repository:
    ```bash
    cd wazuh-agent
    ```

2.  Edit the `docker-compose.yml` file. You need to update the `WAZUH_MANAGER_SERVER` environment variable with the IP address or hostname of your Wazuh manager.

    Locate the `environment` section for the agent service and update it as follows:
    ```yaml
    # Inside your docker-compose.yml file
    # services:
    #   wazuh-agent:
    #     ...
    environment:
      - WAZUH_MANAGER_SERVER=<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>
    #     ...
    ```
    **Note:** Replace `<YOUR_WAZUH_MANAGER_IP_OR_HOSTNAME>` with the actual IP address or hostname of your Wazuh manager.

3.  Start the environment using `docker compose`:

    * To run in the foreground (logs will be displayed in your current terminal, and you can stop it with `Ctrl+C`):
        ```bash
        docker compose up
        ```

    * To run in the background (detached mode, allowing the container to run independently of your terminal):
        ```bash
        docker compose up -d
        ```