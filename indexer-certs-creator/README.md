# Certificate Creation Image Build

The dockerfile hosted in this directory is used to build the image required for generating Wazuh Docker single-node and multi-node certificate files

## Pre-requisites

### QEMU

Set up QEMU to enable building multi-architecture Docker images

Useful documentation:

- https://www.qemu.org/download/
- https://docs.docker.com/build/building/multi-platform/#qemu

## Procedure

Run the following script to build the wazuh-certs-generator docker image

```console
./build-image.sh -v <IMAGE_TAG> [-m] [-rg <REGISTRY>]
```

Replace <IMAGE_TAG> with the new image desired tag.
Use the `-m` flag to build a multi-architecture image (supports both `amd64` and `arm64`)
Use the `-rg <REGISTRY>` parameter to specify a custom Docker registry (default is Docker Hub)
  By default, the script will attempt to push the image to the registry and will only work if credentials are properly configured.
