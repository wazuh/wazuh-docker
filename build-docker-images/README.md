# Wazuh Docker Image Builder

The creation of the images for the Wazuh stack deployment in Docker is done with the build-images.yml script

To execute the process, the following must be executed in the root of the wazuh-docker repository:

```
$ build-docker-images/build-images.sh
```

This script initializes the environment variables needed to build each of the images.
