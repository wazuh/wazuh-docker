#!/bin/bash

# Wazuh package generator
# Copyright (C) 2023, Wazuh Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

WAZUH_CERTS_IMAGE_VERSION="0.0.4"
WAZUH_REGISTRY="docker.io"

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
    IMAGE_TAG="${WAZUH_CERTS_IMAGE_VERSION}"

    echo WAZUH_REGISTRY=$WAZUH_REGISTRY > .env
    echo IMAGE_TAG=$IMAGE_TAG >> .env

    set -a
    source .env
    set +a

    if [ "${MULTIARCH}" ]; then
        docker buildx bake --file build-image.yml \
            --set *.platform=linux/amd64,linux/arm64 \
            --no-cache || clean 1
    else
        docker buildx bake --file build-image.yml --no-cache || clean 1
    fi
    return 0
}

# -----------------------------------------------------------------------------

help() {
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "    -v, --version <ver>      [Optional] Set the image version. By default ${WAZUH_CERTS_IMAGE_VERSION}."
    echo "    -rg, --registry <reg>    [Optional] Set the Docker registry to push the images."
    echo "    -m, --multiarch          [Optional] Enable multi-architecture builds."
    echo "    -h, --help               Show this help."
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
        "-m"|"--multiarch")
            MULTIARCH="true"
            shift
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
                WAZUH_CERTS_IMAGE_VERSION="$2"
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