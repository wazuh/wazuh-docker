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
WAZUH_CURRENT_VERSION=$(curl --silent https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '["]tag_name["]:' | sed -E 's/.*\"([^\"]+)\".*/\1/' | cut -c 2- | sed -e 's/\.//g')
IMAGE_VERSION=${WAZUH_IMAGE_VERSION}
WAZUH_REGISTRY=docker.io

WAZUH_IMAGE_VERSION="5.0.0"
WAZUH_DEV_STAGE=""
WAZUH_COMPONENTS_COMMIT_LIST=''

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

    # WAZUH_MINOR_VERSION: Extracts major and minor version only (e.g., 5.0.0 -> 5.0)
    WAZUH_MINOR_VERSION="${WAZUH_IMAGE_VERSION%.*}"
    # WAZUH_MAJOR_VERSION: Extracts major version only (e.g., 5.0.0 -> 5)
    WAZUH_MAJOR_VERSION="${WAZUH_IMAGE_VERSION%%.*}"
    # WAZUH_STAGE: Extract the 'stage' (e.g., alpha0, beta1, rc2) from the local JSON metadata file.
    # Note: This is primarily used for pre-release package naming.
    WAZUH_STAGE=$(jq -r '.stage' ../VERSION.json)
    # ARTIFACT_URLS_FILE: The name of the artifact URLs file.
    ARTIFACT_URLS_FILE="artifact_urls.yaml"

    # Check if the artifact file already exists to prevent redundant downloads
    if [[ -f "$ARTIFACT_URLS_FILE" ]]; then
        echo "$ARTIFACT_URLS_FILE exists. Using existing file."
    else
        # Prepare logic to fetch the artifact from Wazuh's infrastructure
        TAG="v${WAZUH_IMAGE_VERSION}"
        REPO="wazuh/wazuh-docker"
        GH_URL="https://api.github.com/repos/${REPO}/git/refs/tags/${TAG}"

        # Use GitHub API to check if the tag exists publicly.
        # This determines if we should look for production or staging artifacts.
        if curl -fsSL "$GH_URL" >/dev/null 2>&1; then
            # CASE: Production (Tag exists in the official repository)
            ARTIFACT_URLS_DOWNLOAD=artifact_urls_${WAZUH_IMAGE_VERSION}.yaml
            PACKAGE_URL=packages.wazuh.com
            RELEASE_STAGE=production
        else
            # CASE: Pre-release/Staging (Tag not found, fall back to staging environment)
            # Includes the WAZUH_STAGE suffix (e.g., artifact_urls_5.0.0-alpha0.yaml)
            ARTIFACT_URLS_DOWNLOAD=artifact_urls_${WAZUH_IMAGE_VERSION}-${WAZUH_STAGE}.yaml
            PACKAGE_URL=packages-staging.xdrsiem.wazuh.info
            RELEASE_STAGE=pre-release
        fi
        # Final download using dynamic variables based on the release type.
        # Pattern: server / stage / major_version.x / filename
        curl -fsSL -o "$ARTIFACT_URLS_FILE" "https://${PACKAGE_URL}/${RELEASE_STAGE}/${WAZUH_MAJOR_VERSION}.x/${ARTIFACT_URLS_DOWNLOAD}"
    fi

    awk -F':' '!/^#/ && NF>1 {name=$1; val=substr($0,length(name)+3); gsub(/[-.]/,"_",name); print name "=\"" val "\""}' $ARTIFACT_URLS_FILE > artifacts_env.txt

    # Set component commit references for development builds
    if [ -n "${WAZUH_DEV_STAGE}" ]; then
        if [ -z "${WAZUH_COMPONENTS_COMMIT_LIST}" ]; then
            # Set default to 'latest' for all components if no specific references are provided
            INDEXER_COMMIT="latest"
            MANAGER_COMMIT="latest"
            DASHBOARD_COMMIT="latest"
            AGENT_COMMIT="latest"
        else
            if ! printf '%s' "${WAZUH_COMPONENTS_COMMIT_LIST}" \
                | jq -e 'type=="array" and (all(.[]; type=="string"))' >/dev/null 2>&1; then
                echo 'Error: --references must be a JSON array of strings, e.g. ["ref1","ref2","ref3","ref4"]' >&2
                clean 1
            fi

            refs_count="$(printf '%s' "${WAZUH_COMPONENTS_COMMIT_LIST}" | jq -r 'length')"
            if [ -z "${WAZUH_COMPONENT}" ]; then
                # No specific component to be build: require exactly 4 items
                if [ "${refs_count}" -ne 4 ]; then
                    echo "Error: --references must contain exactly 4 items when no --component is specified." >&2
                    clean 1
                fi

                # Set all component commits

                INDEXER_COMMIT="$(printf '%s' "${WAZUH_COMPONENTS_COMMIT_LIST}" | jq -r '.[0]')"
                MANAGER_COMMIT="$(printf '%s' "${WAZUH_COMPONENTS_COMMIT_LIST}" | jq -r '.[1]')"
                DASHBOARD_COMMIT="$(printf '%s' "${WAZUH_COMPONENTS_COMMIT_LIST}" | jq -r '.[2]')"
                AGENT_COMMIT="$(printf '%s' "${WAZUH_COMPONENTS_COMMIT_LIST}" | jq -r '.[3]')"
            else
                # Specific component to be build: allow 1 (component-only)
                if [ "${refs_count}" -ne 1 ]; then
                    echo "Error: --references must contain exactly 1 item when --component is specified." >&2
                    clean 1
                fi

                # Set specific component commit
                case "${WAZUH_COMPONENT}" in
                    wazuh-indexer)
                        INDEXER_COMMIT="$(printf '%s' "${WAZUH_COMPONENTS_COMMIT_LIST}" | jq -r '.[0]')"
                        ;;
                    wazuh-manager)
                        MANAGER_COMMIT="$(printf '%s' "${WAZUH_COMPONENTS_COMMIT_LIST}" | jq -r '.[0]')"
                        ;;
                    wazuh-dashboard)
                        DASHBOARD_COMMIT="$(printf '%s' "${WAZUH_COMPONENTS_COMMIT_LIST}" | jq -r '.[0]')"
                        ;;
                    wazuh-agent)
                        AGENT_COMMIT="$(printf '%s' "${WAZUH_COMPONENTS_COMMIT_LIST}" | jq -r '.[0]')"
                        ;;
                    *)
                        echo "Error: Unknown component '${WAZUH_COMPONENT}'" >&2
                        clean 1
                        ;;
                esac
            fi
        fi
    fi


    # Function to get component-specific commit reference
    get_component_commit() {
        local component=$1
        case "${component}" in
            wazuh-indexer)
                echo "${INDEXER_COMMIT}"
                ;;
            wazuh-manager)
                echo "${MANAGER_COMMIT}"
                ;;
            wazuh-dashboard)
                echo "${DASHBOARD_COMMIT}"
                ;;
            wazuh-agent)
                echo "${AGENT_COMMIT}"
                ;;
            *)
                echo ""
                ;;
        esac
    }

    # Global env file (without IMAGE_TAG - will be component-specific)
    echo WAZUH_VERSION=$WAZUH_IMAGE_VERSION > ../.env
    echo WAZUH_IMAGE_VERSION=$WAZUH_IMAGE_VERSION >> ../.env
    echo WAZUH_REGISTRY=$WAZUH_REGISTRY >> ../.env

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

        # Get component-specific commit reference
        COMPONENT_COMMIT=$(get_component_commit "${component}")

        # Generate component-specific IMAGE_TAG
        IMAGE_TAG="${WAZUH_IMAGE_VERSION}${WAZUH_DEV_STAGE:+-${WAZUH_DEV_STAGE,,}-${COMPONENT_COMMIT}}"
        echo "Using IMAGE_TAG: ${IMAGE_TAG} for ${component}"
        export IMAGE_TAG="$IMAGE_TAG"

        # Build common args (used by all components)
        build_args=(
            -t "${WAZUH_REGISTRY}/wazuh/${component}:${IMAGE_TAG}"
            --build-arg WAZUH_VERSION="${WAZUH_IMAGE_VERSION}"
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
    echo "    -refs, --references <refs>   [Optional] [Only for Dev] JSON array of commit refs for components to be build (indexer, manager, dashboard, agent) in order. Defaults to latest."
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
        "-refs"|"--references")
            if [ -n "${2}" ]; then
                # Replace single quotes with double quotes to ensure it's valid JSON for jq processing
                WAZUH_COMPONENTS_COMMIT_LIST="$(printf '%s' "${2}" | sed "s/'/\"/g")"
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
