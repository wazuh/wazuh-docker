#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Wazuh indexer and Wazuh API credentials of this deployment. Sourced by the
# entrypoint; defines functions and runs nothing on its own.
# See docs/ref/credentials.md.

WAZUH_CREDENTIALS_DIR="${WAZUH_CREDENTIALS_DIR:-/wazuh-credentials}"
WAZUH_INDEXER_CREDENTIALS_FILE="${WAZUH_CREDENTIALS_DIR}/indexer-users.env"
WAZUH_API_CREDENTIALS_FILE="${WAZUH_CREDENTIALS_DIR}/api-users.env"

credentials_error() {
  echo "[credentials] ERROR: $*" >&2
}

# The files are data written by another container: they are parsed, never sourced.
credentials_get() {
  local file=$1 wanted=$2 line key value

  [ -r "${file}" ] || return 1

  while IFS= read -r line; do
    key=${line%%=*}
    [ "${key}" = "${wanted}" ] || continue
    value=${line#*=}
    value=${value#\'}
    value=${value%\'}
    value=${value//\'\\\'\'/\'}
    printf '%s' "${value}"
    return 0
  done < "${file}"

  return 1
}

credentials_resolve_indexer_password() {
  local user="${DASHBOARD_USERNAME:-kibanaserver}" key value

  [ -z "${DASHBOARD_PASSWORD}" ] || return 0

  key="INDEXER_$(echo "${user}" | tr '[:lower:]-' '[:upper:]_')_PASSWORD"
  if value=$(credentials_get "${WAZUH_INDEXER_CREDENTIALS_FILE}" "${key}"); then
    DASHBOARD_PASSWORD="${value}"
    return 0
  fi

  credentials_error "no password for the indexer user '${user}'"
  return 1
}

credentials_resolve_api_password() {
  local user="${API_USERNAME:-wazuh-wui}" key value

  [ -z "${API_PASSWORD}" ] || return 0

  key="API_$(echo "${user}" | tr '[:lower:]-' '[:upper:]_')_PASSWORD"
  if value=$(credentials_get "${WAZUH_API_CREDENTIALS_FILE}" "${key}"); then
    API_PASSWORD="${value}"
    return 0
  fi

  credentials_error "no password for the Wazuh API user '${user}'"
  return 1
}
