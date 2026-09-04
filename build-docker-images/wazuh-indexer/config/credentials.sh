#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Wazuh indexer internal user credentials. Sourced by the entrypoint and by
# password-tool.sh; defines functions and runs nothing on its own.
# See docs/ref/credentials.md.

OPENSEARCH_HOME="${OPENSEARCH_HOME:-/usr/share/wazuh-indexer}"
OPENSEARCH_PATH_CONF="${OPENSEARCH_PATH_CONF:-${OPENSEARCH_HOME}/config}"

INTERNAL_USERS_FILE="${OPENSEARCH_PATH_CONF}/opensearch-security/internal_users.yml"
HASH_TOOL="${OPENSEARCH_HOME}/plugins/opensearch-security/tools/hash.sh"
HASH_PLACEHOLDER="__WAZUH_UNSET_PASSWORD_HASH__"

CREDENTIALS_DIR="${WAZUH_CREDENTIALS_DIR:-/wazuh-credentials}"
CREDENTIALS_FILE="${CREDENTIALS_DIR}/indexer-users.env"

CREDENTIAL_USERS=(admin kibanaserver wazuh-manager wazuh-admin wazuh-readonly wazuh-demo)

declare -A CREDENTIALS=()

credentials_log() {
  echo "[credentials] $*"
}

credentials_error() {
  echo "[credentials] ERROR: $*" >&2
}

credentials_key() {
  echo "INDEXER_$(echo "$1" | tr '[:lower:]-' '[:upper:]_')_PASSWORD"
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

# The password is passed in the environment: an argument would be readable in
# the process list.
credentials_hash() {
  local output
  output=$(WAZUH_PASSWORD_TO_HASH="$1" \
    OPENSEARCH_JAVA_HOME="${OPENSEARCH_JAVA_HOME:-${OPENSEARCH_HOME}/jdk}" \
    JAVA_HOME="${JAVA_HOME:-${OPENSEARCH_HOME}/jdk}" \
    OPENSEARCH_PATH_CONF="${OPENSEARCH_PATH_CONF}" \
    bash "${HASH_TOOL}" -env WAZUH_PASSWORD_TO_HASH 2>/dev/null | grep -E '^\$2[aby]\$' | tail -n1)

  [ -n "${output}" ] || return 1
  echo "${output}"
}

# The file is data written by another container: it is parsed, never sourced.
credentials_load() {
  local line key value user

  [ -r "${CREDENTIALS_FILE}" ] || return 1

  while IFS= read -r line; do
    case "${line}" in
      INDEXER_*_PASSWORD=*) ;;
      *) continue ;;
    esac
    key=${line%%=*}
    value=${line#*=}
    value=${value#\'}
    value=${value%\'}
    value=${value//\'\\\'\'/\'}
    for user in "${CREDENTIAL_USERS[@]}"; do
      [ "$(credentials_key "${user}")" = "${key}" ] && CREDENTIALS["${user}"]="${value}"
    done
  done < "${CREDENTIALS_FILE}"

  return 0
}

credentials_render() {
  local user quoted
  echo "# Wazuh indexer internal users of this deployment."
  echo "# Read by the Wazuh manager and the Wazuh dashboard containers."
  for user in "${CREDENTIAL_USERS[@]}"; do
    quoted=${CREDENTIALS[${user}]//\'/\'\\\'\'}
    echo "$(credentials_key "${user}")='${quoted}'"
  done
}

credentials_store() {
  local tmp_file="${CREDENTIALS_DIR}/.indexer-users.env.$$"

  ( umask 077; credentials_render > "${tmp_file}" ) 2>/dev/null || { rm -f "${tmp_file}"; return 1; }
  mv -f "${tmp_file}" "${CREDENTIALS_FILE}" 2>/dev/null || { rm -f "${tmp_file}"; return 1; }
  return 0
}

# Published with a hard link, which fails when the name is taken: the file only
# ever becomes visible complete, and nodes starting at the same time cannot
# overwrite each other. Whoever loses the race adopts the winner's file.
credentials_publish() {
  local tmp_file="${CREDENTIALS_DIR}/.indexer-users.env.$$"

  ( umask 077; credentials_render > "${tmp_file}" ) 2>/dev/null || { rm -f "${tmp_file}"; return 1; }
  if ln "${tmp_file}" "${CREDENTIALS_FILE}" 2>/dev/null; then
    rm -f "${tmp_file}"
    return 0
  fi
  rm -f "${tmp_file}"
  return 1
}

credentials_write_users() {
  local pairs="" user hash tmp_file="${INTERNAL_USERS_FILE}.tmp.$$"

  for user in "${CREDENTIAL_USERS[@]}"; do
    if ! hash=$(credentials_hash "${CREDENTIALS[${user}]}"); then
      credentials_error "could not hash the password of '${user}'"
      return 1
    fi
    pairs="${pairs}${user}=${hash};"
  done

  awk -v pairs="${pairs}" '
    BEGIN {
      n = split(pairs, entries, ";")
      for (i = 1; i <= n; i++) {
        if (entries[i] == "") continue
        sep = index(entries[i], "=")
        hash[substr(entries[i], 1, sep - 1)] = substr(entries[i], sep + 1)
      }
    }
    /^[A-Za-z0-9_.-]+:[[:space:]]*$/ {
      current = $0
      sub(/:.*$/, "", current)
    }
    /^[[:space:]]+hash:/ && (current in hash) {
      match($0, /^[[:space:]]+/)
      printf "%shash: \"%s\"\n", substr($0, 1, RLENGTH), hash[current]
      seen[current] = 1
      next
    }
    { print }
    END {
      for (user in hash)
        if (!(user in seen))
          print user > "/dev/stderr"
    }
  ' "${INTERNAL_USERS_FILE}" > "${tmp_file}" 2>"${tmp_file}.err" || {
    rm -f "${tmp_file}" "${tmp_file}.err"; return 1;
  }

  if [ -s "${tmp_file}.err" ]; then
    credentials_error "${INTERNAL_USERS_FILE} has no hash entry for: $(tr '\n' ' ' < "${tmp_file}.err")"
    rm -f "${tmp_file}" "${tmp_file}.err"
    return 1
  fi

  rm -f "${tmp_file}.err"
  cat "${tmp_file}" > "${INTERNAL_USERS_FILE}" || { rm -f "${tmp_file}"; return 1; }
  rm -f "${tmp_file}"

  if grep -q "${HASH_PLACEHOLDER}" "${INTERNAL_USERS_FILE}"; then
    credentials_error "${INTERNAL_USERS_FILE} still holds accounts with no password set"
    return 1
  fi

  return 0
}

credentials_authenticate() {
  curl -sk -o /dev/null -w '%{http_code}' --max-time 15 \
    -u "$1:$2" "https://localhost:${INDEXER_PORT:-9200}/_plugins/_security/authinfo" 2>/dev/null
}

credentials_bootstrap() {
  local user missing=0

  if [ ! -f "${INTERNAL_USERS_FILE}" ]; then
    credentials_error "${INTERNAL_USERS_FILE} not found"
    return 1
  fi

  credentials_load

  for user in "${CREDENTIAL_USERS[@]}"; do
    if [ -z "${CREDENTIALS[${user}]}" ]; then
      CREDENTIALS["${user}"]=$(credentials_generate)
      missing=1
    fi
  done

  if [ "${missing}" -eq 1 ]; then
    if [ ! -d "${CREDENTIALS_DIR}" ] || [ ! -w "${CREDENTIALS_DIR}" ]; then
      credentials_error "${CREDENTIALS_DIR} is not a writable volume, so the passwords of this"
      credentials_error "deployment cannot be shared with the manager and the dashboard containers"
      return 1
    fi

    if [ -f "${CREDENTIALS_FILE}" ]; then
      credentials_store || { credentials_error "could not write ${CREDENTIALS_FILE}"; return 1; }
      credentials_log "Added the missing internal user passwords of this deployment"
    elif credentials_publish; then
      credentials_log "Generated the internal user passwords of this deployment"
      credentials_log "Log in to the Wazuh dashboard as 'admin' with: ${CREDENTIALS[admin]}"
      credentials_log "This is the only time it is printed. Read them again with 'password-tool.sh --show'."
    else
      CREDENTIALS=()
      credentials_load || { credentials_error "could not read ${CREDENTIALS_FILE}"; return 1; }
      credentials_log "Using the internal user passwords published by another Wazuh indexer node"
    fi
  fi

  credentials_write_users
}
