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

## Runtime variables

The image downloads `wazuh-certs-tool.sh` when it runs. These variables control where it comes from:

- `CERT_TOOL_VERSION` (required): version folder of the tool, for example `4.14`.
- `CERT_TOOL_REPOSITORY` (optional, default `prod`): repository tried first.
  - `prod`: tries `https://packages.wazuh.com/$CERT_TOOL_VERSION/` and, if it fails, `https://packages-dev.wazuh.com/$CERT_TOOL_VERSION/`.
  - `dev`: the same two repositories in the opposite order. Use it to deploy a release candidate with the certificates tool published for it in `packages-dev`.
  - Any other value stops the image with an error.

Example, using the tool of the development repository:

```console
docker run --rm -e CERT_TOOL_VERSION=4.14 -e CERT_TOOL_REPOSITORY=dev \
  -v $PWD/config/certs.yml:/config/certs.yml \
  -v $PWD/config/wazuh_indexer_ssl_certs/:/certificates/ \
  wazuh/wazuh-certs-generator:<IMAGE_TAG>
```
