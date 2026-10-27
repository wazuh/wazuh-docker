#!/bin/bash

# Wazuh package generator
# Copyright (C) Wazuh Inc.
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
IS_RELEASE_BUILD=""
SKIP_PACKAGE_SIGNATURE_CHECK=""
ARTIFACT_URLS_INPUT=""
BASE_IMAGE_PULL_RETRIES="${BASE_IMAGE_PULL_RETRIES:-5}"
BASE_IMAGE_PULL_DELAY="${BASE_IMAGE_PULL_DELAY:-15}"
BASE_IMAGES_DIR=""
BASE_IMAGES_BAKE_FILE=""

# -----------------------------------------------------------------------------

trap ctrl_c INT

clean() {
    exit_code=$1

    if [ -n "${BASE_IMAGES_DIR}" ]; then
        rm -rf "${BASE_IMAGES_DIR}"
    fi

    exit ${exit_code}
}

ctrl_c() {
    clean 1
}

# -----------------------------------------------------------------------------

# Runs a command until it succeeds, up to BASE_IMAGE_PULL_RETRIES times, waiting
# BASE_IMAGE_PULL_DELAY seconds more after each failed attempt.
retry() {
    local attempt=1
    until "$@"; do
        if [ "${attempt}" -ge "${BASE_IMAGE_PULL_RETRIES}" ]; then
            return 1
        fi
        local wait=$(( BASE_IMAGE_PULL_DELAY * attempt ))
        echo "Attempt ${attempt}/${BASE_IMAGE_PULL_RETRIES} failed. Retrying in ${wait}s..." >&2
        sleep "${wait}"
        attempt=$(( attempt + 1 ))
    done
}

# Prints the base images of a Dockerfile: the FROM images that are not a
# previous stage.
base_images_of() {
    awk 'toupper($1) == "FROM" {
             image = $2
             for (i = 2; i <= NF; i++) if ($i !~ /^--/) { image = $i; break }
             if (!(image in stage)) print image
             for (i = 2; i < NF; i++) if (toupper($i) == "AS") stage[$(i + 1)] = 1
         }' "$1"
}

# Downloads the base images before the build, with retries, so that a registry
# rate limit (429 Too Many Requests) fails here instead of in the middle of the
# build. The docker driver uses the images pulled into the daemon. Other drivers
# (docker-container, as in CI) do not see them, so the images are exported to
# OCI layouts and passed to bake as named contexts in an extra bake file.
prefetch_base_images() {
    local components=("$@")
    local driver
    driver=$(docker buildx inspect 2>/dev/null | awk '$1 == "Driver:" { print $2; exit }')

    local platforms=""
    if [ "${MULTIARCH}" ]; then
        platforms="linux/amd64,linux/arm64"
    fi

    local images=()
    local component image
    for component in "${components[@]}"; do
        while read -r image; do
            [[ " ${images[*]} " == *" ${image} "* ]] || images+=("${image}")
        done < <(base_images_of "${component}/Dockerfile")
    done

    echo "Downloading base images (driver: ${driver:-unknown}, up to ${BASE_IMAGE_PULL_RETRIES} attempts each): ${images[*]}"

    if [ "${driver}" = "docker" ]; then
        for image in "${images[@]}"; do
            retry docker pull ${platforms:+--platform "${platforms%%,*}"} "${image}" || {
                echo "Error: could not download the base image ${image}." >&2
                return 1
            }
        done
        return 0
    fi

    BASE_IMAGES_DIR=$(mktemp -d)
    mkdir -p "${BASE_IMAGES_DIR}/context"
    local contexts="{}"
    local i=0
    for image in "${images[@]}"; do
        local layout="${BASE_IMAGES_DIR}/image-${i}"
        echo "FROM ${image}" > "${BASE_IMAGES_DIR}/context/Dockerfile.${i}"
        retry docker buildx build ${platforms:+--platform "${platforms}"} \
            --output "type=oci,dest=${layout},tar=false" \
            -f "${BASE_IMAGES_DIR}/context/Dockerfile.${i}" "${BASE_IMAGES_DIR}/context" || {
            echo "Error: could not download the base image ${image}." >&2
            return 1
        }
        contexts=$(jq --arg image "${image}" --arg ref "oci-layout://${layout}:latest" \
            '. + {($image): $ref}' <<< "${contexts}")
        i=$(( i + 1 ))
    done

    BASE_IMAGES_BAKE_FILE="${BASE_IMAGES_DIR}/base-images.json"
    jq -n --argjson contexts "${contexts}" --args \
        '{target: (reduce $ARGS.positional[] as $t ({}; . + {($t): {contexts: $contexts}}))}' \
        "${components[@]}" > "${BASE_IMAGES_BAKE_FILE}"
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

    # Unsigned packages only come from development builds.
    if [ -n "${SKIP_PACKAGE_SIGNATURE_CHECK}" ]; then
        if [ -z "${IS_DEV_BUILD}" ]; then
            echo "Error: --skip-signature-check is only valid along with --dev." >&2
            clean 1
        fi
        echo "Warning: Skipping the signature check of the Wazuh packages. Use it only with unsigned development packages." >&2
    fi
    if [ -n "${IS_RELEASE_BUILD}" ]; then
        if [ -n "${IS_DEV_BUILD}" ] || [ -n "${WAZUH_DEV_STAGE}" ] || [ -n "${ARTIFACT_URLS_INPUT}" ]; then
            echo "Error: --release cannot be combined with --dev, --dev-stage or --artifact-urls." >&2
            clean 1
        fi
    fi
    # ARTIFACT_URLS_FILE: The name of the artifact URLs file.
    ARTIFACT_URLS_FILE="artifact_urls.yaml"
    # ARTIFACT_URLS_DIR: The name of the artifact URLs directory.
    ARTIFACT_URLS_DIR="artifact-urls"

    if [ -n "${ARTIFACT_URLS_INPUT}" ]; then
        if [ ! -f "${ARTIFACT_URLS_INPUT}" ]; then
            echo "Error: artifact URLs file '${ARTIFACT_URLS_INPUT}' not found." >&2
            clean 1
        fi
        echo "Using artifact URLs from ${ARTIFACT_URLS_INPUT}."
        if [ "${ARTIFACT_URLS_INPUT}" != "${ARTIFACT_URLS_FILE}" ]; then
            cp "${ARTIFACT_URLS_INPUT}" "${ARTIFACT_URLS_FILE}" || clean 1
        fi
    else
        # GitHub URL for exact Release Tag lookup
        TAG="v${WAZUH_IMAGE_VERSION}"
        REPO="wazuh/wazuh-docker"
        GH_URL="https://api.github.com/repos/${REPO}/releases/tags/${TAG}"

        # Fetch the HTTP status code to determine release environment.
        # Using -L to follow redirects (GitHub may return 301/302 for some endpoints).
        if [ -z "${IS_RELEASE_BUILD}" ]; then
            HTTP_STATUS=$(curl -sL -o /dev/null -w "%{http_code}" "$GH_URL")
        fi

        if [ -n "${IS_RELEASE_BUILD}" ]; then
            # CASE: Final release. The GitHub release is still a draft at this point,
            # so it is not looked up.
            echo "Final release build. Setting Production environment."
            ARTIFACT_URLS_DOWNLOAD="artifact_urls_${WAZUH_IMAGE_VERSION}.yaml"
            PACKAGE_URL="packages.wazuh.com"
            RELEASE_STAGE="production"
        elif [ "$HTTP_STATUS" -eq 200 ]; then
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
        # A final release build may start before the production sync publishes the file.
        DOWNLOAD_ATTEMPTS=1
        if [ -n "${IS_RELEASE_BUILD}" ]; then
            DOWNLOAD_ATTEMPTS="${ARTIFACT_URLS_ATTEMPTS:-60}"
            if ! [[ "${DOWNLOAD_ATTEMPTS}" =~ ^[1-9][0-9]*$ ]]; then
                echo "Error: ARTIFACT_URLS_ATTEMPTS must be a positive integer, got '${DOWNLOAD_ATTEMPTS}'." >&2
                clean 1
            fi
        fi
        echo "Attempting to download: $FULL_URL"
        for ((attempt = 1; attempt <= DOWNLOAD_ATTEMPTS; attempt++)); do
            curl -fsSL -o "$ARTIFACT_URLS_FILE" "$FULL_URL" && break
            if [ "$attempt" -ge "$DOWNLOAD_ATTEMPTS" ]; then
                echo "Error: Failed to download artifact URLs from $FULL_URL" >&2
                clean 1
            fi
            echo "Artifact URLs not available yet (attempt ${attempt}/${DOWNLOAD_ATTEMPTS}). Retrying in 30 seconds."
            sleep 30
        done
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


    # Write the global .env file used by deployment compose files.
    # IMAGE_TAG here reflects a non-dev, non-per-component tag for reference.
    local base_tag="${WAZUH_IMAGE_VERSION}${WAZUH_DEV_STAGE:+-${WAZUH_DEV_STAGE,,}}"
    echo WAZUH_VERSION=$WAZUH_IMAGE_VERSION > ../.env
    echo WAZUH_IMAGE_VERSION=$WAZUH_IMAGE_VERSION >> ../.env
    echo WAZUH_REGISTRY=$WAZUH_REGISTRY >> ../.env
    echo IMAGE_TAG=${base_tag} >> ../.env

    set -a
    source ../.env
    source ./artifacts_env.txt
    set +a

    # Validate component if a specific one was requested.
    if [ -n "${WAZUH_COMPONENT}" ]; then
        case "${WAZUH_COMPONENT}" in
            wazuh-indexer|wazuh-manager|wazuh-dashboard|wazuh-agent) ;;
            *)
                echo "Error: Unknown component '${WAZUH_COMPONENT}'" >&2
                clean 1
                ;;
        esac
    fi

    # Generate per-component image tags.
    # The commit suffix is only appended when --dev is passed. This ensures:
    #   dev=false, tag=5.0.0       → 5.0.0
    #   dev=false, tag=5.0.0-beta1 → 5.0.0-beta1
    #   dev=true,  tag=5.0.0       → 5.0.0-latest
    #   dev=true,  tag=5.0.0-beta1 → 5.0.0-beta1-latest
    make_tag() {
        local commit=$1
        if [ -n "${IS_DEV_BUILD}" ]; then
            echo "${WAZUH_IMAGE_VERSION}${WAZUH_DEV_STAGE:+-${WAZUH_DEV_STAGE,,}}-${commit}"
        else
            echo "${base_tag}"
        fi
    }

    export WAZUH_VERSION="$WAZUH_IMAGE_VERSION"
    export MULTIARCH="${MULTIARCH}"
    export SKIP_PACKAGE_SIGNATURE_CHECK="${SKIP_PACKAGE_SIGNATURE_CHECK}"
    export INDEXER_TAG=$(make_tag   "${INDEXER_COMMIT:-latest}")
    export MANAGER_TAG=$(make_tag   "${MANAGER_COMMIT:-latest}")
    export DASHBOARD_TAG=$(make_tag "${DASHBOARD_COMMIT:-latest}")
    export AGENT_TAG=$(make_tag     "${AGENT_COMMIT:-latest}")

    echo "Image tags:"
    echo "  wazuh-indexer:   ${WAZUH_REGISTRY}/wazuh/wazuh-indexer:${INDEXER_TAG}"
    echo "  wazuh-manager:   ${WAZUH_REGISTRY}/wazuh/wazuh-manager:${MANAGER_TAG}"
    echo "  wazuh-dashboard: ${WAZUH_REGISTRY}/wazuh/wazuh-dashboard:${DASHBOARD_TAG}"
    echo "  wazuh-agent:     ${WAZUH_REGISTRY}/wazuh/wazuh-agent:${AGENT_TAG}"

    # Bake options: --push for multi-arch (can't load multi-platform locally),
    # --load for single-arch (stores image in local Docker daemon).
    local bake_opts="--no-cache"
    if [ "${MULTIARCH}" ]; then
        bake_opts="${bake_opts} --push"
    else
        bake_opts="${bake_opts} --load"
    fi

    local components=(wazuh-indexer wazuh-manager wazuh-dashboard wazuh-agent)
    if [ -n "${WAZUH_COMPONENT}" ]; then
        components=("${WAZUH_COMPONENT}")
    fi
    prefetch_base_images "${components[@]}" || clean 1

    local bake_files="-f docker-bake.hcl"
    if [ -n "${BASE_IMAGES_BAKE_FILE}" ]; then
        # Bake only reads the layouts outside its directory when allowed to.
        bake_files="${bake_files} -f ${BASE_IMAGES_BAKE_FILE} --allow=fs.read=${BASE_IMAGES_DIR}"
    fi

    # Build a specific component or the full default group (all 4 in parallel).
    if [ -z "${WAZUH_COMPONENT}" ]; then
        echo "Building all components in parallel..."
        docker buildx bake ${bake_opts} ${bake_files} || clean 1
    else
        echo "Building ${WAZUH_COMPONENT}..."
        docker buildx bake ${bake_opts} ${bake_files} "${WAZUH_COMPONENT}" || clean 1
    fi

    echo ""
    echo "Image build process completed!"

    return 0
}

# -----------------------------------------------------------------------------

help() {
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "    -a, --artifact-urls <file>   [Optional] Use this artifact URLs file instead of downloading the one for the requested version."
    echo "    -d, --dev-stage <ref>        [Optional] Set the pre-release stage suffix (e.g. beta1, rc2). Not used by default."
    echo "    --dev                        [Optional] Mark as a development build: appends the commit ref to the image tag. Controlled by inputs.dev in the workflow."
    echo "    --release                    [Optional] Final release build: use the production artifact URLs file without checking the GitHub release. Not valid with --dev, -d or -a."
    echo "    -refs, --references <refs>   [Optional] [Only with --dev] JSON array of commit refs for components (indexer, manager, dashboard, agent) in order. Defaults to 'latest'."
    echo "    -rg, --registry <reg>        [Optional] Set the Docker registry to push the images."
    echo "    -c, --component <comp>       [Optional] Build only this component: 'wazuh-indexer', 'wazuh-manager', 'wazuh-dashboard' or 'wazuh-agent'. By default, all four."
    echo "    -v, --version <ver>          [Optional] Set the Wazuh version should be builded. By default, ${WAZUH_IMAGE_VERSION}."
    echo "    -m, --multiarch              [Optional] Enable multi-architecture builds."
    echo "    --skip-signature-check       [Optional] [Only with --dev] Install the Wazuh packages without checking that they are signed by Wazuh. Only for unsigned development packages."
    echo "    -h, --help                   Show this help."
    echo
    echo "The base images are downloaded before the build. Environment variables:"
    echo "    BASE_IMAGE_PULL_RETRIES      Attempts per base image. By default, 5."
    echo "    BASE_IMAGE_PULL_DELAY        Seconds added to the wait after each failed attempt. By default, 15."
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
        "-a"|"--artifact-urls")
            if [ -n "${2}" ]; then
                ARTIFACT_URLS_INPUT="${2}"
                shift 2
            else
                help 1
            fi
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
        "--release")
            IS_RELEASE_BUILD="true"
            shift
            ;;
        "--skip-signature-check")
            SKIP_PACKAGE_SIGNATURE_CHECK="true"
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
