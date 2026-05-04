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
IS_DEV_BUILD=""

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
    # ARTIFACT_URLS_DIR: The name of the artifact URLs directory.
    ARTIFACT_URLS_DIR="artifact_urls"

    # Check if the artifact file already exists to prevent redundant downloads
    if [[ -f "$ARTIFACT_URLS_FILE" ]]; then
        echo "$ARTIFACT_URLS_FILE exists. Using existing file."
    else
        # GitHub URL for exact Release Tag lookup
        TAG="v${WAZUH_IMAGE_VERSION}"
        REPO="wazuh/wazuh-docker"
        GH_URL="https://api.github.com/repos/${REPO}/releases/tags/${TAG}"

        # Fetch the HTTP status code to determine release environment.
        # Using -L to follow redirects (GitHub may return 301/302 for some endpoints).
        HTTP_STATUS=$(curl -sL -o /dev/null -w "%{http_code}" "$GH_URL")

        if [ "$HTTP_STATUS" -eq 200 ]; then
            # CASE: Production (Tag and Release exist)
            echo "Release $TAG found. Setting Production environment."
            ARTIFACT_URLS_DOWNLOAD="artifact_urls_${WAZUH_IMAGE_VERSION}.yaml"
            PACKAGE_URL="packages.wazuh.com"
            RELEASE_STAGE="production"
        elif [ "$HTTP_STATUS" -eq 403 ]; then
            # CASE: GitHub API rate limit hit — fall back to pre-release to avoid
            # incorrectly skipping staging artifacts.
            echo "Warning: GitHub API rate limit reached (403). Assuming pre-release environment." >&2
            PACKAGE_URL="packages-staging.xdrsiem.wazuh.info"
            RELEASE_STAGE="pre-release"
            if [ -n "$WAZUH_STAGE" ] && [ "$WAZUH_STAGE" != "null" ]; then
                ARTIFACT_URLS_DOWNLOAD="artifact_urls_${WAZUH_IMAGE_VERSION}-${WAZUH_STAGE}.yaml"
            else
                ARTIFACT_URLS_DOWNLOAD="artifact_urls_${WAZUH_IMAGE_VERSION}.yaml"
            fi
        else
            # CASE: Pre-release/Staging (404 Not Found or any other non-200 status)
            echo "Release $TAG not found (HTTP status: $HTTP_STATUS). Setting Pre-release environment."
            PACKAGE_URL="packages-staging.xdrsiem.wazuh.info"
            RELEASE_STAGE="pre-release"
            if [ -n "$WAZUH_STAGE" ] && [ "$WAZUH_STAGE" != "null" ]; then
                ARTIFACT_URLS_DOWNLOAD="artifact_urls_${WAZUH_IMAGE_VERSION}-${WAZUH_STAGE}.yaml"
            else
                ARTIFACT_URLS_DOWNLOAD="artifact_urls_${WAZUH_IMAGE_VERSION}.yaml"
            fi
        fi

        # Final download using dynamic variables based on the release type.
        # Pattern: server / stage / major_version.x / filename
        FULL_URL="https://${PACKAGE_URL}/${RELEASE_STAGE}/${WAZUH_MAJOR_VERSION}.x/${ARTIFACT_URLS_DIR}/${ARTIFACT_URLS_DOWNLOAD}"
        echo "Attempting to download: $FULL_URL"
        curl -fsSL -o "$ARTIFACT_URLS_FILE" "$FULL_URL" || {
            echo "Error: Failed to download artifact URLs from $FULL_URL" >&2
            clean 1
        }
    fi

    awk -F':' '!/^#/ && NF>1 {name=$1; val=substr($0,length(name)+3); gsub(/[-.]/,"_",name); print name "=\"" val "\""}' $ARTIFACT_URLS_FILE > artifacts_env.txt

    # Set component commit references for development builds.
    # Commits are only resolved (and later appended to the image tag) when --dev is
    # explicitly passed. Production and stage builds (dev=false) never include a
    # commit suffix even if -refs is provided. Manual local builds also omit it.
    if [ -n "${IS_DEV_BUILD}" ]; then
        if [ -z "${WAZUH_COMPONENTS_COMMIT_LIST}" ]; then
            # Default to 'latest' for all components if no specific references are provided
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

        # Generate component-specific IMAGE_TAG.
        # The commit suffix is only appended when --dev was passed, which maps
        # directly to inputs.dev=true in the workflow. This ensures:
        #   dev=false, tag=5.0.0       → 5.0.0
        #   dev=false, tag=5.0.0-beta1 → 5.0.0-beta1
        #   dev=true,  tag=5.0.0       → 5.0.0-latest
        #   dev=true,  tag=5.0.0-beta1 → 5.0.0-beta1-latest
        if [ -n "${IS_DEV_BUILD}" ]; then
            IMAGE_TAG="${WAZUH_IMAGE_VERSION}${WAZUH_DEV_STAGE:+-${WAZUH_DEV_STAGE,,}}-${COMPONENT_COMMIT}"
        else
            IMAGE_TAG="${WAZUH_IMAGE_VERSION}${WAZUH_DEV_STAGE:+-${WAZUH_DEV_STAGE,,}}"
        fi
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
                    --build-arg wazuh_indexer_x86_64_rpm="${wazuh_indexer_x86_64_rpm}"
                    --build-arg wazuh_indexer_aarch64_rpm="${wazuh_indexer_aarch64_rpm}"
                    --build-arg wazuh_certs_tool="${wazuh_certs_tool}"
                    --build-arg wazuh_config_yml="${wazuh_config_yml}"
                )
                ;;
            wazuh-manager)
                build_args+=(
                    --build-arg wazuh_manager_x86_64_rpm="${wazuh_manager_x86_64_rpm}"
                    --build-arg wazuh_manager_aarch64_rpm="${wazuh_manager_aarch64_rpm}"
                )
                ;;
            wazuh-dashboard)
                build_args+=(
                    --build-arg wazuh_dashboard_x86_64_rpm="${wazuh_dashboard_x86_64_rpm}"
                    --build-arg wazuh_dashboard_aarch64_rpm="${wazuh_dashboard_aarch64_rpm}"
                    --build-arg wazuh_certs_tool="${wazuh_certs_tool}"
                    --build-arg wazuh_config_yml="${wazuh_config_yml}"
                )
                ;;
            wazuh-agent)
                build_args+=(
                    --build-arg wazuh_agent_x86_64_rpm="${wazuh_agent_x86_64_rpm}"
                    --build-arg wazuh_agent_aarch64_rpm="${wazuh_agent_aarch64_rpm}"
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
    echo "    -d, --dev-stage <ref>        [Optional] Set the pre-release stage suffix (e.g. beta1, rc2). Not used by default."
    echo "    --dev                        [Optional] Mark as a development build: appends the commit ref to the image tag. Controlled by inputs.dev in the workflow."
    echo "    -refs, --references <refs>   [Optional] [Only with --dev] JSON array of commit refs for components (indexer, manager, dashboard, agent) in order. Defaults to 'latest'."
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
        "-d"|"--dev-stage")
            if [ -n "${2}" ]; then
                WAZUH_DEV_STAGE="${2}"
                shift 2
            else
                help 1
            fi
            ;;
        "--dev")
            IS_DEV_BUILD="true"
            shift
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
