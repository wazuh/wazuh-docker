# Upgrading Wazuh in Docker

To upgrade your Wazuh deployment when using Docker, the process primarily involves updating the image tags in your `docker-compose.yml` file to the desired version.

Below is a step-by-step example of how to perform this update:

1. **Stop the current deployment**:
   Stop and remove the existing containers.
   ```bash
   docker-compose down
   ```

2. **Update the image tags**:
   Edit your `docker-compose.yml` file and update the `image` field for all Wazuh services to the desired version.

   ### Single-node configuration
   Update the image tag for the following services in `single-node/docker-compose.yml`:
   - `wazuh.manager`
   - `wazuh.indexer`
   - `wazuh.dashboard`

   Example (update to 5.0.0):

   ```yaml
   services:
     wazuh.manager:
       image: wazuh/wazuh-manager:5.0.0
       ...

     wazuh.indexer:
       image: wazuh/wazuh-indexer:5.0.0
       ...

     wazuh.dashboard:
       image: wazuh/wazuh-dashboard:5.0.0
       ...
   ```

   ### Multi-node configuration
   Update the image tag for the following services in `multi-node/docker-compose.yml`:
   - `wazuh.master`
   - `wazuh.worker`
   - `wazuh1.indexer`, `wazuh2.indexer`, and `wazuh3.indexer`
   - `wazuh.dashboard`

   Example (update to 5.0.0):

   ```yaml
   services:
     wazuh.master:
       image: wazuh/wazuh-manager:5.0.0
       ...

     wazuh.worker:
       image: wazuh/wazuh-manager:5.0.0
       ...

     wazuh1.indexer:
       image: wazuh/wazuh-indexer:5.0.0
       ...

     wazuh2.indexer:
       image: wazuh/wazuh-indexer:5.0.0
       ...

     wazuh3.indexer:
       image: wazuh/wazuh-indexer:5.0.0
       ...

     wazuh.dashboard:
       image: wazuh/wazuh-dashboard:5.0.0
       ...
   ```

3. **Start the updated deployment**:
   Start the containers again. Docker will automatically pull the new images.
   ```bash
   docker-compose up -d
   ```
