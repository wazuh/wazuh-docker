#!/bin/bash

# This script is used to update the version of a repository in the specified files.
# It takes a version number as an argument and updates the version in the specified files.
# Usage: ./repository_bumper.sh <version>

# Global variables
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="${DIR}/tools/repository_bumper_$(date +"%Y-%m-%d_%H-%M-%S-%3N").log"
VERSION=""
STAGE=""
TAG=""
REFERENCE=""
FILES_EDITED=()
FILES_EXCLUDED='--exclude="repository_bumper_*.log" --exclude="CHANGELOG.md" --exclude="repository_bumper.sh" --exclude="*_bumper_repository.yml" --exclude="mermaid-init.js" --exclude="mermaid.min.js"'

get_old_version_and_stage() {
    local VERSION_FILE="${DIR}/VERSION.json"

    OLD_VERSION=$(jq -r '.version' "${VERSION_FILE}")
    OLD_STAGE=$(jq -r '.stage' "${VERSION_FILE}")
    echo "Old version: ${OLD_VERSION}" | tee -a "${LOG_FILE}"
    echo "Old stage: ${OLD_STAGE}" | tee -a "${LOG_FILE}"
}

grep_command() {
    # This function is used to search for a specific string in the specified directory.
    # It takes two arguments: the string to search for and the directory to search in.
    # Usage: grep_command <string> <directory>
    eval grep -Rl \"${1}\" \"${2}\" --exclude-dir=".git" $FILES_EXCLUDED "${3}"
}

update_version_in_files() {

    local OLD_MAJOR="$(echo "${OLD_VERSION}" | cut -d '.' -f 1)"
    local OLD_MINOR="$(echo "${OLD_VERSION}" | cut -d '.' -f 2)"
    local OLD_PATCH="$(echo "${OLD_VERSION}" | cut -d '.' -f 3)"
    local NEW_MAJOR="$(echo "${VERSION}" | cut -d '.' -f 1)"
    local NEW_MINOR="$(echo "${VERSION}" | cut -d '.' -f 2)"
    local NEW_PATCH="$(echo "${VERSION}" | cut -d '.' -f 3)"
    m_m_p_files=( $(grep_command "${OLD_MAJOR}\.${OLD_MINOR}\.${OLD_PATCH}" "${DIR}") )
    for file in "${m_m_p_files[@]}"; do
        sed -i "s/\bv${OLD_MAJOR}\.${OLD_MINOR}\.${OLD_PATCH}\b/v${NEW_MAJOR}\.${NEW_MINOR}\.${NEW_PATCH}/g; s/\b${OLD_MAJOR}\.${OLD_MINOR}\.${OLD_PATCH}/${NEW_MAJOR}\.${NEW_MINOR}\.${NEW_PATCH}/g" "${file}"
        if [[ $(git diff --name-only "${file}") ]]; then
            FILES_EDITED+=("${file}")
        fi
    done
    m_m_files=( $(grep_command "${OLD_MAJOR}\.${OLD_MINOR}" "${DIR}") )
    for file in "${m_m_files[@]}"; do
        sed -i -E "/[0-9]+\.[0-9]+\.[0-9]+/! s/(^|[^0-9.])(${OLD_MAJOR}\.${OLD_MINOR})([^0-9.]|$)/\1${NEW_MAJOR}.${NEW_MINOR}\3/g" "$file"
        if [[ $(git diff --name-only "${file}") ]]; then
            FILES_EDITED+=("${file}")
        fi
    done
    m_x_files=( $(grep_command "${OLD_MAJOR}\.x" "${DIR}") )
    for file in "${m_x_files[@]}"; do
        sed -i "s/\b${OLD_MAJOR}\.x\b/${NEW_MAJOR}\.x/g" "${file}"
        if [[ $(git diff --name-only "${file}") ]]; then
            FILES_EDITED+=("${file}")
        fi
    done
    if ! sed -i "/^All notable changes to this project will be documented in this file.$/a \\\n## [${VERSION}]\\n\\n### Added\\n\\n- None\\n\\n### Changed\\n\\n- None\\n\\n### Fixed\\n\\n- None\\n\\n### Deleted\\n\\n- None" "${DIR}/CHANGELOG.md"; then
        echo "Error: Failed to update CHANGELOG.md" | tee -a "${LOG_FILE}"
    fi
    if [[ $(git diff --name-only "${DIR}/CHANGELOG.md") ]]; then
        FILES_EDITED+=("${DIR}/CHANGELOG.md")
    fi
}

update_stage_in_files() {
    local OLD_STAGE="$(echo "${OLD_STAGE}")"
    files=( $(grep_command "${OLD_STAGE}" "${DIR}" --exclude="README.md") )
    for file in "${files[@]}"; do
        sed -i "s/${OLD_STAGE}/${STAGE}/g" "${file}"
        if [[ $(git diff --name-only "${file}") ]]; then
            FILES_EDITED+=("${file}")
        fi
    done
}

# Compute the value written into branch reference defaults ("<key>: '...'").
# Without --tag, references stay branch-like (e.g. 5.0.0).
# With --tag, references become tag-like (e.g. v5.0.0-beta3), or a plain release
# tag (e.g. v5.0.0) when no stage is provided.
build_reference() {
    if [[ -n "$TAG" ]]; then
        if [[ -z "$STAGE" ]]; then
            REFERENCE="v${VERSION}"
        else
            REFERENCE="v${VERSION}-${STAGE}"
        fi
    else
        REFERENCE="${VERSION}"
    fi
}

# Tag mode only: normalize every reference to the current version
# (branch-like "5.0.0", "v5.0.0" or "v5.0.0-<stage>") into ${REFERENCE}.
# Matching is restricted to "<key>: '...'" entries so plain version strings
# elsewhere in the repository are left untouched.
update_tag_references() {
    local V_ESC="${VERSION//./\\.}"
    files=( $(grep_command "${VERSION}" "${DIR}") )
    for file in "${files[@]}"; do
        sed -Ei "s/(:[[:space:]]*')v?${V_ESC}(-[A-Za-z0-9]+)?(')/\1${REFERENCE}\3/g" "${file}"
        if [[ $(git diff --name-only "${file}") ]]; then
            FILES_EDITED+=("${file}")
        fi
    done
}

update_main_in_files() {
    local main_string=": 'main'"
    files=( $(grep_command "${main_string}" "${DIR}") )
    for file in "${files[@]}"; do
        sed -Ei "s/(:[[:space:]])'main'/\1'${REFERENCE}'/g" "${file}"
        if [[ $(git diff --name-only "${file}") ]]; then
            FILES_EDITED+=("${file}")
        fi
    done
}

update_docker_images_tag() {
    local NEW_TAG="$1"
    local DOCKERFILES=( $(grep_command "wazuh/wazuh-[a-zA-Z0-9._-]*" "${DIR}" "--exclude="README.md"  --exclude="generate-indexer-certs.yml"") )
    for file in "${DOCKERFILES[@]}"; do
        sed -i -E "s/(wazuh\/wazuh-[a-zA-Z0-9._-]*):[a-zA-Z0-9._-]+/\1:${NEW_TAG}/g" "${file}"
        if [[ $(git diff --name-only "${file}") ]]; then
            FILES_EDITED+=("${file}")
        fi
    done
}

main() {

    echo "Starting repository version bumping process..." | tee -a "${LOG_FILE}"
    echo "Log file: ${LOG_FILE}"
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                VERSION="$2"
                shift 2
                ;;
            --stage)
                STAGE="$2"
                shift 2
                ;;
            --tag)
                TAG="yes"
                shift 1
                ;;
            --set-as-main)
                set_as_main="yes"
                shift 1
                ;;
            *)
                echo "Unknown argument: $1"
                exit 1
                ;;
        esac
    done

    # --tag rewrites branch references into tag-like references (e.g. v5.0.0-beta3)
    # and re-tags the Docker images accordingly. It is mutually exclusive with
    # --set-as-main, which keeps references on main.
    if [[ -n "$TAG" && -n "$set_as_main" ]]; then
        echo "Error: --tag cannot be combined with --set-as-main." | tee -a "${LOG_FILE}"
        exit 1
    fi

    # Read the current version/stage early: tag scenarios may omit --version and/or
    # --stage and reuse the values already stored in VERSION.json.
    get_old_version_and_stage

    # Resolve and validate arguments depending on the mode
    if [[ -n "$TAG" ]]; then
        # Tag mode: version defaults to the current one; stage is optional
        # (absent yields a release tag without a stage suffix).
        [[ -z "$VERSION" ]] && VERSION="$OLD_VERSION"
    else
        # Branch mode: a full version + stage bump is required
        if [[ -z "${VERSION}" ]]; then
            echo "Error: --version argument is required." | tee -a "${LOG_FILE}"
            exit 1
        fi
        if [[ -z "${STAGE}" ]]; then
            echo "Error: --stage argument is required." | tee -a "${LOG_FILE}"
            exit 1
        fi
    fi

    # Validate if version is in the correct format
    if ! [[ "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version must be in the format X.Y.Z (e.g., 1.2.3)." | tee -a "${LOG_FILE}"
        exit 1
    fi

    # Validate if stage is in the correct format (when provided)
    if [[ -n "${STAGE}" ]]; then
        STAGE=$(echo "${STAGE}" | tr '[:upper:]' '[:lower:]')
        if ! [[ "${STAGE}" =~ ^(alpha[0-9]*|beta[0-9]*|rc[0-9]*|stable)$ ]]; then
            echo "Error: Stage must be one of the following examples: alpha1, beta1, rc1, stable." | tee -a "${LOG_FILE}"
            exit 1
        fi
    fi

    # Compute the value written into branch reference defaults
    build_reference
    echo "Reference for branch defaults: ${REFERENCE}" | tee -a "${LOG_FILE}"

    # Convert 'main' references unless they must keep pointing to main (set-as-main)
    if [[ -z "$set_as_main" ]]; then
        echo "Updating 'main' references to ${REFERENCE}" | tee -a "${LOG_FILE}"
        update_main_in_files
    fi

    if [[ "${OLD_VERSION}" != "${VERSION}" ]]; then
        echo "Updating version from ${OLD_VERSION} to ${VERSION}" | tee -a "${LOG_FILE}"
        update_version_in_files "${VERSION}"
    fi
    if [[ -n "$STAGE" ]]; then
        echo "Updating stage from ${OLD_STAGE} to ${STAGE}" | tee -a "${LOG_FILE}"
        update_stage_in_files "$VERSION" "$STAGE"
    fi

    # Tag mode: normalize remaining version references and re-tag the Docker images
    # (image tags carry no leading 'v', e.g. 5.0.0-beta3).
    if [[ -n "$TAG" ]]; then
        echo "Updating version references to tag reference ${REFERENCE}" | tee -a "${LOG_FILE}"
        update_tag_references
        echo "Updating Docker images tag to ${REFERENCE#v}" | tee -a "${LOG_FILE}"
        update_docker_images_tag "${REFERENCE#v}"
    fi


    echo "The following files were edited:" | tee -a "${LOG_FILE}"
    for file in $(printf "%s\n" "${FILES_EDITED[@]}" | sort -u); do
        echo "${file}" | tee -a "${LOG_FILE}"
    done

    echo "Version and stage updated successfully." | tee -a "${LOG_FILE}"
}

# Call the main method with all arguments
main "$@"
