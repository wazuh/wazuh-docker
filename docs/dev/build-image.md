# Wazuh Docker Image Builder

The creation of the images for the Wazuh stack deployment in Docker is done with the `build-docker-images/build-images.sh` script

This script initializes the environment variables needed to build each of the images.

To execute it, make sure to be in the `build-docker-images` directory:

<<<<<<< HEAD
```bash
cd build-docker-images
=======
```
$ build-docker-images/build-images.sh -v 4.14.10
>>>>>>> origin/4.14.10
```

Then execute:

```bash
./build-images.sh
```

The script reads the package URLs from `artifact_urls.yaml` in the same directory, and builds the four images in parallel. To build only one, use `-c`:

<<<<<<< HEAD
```bash
./build-images.sh -c wazuh-dashboard
```

To get all the available script options use the `-h` or `--help` option:

```bash
./build-images.sh -h

Usage: ./build-images.sh [OPTIONS]

    -d, --dev-stage <ref>        [Optional] Set the pre-release stage suffix (e.g. beta1, rc2). Not used by default.
    --dev                        [Optional] Mark as a development build: appends the commit ref to the image tag. Controlled by inputs.dev in the workflow.
    -refs, --references <refs>   [Optional] [Only with --dev] JSON array of commit refs for components (indexer, manager, dashboard, agent) in order. Defaults to 'latest'.
    -rg, --registry <reg>        [Optional] Set the Docker registry to push the images.
    -c, --component <comp>       [Optional] Build only this component: 'wazuh-indexer', 'wazuh-manager', 'wazuh-dashboard' or 'wazuh-agent'. By default, all four.
    -v, --version <ver>          [Optional] Set the Wazuh version should be builded. By default, 5.0.0.
    -m, --multiarch              [Optional] Enable multi-architecture builds.
=======
    -d, --dev <ref>              [Optional] Set the development stage you want to build, example rc4 or beta1, not used by default.
    -f, --filebeat-module <ref>  [Optional] Set Filebeat module version. By default 0.5.
    -r, --revision <rev>         [Optional] Package revision. By default 1
    -v, --version <ver>          [Optional] Set the Wazuh version should be builded. By default, 4.14.10.
>>>>>>> origin/4.14.10
    -h, --help                   Show this help.
```
