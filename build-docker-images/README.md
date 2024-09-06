# Wazuh Docker Image Builder

The creation of the images for the Wazuh stack deployment in Docker is done with the build-images.yml script

To execute the process, the following must be executed in the root of the wazuh-docker repository:

```
$ build-docker-images/build-images.sh
```

This script initializes the environment variables needed to build each of the images.

The script allows you to build images from other versions of Wazuh, to do this you must use the -v or --version argument:

```
$ build-docker-images/build-images.sh -v 4.9.2
```

To get all the available script options use the -h or --help option:

```
$ build-docker-images/build-images.sh -h

Usage: build-docker-images/build-images.sh [OPTIONS]

    -d, --dev <ref>              [Optional] Set the development stage you want to build, example rc1 or beta1, not used by default.
    -f, --filebeat-module <ref>  [Optional] Set Filebeat module version. By default 0.4.
    -r, --revision <rev>         [Optional] Package revision. By default 1
    -v, --version <ver>          [Optional] Set the Wazuh version should be builded. By default, 4.9.2.
    -h, --help                   Show this help.

```