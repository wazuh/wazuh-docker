# Wazuh Docker Image Builder

The creation of the images for the Wazuh stack deployment in Docker is done with the `build-docker-images/build-images.sh` script

This script initializes the environment variables needed to build each of the images.

To execute it, make sure to be in the `build-docker-images` directory:

```bash
cd build-docker-images
```

Then execute:

```bash
./build-images.sh
```

The script downloads the package URLs for the requested version into `artifact_urls.yaml` on every run, overwriting any previous copy, and builds the four images in parallel. To build from your own package list instead, pass it with `-a <file>`. To build only one, use `-c`:

```bash
./build-images.sh -c wazuh-dashboard
```

To get all the available script options use the `-h` or `--help` option:

```bash
./build-images.sh -h

Usage: ./build-images.sh [OPTIONS]

    -a, --artifact-urls <file>   [Optional] Use this artifact URLs file instead of downloading the one for the requested version.
    -d, --dev-stage <ref>        [Optional] Set the pre-release stage suffix (e.g. beta1, rc2). Not used by default.
    --dev                        [Optional] Mark as a development build: appends the commit ref to the image tag. Controlled by inputs.dev in the workflow.
    -refs, --references <refs>   [Optional] [Only with --dev] JSON array of commit refs for components (indexer, manager, dashboard, agent) in order. Defaults to 'latest'.
    -rg, --registry <reg>        [Optional] Set the Docker registry to push the images.
    -c, --component <comp>       [Optional] Build only this component: 'wazuh-indexer', 'wazuh-manager', 'wazuh-dashboard' or 'wazuh-agent'. By default, all four.
    -v, --version <ver>          [Optional] Set the Wazuh version should be builded. By default, 5.0.0.
    -m, --multiarch              [Optional] Enable multi-architecture builds.
    --skip-signature-check       [Optional] [Only with --dev] Install the Wazuh packages without checking that they are signed by Wazuh. Only for unsigned development packages.
    -h, --help                   Show this help.
```

## Package signature check

Each Dockerfile downloads its Wazuh package from the URL in `artifact_urls.yaml`, and installs it only if it is signed with the Wazuh key (`build-docker-images/shared/verify-package-signature.sh`). The key is downloaded from `https://packages.wazuh.com/key/GPG-KEY-WAZUH`, and trusted only if it holds a single key with one of the fingerprints pinned in that script. A package that is unsigned, signed with another key, or modified fails the build. Package URLs must use `https://`.

Packages built from a commit for development are not signed. To build images from them, pass `--skip-signature-check` along with `--dev` (or set the `SKIP_PACKAGE_SIGNATURE_CHECK=true` build argument): the build prints a warning and installs the packages without checking them.

```bash
./build-images.sh --dev --skip-signature-check -c wazuh-agent
```

The `tini` binary of the manager and agent images is checked against the SHA-256 pinned in their Dockerfiles (`TINI_SHA256_AMD64` and `TINI_SHA256_ARM64`), which must be updated along with `TINI_VERSION`.
