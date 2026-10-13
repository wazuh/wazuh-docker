#!/bin/bash
# Wazuh App Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Changes the passwords of the Wazuh API users of this manager node, and prints
# the new ones with the commands that apply them to the dashboard and to
# config/credentials/*.env. It stores nothing itself.
# See docs/ref/credentials.md.

set -o pipefail

USERS=(wazuh wazuh-internal-client)

# Where each account is recorded (config/credentials/<file>.env) and which
# component stores it.
declare -A ENV_KEY=([wazuh]="WAZUH_MANAGER_API_PASSWORD" [wazuh-internal-client]="WAZUH_MANAGER_WUI_PASSWORD")
declare -A ENV_FILES=([wazuh]="manager" [wazuh-internal-client]="manager dashboard")
declare -A CONSUMERS=([wazuh-internal-client]="dashboard:wazuh_core.hosts.default.password")

RBAC_DB="/var/wazuh-manager/api/configuration/security/rbac.db"

error() {
  echo "password-tool.sh: $*" >&2
}

# Password generation and policy come from the credentials library the
# package ships, the same one its resolver uses.
CREDENTIALS_LIB="/var/wazuh-manager/lib/wazuh-credentials.sh"
if ! . "${CREDENTIALS_LIB}" 2>/dev/null || ! declare -F wazuh_password_generate >/dev/null; then
  error "cannot load ${CREDENTIALS_LIB}"
  exit 1
fi

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

# A library older than the four-class policy may produce a password without a
# symbol, so every candidate goes through validate_password.
generate_password() {
  local candidate attempt
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    candidate=$(wazuh_password_generate) || return 1
    if validate_password "${candidate}" 2>/dev/null; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

# The rules the package resolvers apply, so a rotated password is one every
# component would also accept at start: only the characters the library
# generates, the library's policy, the four classes it requires since
# wazuh-installation-assistant#1047 (checked here too, because an older
# library in a package does not), and no value the dashboard keystore would
# store as a number.
validate_password() {
  local password=$1 reason
  if [ -n "$(printf '%s' "${password}" | LC_ALL=C tr -d 'A-Za-z0-9.,_+:@%^=~-')" ]; then
    error "only A-Z a-z 0-9 . , _ + : @ % ^ = ~ - are allowed"
    return 1
  fi
  if ! reason=$(wazuh_password_validate "${password}" 2>&1); then
    error "${reason#wazuh-credentials: }"
    return 1
  fi
  case ${password} in *[abcdefghijklmnopqrstuvwxyz]*) ;; *) error "password must contain at least one lowercase letter"; return 1 ;; esac
  case ${password} in *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]*) ;; *) error "password must contain at least one uppercase letter"; return 1 ;; esac
  case ${password} in *[0123456789]*) ;; *) error "password must contain at least one digit"; return 1 ;; esac
  case ${password} in *[.,_+:@%^=~-]*) ;; *) error "password must contain at least one symbol from . , _ + : @ % ^ = ~ -"; return 1 ;; esac
  if printf '%s' "${password}" | grep -Eq '^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$'; then
    error "the dashboard keystore would store this value as a number"
    return 1
  fi
}

# How a rotated password reaches the rest of the deployment. The other
# components keep the value they stored at their first start (their keystore
# wins over the environment), so recreating them is not enough: each one that
# consumes the account gets the new value in its keystore and is restarted.
# config/credentials/*.env is the operator's record, updated so a deployment
# started from scratch uses the same passwords.
print_follow_up() {
  local user password key files consumer
  echo "Apply the new passwords to the rest of the deployment, from the directory of"
  echo "its docker-compose.yml:"
  echo
  for user in "${selected[@]}"; do
    password=${NEW_PASSWORD[${user}]}
    key=${ENV_KEY[${user}]}
    echo "  ${user}:"
    for files in ${ENV_FILES[${user}]}; do
      printf "    sed -i 's|^%s=.*|%s=%s|' config/credentials/%s.env\n" "${key}" "${key}" "${password}" "${files}"
    done
    for consumer in ${CONSUMERS[${user}]}; do
      case "${consumer}" in
        dashboard:*)
          printf "    printf '%%s' '%s' | docker compose exec -T wazuh.dashboard runuser -u wazuh-dashboard -- /usr/share/wazuh-dashboard/bin/opensearch-dashboards-keystore add -f --stdin %s\n" "${password}" "${consumer#dashboard:}"
          echo "    docker compose restart wazuh.dashboard"
          ;;
        manager:indexer)
          printf "    printf '%%s' '%s' | docker compose exec -T wazuh.manager /var/wazuh-manager/bin/wazuh-manager-keystore -f indexer -k password\n" "${password}"
          echo "    docker compose restart wazuh.manager"
          ;;
      esac
    done
    echo
  done
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

# Before the first start there is no user database: 1-credentials creates it
# from config/credentials/manager.env. Opening it here would create one with the
# defaults, which the first start would then take as already seeded.
# A worker never has one: the Wazuh API runs on the master.
if [ ! -s "${RBAC_DB}" ] && \
   [ "$(/var/wazuh-manager/bin/wazuh-manager-conf get cluster.node_type 2>/dev/null)" = "worker" ]; then
  error "this node is a cluster worker and has no Wazuh API user database;"
  error "change the passwords on the master node"
  exit 1
fi
if [ ! -s "${RBAC_DB}" ]; then
  error "the Wazuh API user database does not exist yet; the first start of the"
  error "manager creates it with the passwords in config/credentials/manager.env"
  exit 1
fi

declare -A NEW_PASSWORD=()

if [ "${from_stdin}" -eq 1 ]; then
  if [ "${target}" = "all" ]; then
    error "--stdin changes one account; it would give every account the same password"
    exit 2
  fi

  IFS= read -r password
  if ! validate_password "${password}"; then
    exit 2
  fi
  NEW_PASSWORD["${selected[0]}"]="${password}"
else
  for user in "${selected[@]}"; do
    if ! NEW_PASSWORD["${user}"]=$(generate_password); then
      error "could not generate a password for '${user}'"
      exit 1
    fi
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
  printf '  %-22s %s\n' "${user}" "${NEW_PASSWORD[${user}]}"
done
echo
echo "This is the only time these passwords are shown. Nothing is stored."
echo

print_follow_up

echo "On a cluster, only the master has a Wazuh API user database. A worker that is"
echo "promoted to master creates its own from config/credentials/manager.env when its"
echo "container is recreated, so keep that file updated with the commands above."
