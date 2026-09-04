#!/bin/bash
# Wazuh App Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Wazuh API and Wazuh indexer credentials of this deployment. Sourced by the
# init scripts and by password-tool.sh; defines functions and runs nothing on
# its own. See docs/ref/credentials.md.

WAZUH_CREDENTIALS_DIR="${WAZUH_CREDENTIALS_DIR:-/wazuh-credentials}"
WAZUH_INDEXER_CREDENTIALS_FILE="${WAZUH_CREDENTIALS_DIR}/indexer-users.env"
WAZUH_API_CREDENTIALS_FILE="${WAZUH_CREDENTIALS_DIR}/api-users.env"

# The dashboard container reads what this one publishes and does not run as root.
WAZUH_CREDENTIALS_UID=101
WAZUH_CREDENTIALS_GID=101

WAZUH_API_USERS=(wazuh wazuh-wui)

declare -A WAZUH_API_PASSWORDS=()

credentials_log() {
  echo "[credentials] $*"
}

credentials_error() {
  echo "[credentials] ERROR: $*" >&2
}

credentials_api_key() {
  echo "API_$(echo "$1" | tr '[:lower:]-' '[:upper:]_')_PASSWORD"
}

credentials_generate() {
  local body special lower upper digit
  body=$(tr -dc 'A-Za-z0-9.*+?-' < /dev/urandom | head -c 28)
  special=$(tr -dc '.*+?-' < /dev/urandom | head -c 1)
  lower=$(tr -dc 'a-z' < /dev/urandom | head -c 1)
  upper=$(tr -dc 'A-Z' < /dev/urandom | head -c 1)
  digit=$(tr -dc '0-9' < /dev/urandom | head -c 1)
  echo "${body}${special}${lower}${upper}${digit}" | fold -w1 | shuf | tr -d '\n'
}

credentials_validate() {
  local password=$1
  [ "${#password}" -ge 8 ] && [ "${#password}" -le 64 ] || return 1
  [[ ${password} == *[[:upper:]]* ]] || return 1
  [[ ${password} == *[[:lower:]]* ]] || return 1
  [[ ${password} == *[[:digit:]]* ]] || return 1
  [[ ${password} == *[.*+?-]* ]] || return 1
  return 0
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

credentials_api_load() {
  local user value loaded=0

  for user in "${WAZUH_API_USERS[@]}"; do
    if value=$(credentials_get "${WAZUH_API_CREDENTIALS_FILE}" "$(credentials_api_key "${user}")"); then
      WAZUH_API_PASSWORDS["${user}"]="${value}"
      loaded=1
    fi
  done

  [ "${loaded}" -eq 1 ]
}

credentials_api_render() {
  local user quoted
  echo "# Wazuh API users of this deployment."
  echo "# Read by the Wazuh dashboard container."
  for user in "${WAZUH_API_USERS[@]}"; do
    quoted=${WAZUH_API_PASSWORDS[${user}]//\'/\'\\\'\'}
    echo "$(credentials_api_key "${user}")='${quoted}'"
  done
}

credentials_api_store() {
  local tmp_file="${WAZUH_CREDENTIALS_DIR}/.api-users.env.$$"

  ( umask 077; credentials_api_render > "${tmp_file}" ) 2>/dev/null || { rm -f "${tmp_file}"; return 1; }
  chown "${WAZUH_CREDENTIALS_UID}:${WAZUH_CREDENTIALS_GID}" "${tmp_file}" 2>/dev/null || true
  mv -f "${tmp_file}" "${WAZUH_API_CREDENTIALS_FILE}" 2>/dev/null || { rm -f "${tmp_file}"; return 1; }
  return 0
}

# Published with a hard link, which fails when the name is taken: manager nodes
# starting at the same time cannot overwrite each other's file.
credentials_api_publish() {
  local tmp_file="${WAZUH_CREDENTIALS_DIR}/.api-users.env.$$"

  ( umask 077; credentials_api_render > "${tmp_file}" ) 2>/dev/null || { rm -f "${tmp_file}"; return 1; }
  chown "${WAZUH_CREDENTIALS_UID}:${WAZUH_CREDENTIALS_GID}" "${tmp_file}" 2>/dev/null || true
  if ln "${tmp_file}" "${WAZUH_API_CREDENTIALS_FILE}" 2>/dev/null; then
    rm -f "${tmp_file}"
    return 0
  fi
  rm -f "${tmp_file}"
  return 1
}

credentials_api_bootstrap() {
  local user missing=0

  credentials_api_load

  for user in "${WAZUH_API_USERS[@]}"; do
    if [ -z "${WAZUH_API_PASSWORDS[${user}]}" ]; then
      WAZUH_API_PASSWORDS["${user}"]=$(credentials_generate)
      missing=1
    fi
  done

  [ "${missing}" -eq 1 ] || return 0

  if [ ! -d "${WAZUH_CREDENTIALS_DIR}" ] || [ ! -w "${WAZUH_CREDENTIALS_DIR}" ]; then
    credentials_error "${WAZUH_CREDENTIALS_DIR} is not a writable volume, so the Wazuh API passwords"
    credentials_error "of this deployment cannot be shared with the dashboard container"
    return 1
  fi

  if [ -f "${WAZUH_API_CREDENTIALS_FILE}" ]; then
    credentials_api_store || { credentials_error "could not write ${WAZUH_API_CREDENTIALS_FILE}"; return 1; }
  elif credentials_api_publish; then
    credentials_log "Generated the Wazuh API passwords of this deployment"
    credentials_log "Log in to the Wazuh API as 'wazuh' with: ${WAZUH_API_PASSWORDS[wazuh]}"
    credentials_log "This is the only time it is printed. Read them again with 'password-tool.sh --show'."
  else
    WAZUH_API_PASSWORDS=()
    credentials_api_load || { credentials_error "could not read ${WAZUH_API_CREDENTIALS_FILE}"; return 1; }
    credentials_log "Using the Wazuh API passwords published by another manager node"
  fi

  return 0
}

# Applies the recorded passwords to the RBAC database of this node. The
# credentials volume is the deployment's password store, so a stored password
# that does not match it is replaced.
credentials_api_apply() {
  local user args=()

  for user in "${WAZUH_API_USERS[@]}"; do
    args+=("${user}=${WAZUH_API_PASSWORDS[${user}]}")
  done

  ( cd /var/wazuh-manager && \
    WAZUH_API_CREDENTIALS="$(printf '%s\n' "${args[@]}")" \
    /var/wazuh-manager/framework/python/bin/python3 /etc/wazuh-api-users.py )
}

credentials_resolve_indexer_password() {
  local user="${INDEXER_USERNAME:-wazuh-manager}" key value

  [ -z "${INDEXER_PASSWORD}" ] || return 0

  key="INDEXER_$(echo "${user}" | tr '[:lower:]-' '[:upper:]_')_PASSWORD"
  if value=$(credentials_get "${WAZUH_INDEXER_CREDENTIALS_FILE}" "${key}"); then
    INDEXER_PASSWORD="${value}"
    return 0
  fi

  credentials_error "no password for the indexer user '${user}'"
  return 1
}
