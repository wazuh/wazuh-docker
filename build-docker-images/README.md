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

The script also allows to build images from other versions of Wazuh by using the `-v` or `--version` argument:

```bash
./build-images.sh -v 4.14.3
```

To get all the available script options use the -h or --help option:

```bash
./build-images.sh -h

Usage: ./build-images.sh [OPTIONS]

    -d, --dev <ref>              [Optional] Set the development stage you want to build, example rc1 or beta1, not used by default.
    -f, --filebeat-module <ref>  [Optional] Set Filebeat module version. By default 0.5.
    -r, --revision <rev>         [Optional] Package revision. By default 1
    -rg, --registry <reg>        [Optional] Set the Docker registry to push the images.
    -v, --version <ver>          [Optional] Set the Wazuh version should be builded. By default, 4.14.3.
    -m, --multiarch              [Optional] Enable multi-architecture builds.
    -h, --help                   Show this help.

```