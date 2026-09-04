#!/bin/bash
# Wazuh App Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Reads, verifies and changes the passwords of the Wazuh API users of this
# deployment. See docs/ref/credentials.md.

set -o pipefail

source /etc/wazuh-credentials.sh

usage() {
  cat <<USAGE
Usage: password-tool.sh <action>

  --show                 Print the account and password of every Wazuh API user.
  --verify               Check every account against this node's user database.
  -u, --user <account>   Change the password of one account.
  -a, --all              Change the password of every account.
  --apply                Apply the recorded passwords to this node's user
                         database, without changing them. Use it on the other
                         manager nodes of a cluster.
  --stdin                Read the new password from standard input instead of
                         generating one. Only with --user.
  -h, --help             Show this help.

Accounts: ${WAZUH_API_USERS[*]}
USAGE
}

action=""
target=""
from_stdin=0

while [ -n "$1" ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --show) action="show"; shift ;;
    --verify) action="verify"; shift ;;
    --apply) action="apply"; shift ;;
    -a|--all) action="change"; target="all"; shift ;;
    -u|--user) action="change"; target="$2"; shift 2 ;;
    --stdin) from_stdin=1; shift ;;
    *) usage >&2; exit 2 ;;
  esac
done

[ -n "${action}" ] || { usage >&2; exit 2; }

if ! credentials_api_load; then
  credentials_error "no Wazuh API credentials recorded for this deployment (${WAZUH_API_CREDENTIALS_FILE})"
  exit 1
fi

selected=()
if [ "${target}" = "all" ]; then
  selected=("${WAZUH_API_USERS[@]}")
elif [ -n "${target}" ]; then
  for user in "${WAZUH_API_USERS[@]}"; do
    [ "${user}" = "${target}" ] && selected=("${user}")
  done
  if [ "${#selected[@]}" -eq 0 ]; then
    credentials_error "unknown account '${target}'. Accounts: ${WAZUH_API_USERS[*]}"
    exit 2
  fi
fi

case "${action}" in
  show)
    for user in "${WAZUH_API_USERS[@]}"; do
      printf '%-16s %s\n' "${user}" "${WAZUH_API_PASSWORDS[${user}]}"
    done
    exit 0
    ;;

  verify)
    args=()
    for user in "${WAZUH_API_USERS[@]}"; do
      args+=("${user}=${WAZUH_API_PASSWORDS[${user}]}")
    done
    ( cd /var/wazuh-manager && \
      WAZUH_API_CREDENTIALS="$(printf '%s\n' "${args[@]}")" \
      /var/wazuh-manager/framework/python/bin/python3 /etc/wazuh-api-users.py --verify )
    exit $?
    ;;

  apply)
    credentials_api_apply || exit 1
    exec "$0" --verify
    ;;
esac

if [ "${from_stdin}" -eq 1 ]; then
  if [ "${target}" = "all" ]; then
    credentials_error "--stdin changes one account; it would give every account the same password"
    exit 2
  fi

  IFS= read -r new_password
  if ! credentials_validate "${new_password}"; then
    credentials_error "the password must be 8 to 64 characters and contain an upper case letter,"
    credentials_error "a lower case letter, a digit and one of '.*+?-'"
    exit 2
  fi
fi

for user in "${selected[@]}"; do
  if [ "${from_stdin}" -eq 1 ]; then
    WAZUH_API_PASSWORDS["${user}"]="${new_password}"
  else
    WAZUH_API_PASSWORDS["${user}"]=$(credentials_generate)
  fi
done

credentials_api_store || { credentials_error "could not write ${WAZUH_API_CREDENTIALS_FILE}"; exit 1; }
credentials_api_apply || exit 1

failed=0
for user in "${selected[@]}"; do
  printf '  %-16s %s\n' "${user}" "${WAZUH_API_PASSWORDS[${user}]}"
done

args=()
for user in "${WAZUH_API_USERS[@]}"; do
  args+=("${user}=${WAZUH_API_PASSWORDS[${user}]}")
done
( cd /var/wazuh-manager && \
  WAZUH_API_CREDENTIALS="$(printf '%s\n' "${args[@]}")" \
  /var/wazuh-manager/framework/python/bin/python3 /etc/wazuh-api-users.py --verify ) || failed=1

for user in "${selected[@]}"; do
  [ "${user}" = "wazuh-wui" ] && \
    credentials_log "Restart the dashboard container so it reads the new password: docker compose restart wazuh.dashboard"
done
credentials_log "On a cluster, restart the other manager nodes, or run 'password-tool.sh --apply' on each."

exit "${failed}"
