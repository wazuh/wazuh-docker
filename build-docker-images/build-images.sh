WAZUH_IMAGE_VERSION=5.0.0
IMAGE_TAG=5.0.0
WAZUH_VERSION=$(echo $WAZUH_IMAGE_VERSION | sed -e 's/\.//g')
WAZUH_TAG_REVISION=1
WAZUH_CURRENT_VERSION=$(curl --silent https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '["]tag_name["]:' | sed -E 's/.*\"([^\"]+)\".*/\1/' | cut -c 2- | sed -e 's/\.//g')
IMAGE_VERSION=${WAZUH_IMAGE_VERSION}
WAZUH_REGISTRY=docker.io

# Wazuh package generator
# Copyright (C) 2023, Wazuh Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

WAZUH_IMAGE_VERSION="5.0.0"
WAZUH_TAG_REVISION="1"
WAZUH_DEV_STAGE=""
WAZUH_TAG_REFERENCE=""

# -----------------------------------------------------------------------------

trap ctrl_c INT

clean() {
    exit_code=$1

    exit ${exit_code}
}

ctrl_c() {
    clean 1
}

# -----------------------------------------------------------------------------


build() {

    WAZUH_VERSION="$(echo $WAZUH_IMAGE_VERSION | sed -e 's/\.//g')"
    WAZUH_MINOR_VERSION="${WAZUH_IMAGE_VERSION%.*}"
    WAZUH_UI_REVISION="${WAZUH_TAG_REVISION}"

    # Variables
    ARTIFACT_URLS_FILE="artifact_urls.yml"

    if [[ -f "$ARTIFACT_URLS_FILE" ]]; then
        echo "$ARTIFACT_URLS_FILE exists. Using existing file."
    else
        TAG="v${WAZUH_VERSION}"
        REPO="wazuh/wazuh-docker"
        GH_URL="https://api.github.com/repos/${REPO}/git/refs/tags/${TAG}"

        if curl -fsSL "$GH_URL" >/dev/null 2>&1; then
            curl -fsSL -o "$ARTIFACT_URLS_FILE" "https://packages.wazuh.com/${WAZUH_MINOR_VERSION}/${ARTIFACT_URLS_FILE}"
        else
            curl -fsSL -o "$ARTIFACT_URLS_FILE" "https://packages-dev.wazuh.com/${WAZUH_MINOR_VERSION}/${ARTIFACT_URLS_FILE}"
        fi
    fi
    awk -F':' '{name=$1; val=substr($0,length(name)+3); gsub(/[-.]/,"_",name); print name "=" val}' $ARTIFACT_URLS_FILE > artifacts_env.txt
    
    echo WAZUH_VERSION=$WAZUH_IMAGE_VERSION > ../.env
    echo WAZUH_IMAGE_VERSION=$WAZUH_IMAGE_VERSION >> ../.env
    echo WAZUH_TAG_REVISION=$WAZUH_TAG_REVISION >> ../.env
    echo WAZUH_UI_REVISION=$WAZUH_UI_REVISION >> ../.env
    echo WAZUH_REGISTRY=$WAZUH_REGISTRY >> ../.env
    echo IMAGE_TAG=$IMAGE_TAG >> ../.env

    set -a
    source ../.env
    source ./artifacts_env.txt
    set +a

    if  [ "${MULTIARCH}" ];then
        docker buildx bake --file build-images.yml --push --set *.platform=linux/amd64,linux/arm64 --no-cache|| clean 1
    else
        docker buildx bake --file build-images.yml --no-cache|| clean 1
    fi
    return 0
}

# -----------------------------------------------------------------------------

help() {
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "    -d, --dev <ref>              [Optional] Set the development stage you want to build, example rc2 or beta1, not used by default."
    echo "    -r, --revision <rev>         [Optional] Package revision. By default ${WAZUH_TAG_REVISION}"
    echo "    -ref, --reference <ref>      [Optional] Set the Wazuh reference to build development images. By default, the latest stable release."
    echo "    -rg, --registry <reg>        [Optional] Set the Docker registry to push the images."
    echo "    -v, --version <ver>          [Optional] Set the Wazuh version should be builded. By default, ${WAZUH_IMAGE_VERSION}."
    echo "    -m, --multiarch              [Optional] Enable multi-architecture builds."
    echo "    -h, --help                   Show this help."
    echo
    exit $1
}

# -----------------------------------------------------------------------------

main() {
    while [ -n "${1}" ]
    do
        case "${1}" in
        "-h"|"--help")
            help 0
            ;;
        "-d"|"--dev")
            if [ -n "${2}" ]; then
                WAZUH_DEV_STAGE="${2}"
                shift 2
            else
                help 1
            fi
            ;;
        "-m"|"--multiarch")
            MULTIARCH="true"
                shift
            ;;
        "-r"|"--revision")
            if [ -n "${2}" ]; then
                WAZUH_TAG_REVISION="${2}"
                shift 2
            else
                help 1
            fi
            ;;
        "-ref"|"--reference")
            if [ -n "${2}" ]; then
                WAZUH_TAG_REFERENCE="${2}"
                shift 2
            else
                help 1
            fi
            ;;
        "-rg"|"--registry")
            if [ -n "${2}" ]; then
                WAZUH_REGISTRY="${2}"
                shift 2
            else
                help 1
            fi
            ;;
        "-v"|"--version")
            if [ -n "$2" ]; then
                WAZUH_IMAGE_VERSION="$2"
                shift 2
            else
                help 1
            fi
            ;;
        *)
            help 1
        esac
    done

    build || clean 1

    clean 0
}

main "$@"
