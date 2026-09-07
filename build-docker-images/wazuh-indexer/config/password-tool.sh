#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Changes the passwords of the Wazuh indexer internal users of the running
# deployment and prints the new ones. It stores nothing: the passwords are
# shown once and the operator writes the service ones into docker-compose.yml.
# See docs/ref/credentials.md.

set -o pipefail

OPENSEARCH_HOME="${OPENSEARCH_HOME:-/usr/share/wazuh-indexer}"
OPENSEARCH_PATH_CONF="${OPENSEARCH_PATH_CONF:-${OPENSEARCH_HOME}/config}"
HASH_TOOL="${OPENSEARCH_HOME}/plugins/opensearch-security/tools/hash.sh"

USERS=(admin kibanaserver wazuh-manager wazuh-admin wazuh-readonly wazuh-demo)

# The Compose service and variable each service account has to be copied into.
declare -A COMPOSE_SERVICE=([kibanaserver]="wazuh.dashboard" [wazuh-manager]="wazuh.manager")
declare -A COMPOSE_VARIABLE=([kibanaserver]="DASHBOARD_PASSWORD" [wazuh-manager]="INDEXER_PASSWORD")

error() {
  echo "password-tool.sh: $*" >&2
}

usage() {
  cat <<USAGE
Usage: password-tool.sh <action>

  -a, --all              Change the password of every account.
  -u, --user <account>   Change the password of one account.
  --stdin                Read the new password from standard input instead of
                         generating one. Only with --user.
  -h, --help             Show this help.

Accounts: ${USERS[*]}
USAGE
}

generate_password() {
  local body special lower upper digit
  body=$(tr -dc 'A-Za-z0-9.*+?-' < /dev/urandom | head -c 28)
  special=$(tr -dc '.*+?-' < /dev/urandom | head -c 1)
  lower=$(tr -dc 'a-z' < /dev/urandom | head -c 1)
  upper=$(tr -dc 'A-Z' < /dev/urandom | head -c 1)
  digit=$(tr -dc '0-9' < /dev/urandom | head -c 1)
  echo "${body}${special}${lower}${upper}${digit}" | fold -w1 | shuf | tr -d '\n'
}

validate_password() {
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
hash_password() {
  local output
  output=$(WAZUH_PASSWORD_TO_HASH="$1" \
    OPENSEARCH_JAVA_HOME="${OPENSEARCH_JAVA_HOME:-${OPENSEARCH_HOME}/jdk}" \
    JAVA_HOME="${JAVA_HOME:-${OPENSEARCH_HOME}/jdk}" \
    OPENSEARCH_PATH_CONF="${OPENSEARCH_PATH_CONF}" \
    bash "${HASH_TOOL}" -env WAZUH_PASSWORD_TO_HASH 2>/dev/null | grep -E '^\$2[aby]\$' | tail -n1)

  [ -n "${output}" ] || return 1
  echo "${output}"
}

target=""
from_stdin=0

while [ -n "$1" ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -a|--all) target="all"; shift ;;
    -u|--user) target="$2"; shift 2 ;;
    --stdin) from_stdin=1; shift ;;
    *) usage >&2; exit 2 ;;
  esac
done

[ -n "${target}" ] || { usage >&2; exit 2; }

selected=()
if [ "${target}" = "all" ]; then
  selected=("${USERS[@]}")
else
  for user in "${USERS[@]}"; do
    [ "${user}" = "${target}" ] && selected=("${user}")
  done
  if [ "${#selected[@]}" -eq 0 ]; then
    error "unknown account '${target}'. Accounts: ${USERS[*]}"
    exit 2
  fi
fi

declare -A NEW_PASSWORD=()

if [ "${from_stdin}" -eq 1 ]; then
  if [ "${target}" = "all" ]; then
    error "--stdin changes one account; it would give every account the same password"
    exit 2
  fi

  IFS= read -r password
  if ! validate_password "${password}"; then
    error "the password must be 8 to 64 characters and contain an upper case letter,"
    error "a lower case letter, a digit and one of '.*+?-'"
    exit 2
  fi
  NEW_PASSWORD["${selected[0]}"]="${password}"
else
  for user in "${selected[@]}"; do
    NEW_PASSWORD["${user}"]=$(generate_password)
  done
fi

workdir=$(mktemp -d) || { error "could not create a temporary directory"; exit 1; }
trap 'rm -rf "${workdir}"' EXIT INT TERM

# A cluster that is busy answers 429 and securityadmin gives up, so every call
# to it is retried.
run_securityadmin() {
  local attempt
  for attempt in 1 2 3 4 5; do
    if "$@" /securityadmin.sh > "${workdir}/log" 2>&1; then
      return 0
    fi
    sleep 10
  done
  return 1
}

# The user database in the image is the one the cluster started from, not the
# one it is running: an account changed earlier is only in the security index.
# Take the current configuration from the cluster, change the selected hashes
# and put it back, so the accounts that are not being changed keep the password
# they have.
if ! run_securityadmin env BACKUP="${workdir}"; then
  error "could not read the user database from the cluster:"
  sed 's/^/  /' "${workdir}/log" >&2
  exit 1
fi

users_file=$(ls -1 "${workdir}"/internal_users*.yml 2>/dev/null | head -n1)
if [ -z "${users_file}" ]; then
  error "the cluster returned no user database"
  exit 1
fi

pairs=""
for user in "${selected[@]}"; do
  if ! hash=$(hash_password "${NEW_PASSWORD[${user}]}"); then
    error "could not hash the password of '${user}'"
    exit 1
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
' "${users_file}" > "${users_file}.new" 2> "${workdir}/missing"

if [ -s "${workdir}/missing" ]; then
  error "the cluster has no account named: $(tr '\n' ' ' < "${workdir}/missing")"
  exit 1
fi
mv "${users_file}.new" "${users_file}"

if ! run_securityadmin env FILE="${users_file}" TYPE=internalusers; then
  error "could not load the user database into the cluster:"
  sed 's/^/  /' "${workdir}/log" >&2
  exit 1
fi

echo
echo "Changed on the running deployment:"
echo
for user in "${selected[@]}"; do
  printf '  %-16s %s\n' "${user}" "${NEW_PASSWORD[${user}]}"
done
echo
echo "This is the only time these passwords are shown. Nothing is stored."
echo

needs_compose=0
for user in "${selected[@]}"; do
  [ -n "${COMPOSE_VARIABLE[${user}]}" ] && needs_compose=1
done

if [ "${needs_compose}" -eq 1 ]; then
  echo "Write these into docker-compose.yml, then take the stack down and up,"
  echo "or those components keep authenticating with the old values:"
  echo
  for user in "${selected[@]}"; do
    [ -n "${COMPOSE_VARIABLE[${user}]}" ] || continue
    printf '  service %s:\n' "${COMPOSE_SERVICE[${user}]}"
    printf '    - %s=%s\n' "${COMPOSE_VARIABLE[${user}]}" "${NEW_PASSWORD[${user}]}"
  done
  echo
fi
