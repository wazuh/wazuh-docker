#!/bin/bash
# Wazuh App Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Changes the passwords of the Wazuh API users of this manager node and prints
# the new ones. It stores nothing: the passwords are shown once and the
# operator writes the service one into docker-compose.yml.
# See docs/ref/credentials.md.

set -o pipefail

USERS=(wazuh wazuh-wui)

# The Compose service and variable each service account has to be copied into.
declare -A COMPOSE_SERVICE=([wazuh-wui]="wazuh.dashboard")
declare -A COMPOSE_VARIABLE=([wazuh-wui]="API_PASSWORD")

error() {
  echo "password-tool.sh: $*" >&2
}

usage() {
  cat <<USAGE
Usage: password-tool.sh <action>

  -a, --all              Change the password of every account.
  -u, --user <account>   Change the password of one account.
  --stdin                Read the new password from standard input instead of
                         generating one. Only with --user. Use it to set the
                         same password on the other manager nodes of a cluster.
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

credentials=""
for user in "${selected[@]}"; do
  credentials="${credentials}${user}=${NEW_PASSWORD[${user}]}"$'\n'
done

if ! ( cd /var/wazuh-manager && \
       WAZUH_API_CREDENTIALS="${credentials}" \
       /var/wazuh-manager/framework/python/bin/python3 /etc/wazuh-api-users.py ); then
  exit 1
fi

echo
echo "Changed on this manager node:"
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

echo "The Wazuh API user database is local to each manager node. On a cluster,"
echo "set the same passwords on the other nodes:"
echo
for user in "${selected[@]}"; do
  printf "  printf '%%s\\\\n' '%s' | docker compose exec -T <node> /password-tool.sh --user %s --stdin\n" \
    "${NEW_PASSWORD[${user}]}" "${user}"
done
echo
