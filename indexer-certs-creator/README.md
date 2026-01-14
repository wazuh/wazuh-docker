# Certificate Creation Image Build

The dockerfile hosted in this directory is used to build the image required for generating Wazuh Docker single-node and multi-node certificate files

## Pre-requisites

1. Verify the Docker Buildx plugin is properly set up
2. For multi-architecture image builds:
    - Ensure QEMU is installed
    - Check permissions to push images to a Docker registry

Useful documentation:

- https://docs.docker.com/build/building/multi-platform/
- https://www.qemu.org/download/

## Procedure

Execute the following to run the script used to build the wazuh-certs-generator docker image

```console
cd indexer-certs-creator
```

```console
./build-image.sh -v <IMAGE_TAG> [-m] [-rg <REGISTRY>]
```

- Replace <IMAGE_TAG> with the new image desired tag.
- Use the `-m` flag to build a multi-architecture image (supports both `amd64` and `arm64`)
  - If multiarch build is enabled, the script will attempt to push the image to the specified registry. This image upload will only work if credentials are properly configured.
- Use the `-rg <REGISTRY>` parameter to specify a custom Docker registry (default is Docker Hub)
