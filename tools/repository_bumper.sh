#!/bin/bash

# This script is used to update the version of a repository in the specified files.
# It takes a version number as an argument and updates the version in the specified files.
# Usage: ./repository_bumper.sh <version>

# Global variables
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="${DIR}/tools/repository_bumper_$(date +"%Y-%m-%d_%H-%M-%S-%3N").log"
VERSION=""
STAGE=""
FILES_EDITED=()
FILES_EXCLUDED='--exclude="repository_bumper_*.log" --exclude="CHANGELOG.md" --exclude="repository_bumper.sh" --exclude="*_bumper_repository.yml"'

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
    eval grep -Rl "${1}" "${2}" --exclude-dir=".git" $FILES_EXCLUDED "${3}"
}

update_version_in_files() {

    local OLD_MAYOR="$(echo "${OLD_VERSION}" | cut -d '.' -f 1)"
    local OLD_MINOR="$(echo "${OLD_VERSION}" | cut -d '.' -f 2)"
    local OLD_PATCH="$(echo "${OLD_VERSION}" | cut -d '.' -f 3)"
    local NEW_MAYOR="$(echo "${VERSION}" | cut -d '.' -f 1)"
    local NEW_MINOR="$(echo "${VERSION}" | cut -d '.' -f 2)"
    local NEW_PATCH="$(echo "${VERSION}" | cut -d '.' -f 3)"
    m_m_p_files=( $(grep_command "${OLD_MAYOR}\.${OLD_MINOR}\.${OLD_PATCH}" "${DIR}") )
    for file in "${m_m_p_files[@]}"; do
        sed -i "s/\bv${OLD_MAYOR}\.${OLD_MINOR}\.${OLD_PATCH}\b/v${NEW_MAYOR}\.${NEW_MINOR}\.${NEW_PATCH}/g; s/\b${OLD_MAYOR}\.${OLD_MINOR}\.${OLD_PATCH}/${NEW_MAYOR}\.${NEW_MINOR}\.${NEW_PATCH}/g" "${file}"
        if [[ $(git diff --name-only "${file}") ]]; then
            FILES_EDITED+=("${file}")
        fi
    done
    m_m_files=( $(grep_command "${OLD_MAYOR}\.${OLD_MINOR}" "${DIR}") )
    for file in "${m_m_files[@]}"; do
        sed -i -E "/[0-9]+\.[0-9]+\.[0-9]+/! s/(^|[^0-9.])(${OLD_MAYOR}\.${OLD_MINOR})([^0-9.]|$)/\1${NEW_MAYOR}.${NEW_MINOR}\3/g" "$file"
        if [[ $(git diff --name-only "${file}") ]]; then
            FILES_EDITED+=("${file}")
        fi
    done
    m_x_files=( $(grep_command "${OLD_MAYOR}\.x" "${DIR}") )
    for file in "${m_x_files[@]}"; do
        sed -i "s/\b${OLD_MAYOR}\.x\b/${NEW_MAYOR}\.x/g" "${file}"
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
                TAG="$2"
                shift 2
                ;;
            *)
                echo "Unknown argument: $1"
                exit 1
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "${VERSION}" ]]; then
        echo "Error: --version argument is required." | tee -a "${LOG_FILE}"
        exit 1
    fi

    if [[ -z "${STAGE}" ]]; then
        echo "Error: --stage argument is required." | tee -a "${LOG_FILE}"
        exit 1
    fi

    # Validate if version is in the correct format
    if ! [[ "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version must be in the format X.Y.Z (e.g., 1.2.3)." | tee -a "${LOG_FILE}"
        exit 1
    fi

    # Validate if stage is in the correct format
    STAGE=$(echo "${STAGE}" | tr '[:upper:]' '[:lower:]')
    if ! [[ "${STAGE}" =~ ^(alpha[0-9]*|beta[0-9]*|rc[0-9]*|stable)$ ]]; then
        echo "Error: Stage must be one of the following examples: alpha1, beta1, rc1, stable." | tee -a "${LOG_FILE}"
        exit 1
    fi

    # Validate if tag is true or false
    if [[ -n "${TAG}" && ! "${TAG}" =~ ^(true|false)$ ]]; then
        echo "Error: --tag must be either true or false." | tee -a "${LOG_FILE}"
        exit 1
    fi

    # Get old version and stage
    get_old_version_and_stage

    if [[ "${OLD_VERSION}" == "${VERSION}" && "${OLD_STAGE}" == "${STAGE}" ]]; then
        echo "Version and stage are already up to date." | tee -a "${LOG_FILE}"
        echo "No changes needed." | tee -a "${LOG_FILE}"
        exit 0
    fi
    if [[ "${OLD_VERSION}" != "${VERSION}" ]]; then
        echo "Updating version from ${OLD_VERSION} to ${VERSION}" | tee -a "${LOG_FILE}"
        update_version_in_files "${VERSION}"
    fi
    if [[ "${OLD_STAGE}" != "${STAGE}" ]]; then
        echo "Updating stage from ${OLD_STAGE} to ${STAGE}" | tee -a "${LOG_FILE}"
        update_stage_in_files "${STAGE}"
    fi

    # Update Docker images tag if tag is true
    if [[ "${TAG}" == "true" ]]; then
        echo "Updating Docker images tag to ${VERSION}-${STAGE}" | tee -a "${LOG_FILE}"
        update_docker_images_tag "${VERSION}-${STAGE}"
    fi


    echo "The following files were edited:" | tee -a "${LOG_FILE}"
    for file in $(printf "%s\n" "${FILES_EDITED[@]}" | sort -u); do
        echo "${file}" | tee -a "${LOG_FILE}"
    done

    echo "Version and stage updated successfully." | tee -a "${LOG_FILE}"
}

# Call the main method with all arguments
main "$@"
