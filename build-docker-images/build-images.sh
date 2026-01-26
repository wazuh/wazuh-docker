#!/bin/bash

# Wazuh package generator
# Copyright (C) 2023, Wazuh Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

WAZUH_IMAGE_VERSION=5.0.0
IMAGE_TAG=5.0.0
WAZUH_VERSION=$(echo $WAZUH_IMAGE_VERSION | sed -e 's/\.//g')
WAZUH_TAG_REVISION=1
WAZUH_CURRENT_VERSION=$(curl --silent https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '["]tag_name["]:' | sed -E 's/.*\"([^\"]+)\".*/\1/' | cut -c 2- | sed -e 's/\.//g')
IMAGE_VERSION=${WAZUH_IMAGE_VERSION}
WAZUH_REGISTRY=docker.io

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

    awk -F':' '!/^#/ && NF>1 {name=$1; val=substr($0,length(name)+3); gsub(/[-.]/,"_",name); print name "=" val}' $ARTIFACT_URLS_FILE > artifacts_env.txt

    if  [ "${WAZUH_DEV_STAGE}" ];then
        if  [ "${WAZUH_TAG_REFERENCE}" ];then
            IMAGE_TAG="${WAZUH_IMAGE_VERSION}-${WAZUH_DEV_STAGE,,}-${WAZUH_TAG_REFERENCE}"
        else
            IMAGE_TAG="${WAZUH_IMAGE_VERSION}-${WAZUH_DEV_STAGE,,}"
        fi
    else
        if  [ "${WAZUH_TAG_REFERENCE}" ];then
            IMAGE_TAG="${WAZUH_IMAGE_VERSION}-${WAZUH_TAG_REFERENCE}"
        else
            IMAGE_TAG="${WAZUH_IMAGE_VERSION}"
        fi
    fi

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

    # Define all available components
    local all_components=("wazuh-indexer" "wazuh-manager" "wazuh-dashboard" "wazuh-agent")
    local components_to_build=()

    # Determine which components to build
    if [ -z "${WAZUH_COMPONENT}" ]; then
        echo "No component specified. Building all components..."
        components_to_build=("${all_components[@]}")
    else
        # Validate component
        case "${WAZUH_COMPONENT}" in
            wazuh-indexer|wazuh-manager|wazuh-dashboard|wazuh-agent)
                components_to_build=("${WAZUH_COMPONENT}")
                ;;
            *)
                echo "Error: Unknown component '${WAZUH_COMPONENT}'" >&2
                clean 1
                ;;
        esac
    fi

    # Determine build command and base options
    if [ "${MULTIARCH}" ]; then
        build_cmd="docker buildx build --platform linux/amd64,linux/arm64 --push --no-cache"
    else
        build_cmd="docker build --no-cache"
    fi

    # Build each component
    for component in "${components_to_build[@]}"; do
        echo "Building ${component} image..."

        # Build common args (used by all components)
        build_args=(
            -t "${WAZUH_REGISTRY}/wazuh/${component}:${IMAGE_TAG}"
            --build-arg WAZUH_VERSION="${WAZUH_IMAGE_VERSION}"
            --build-arg WAZUH_TAG_REVISION="${WAZUH_TAG_REVISION}"
        )

        # Add component-specific args
        case "${component}" in
            wazuh-indexer)
                build_args+=(
                    --build-arg wazuh_indexer_amd64_rpm="${wazuh_indexer_amd64_rpm}"
                    --build-arg wazuh_indexer_arm64_rpm="${wazuh_indexer_arm64_rpm}"
                    --build-arg wazuh_certs_tool="${wazuh_certs_tool}"
                    --build-arg wazuh_config_yml="${wazuh_config_yml}"
                )
                ;;
            wazuh-manager)
                build_args+=(
                    --build-arg wazuh_manager_amd64_rpm="${wazuh_manager_amd64_rpm}"
                    --build-arg wazuh_manager_arm64_rpm="${wazuh_manager_arm64_rpm}"
                )
                ;;
            wazuh-dashboard)
                build_args+=(
                    --build-arg WAZUH_UI_REVISION="${WAZUH_UI_REVISION}"
                    --build-arg wazuh_dashboard_amd64_rpm="${wazuh_dashboard_amd64_rpm}"
                    --build-arg wazuh_dashboard_arm64_rpm="${wazuh_dashboard_arm64_rpm}"
                    --build-arg wazuh_certs_tool="${wazuh_certs_tool}"
                    --build-arg wazuh_config_yml="${wazuh_config_yml}"
                )
                ;;
            wazuh-agent)
                build_args+=(
                    --build-arg wazuh_agent_amd64_rpm="${wazuh_agent_amd64_rpm}"
                    --build-arg wazuh_agent_arm64_rpm="${wazuh_agent_arm64_rpm}"
                )
                ;;
        esac

        # Execute build
        $build_cmd "${build_args[@]}" ${component}/ || clean 1
        echo "${component} image built successfully!"
    done

    echo ""
    echo "Image build process completed!"

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
    echo "    -c, --component <comp>       [Required] Set the Wazuh component to build. Accepted values: 'wazuh-indexer', 'wazuh-manager', 'wazuh-dashboard', 'wazuh-agent'."
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
        "-c"|"--component")
            if [ -n "${2}" ]; then
                WAZUH_COMPONENT="${2}"
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
