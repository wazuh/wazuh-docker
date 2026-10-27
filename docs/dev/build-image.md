# Wazuh Docker Image Builder

The creation of the images for the Wazuh stack deployment in Docker is done with the build-images.yml script

To execute the process, the following must be executed in the root of the wazuh-docker repository:

```
$ build-docker-images/build-images.sh
```

This script initializes the environment variables needed to build each of the images.

The script allows you to build images from other versions of Wazuh, to do this you must use the -v or --version argument:

```
$ build-docker-images/build-images.sh -v 4.14.10
```

To get all the available script options use the -h or --help option:

```
$ build-docker-images/build-images.sh -h

Usage: build-docker-images/build-images.sh [OPTIONS]

    -d, --dev <ref>              [Optional] Set the development stage you want to build, example rc4 or beta1, not used by default.
    --release                    [Optional] Final release build: install the packages from the production repository without checking the wazuh/wazuh tag. Not valid with -d.
    -f, --filebeat-module <ref>  [Optional] Set Filebeat module version. By default 0.5.
    -r, --revision <rev>         [Optional] Package revision. By default 1
    -v, --version <ver>          [Optional] Set the Wazuh version should be builded. By default, 4.14.10.
    -h, --help                   Show this help.

```

## Package repository

Each Dockerfile runs `config/check_repository.sh` to choose the yum repository of the Wazuh packages:

- With `--release`, it uses the production repository (`https://packages.wazuh.com/4.x/yum/`). The `4_build_and_push_images.yml` workflow passes `--release` when `dev` is `false` and `image_tag` has no stage suffix.
- With `-d`, it uses the pre-release repository (`https://packages-dev.wazuh.com/pre-release/yum/`).
- Otherwise, it uses the production repository if the `v<version>` tag exists in `wazuh/wazuh`, and the pre-release repository if it does not. If GitHub cannot be queried (for example, the API rate limit is reached), the build fails.
