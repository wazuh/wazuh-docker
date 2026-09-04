#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Reads, verifies and changes the passwords of the Wazuh indexer internal
# users of this deployment. See docs/ref/credentials.md.

set -o pipefail

source /credentials.sh

usage() {
  cat <<USAGE
Usage: password-tool.sh <action>

  --show                 Print the account and password of every internal user.
  --verify               Authenticate every account with its recorded password.
  -u, --user <account>   Change the password of one account.
  -a, --all              Change the password of every account.
  --stdin                Read the new password from standard input instead of
                         generating one. Only with --user.
  -h, --help             Show this help.

Accounts: ${CREDENTIAL_USERS[*]}
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
    -a|--all) action="change"; target="all"; shift ;;
    -u|--user) action="change"; target="$2"; shift 2 ;;
    --stdin) from_stdin=1; shift ;;
    *) usage >&2; exit 2 ;;
  esac
done

[ -n "${action}" ] || { usage >&2; exit 2; }

if ! credentials_load; then
  credentials_error "no credentials recorded for this deployment (${CREDENTIALS_FILE})"
  exit 1
fi

selected=()
if [ "${target}" = "all" ]; then
  selected=("${CREDENTIAL_USERS[@]}")
elif [ -n "${target}" ]; then
  for user in "${CREDENTIAL_USERS[@]}"; do
    [ "${user}" = "${target}" ] && selected=("${user}")
  done
  if [ "${#selected[@]}" -eq 0 ]; then
    credentials_error "unknown account '${target}'. Accounts: ${CREDENTIAL_USERS[*]}"
    exit 2
  fi
fi

case "${action}" in
  show)
    for user in "${CREDENTIAL_USERS[@]}"; do
      printf '%-16s %s\n' "${user}" "${CREDENTIALS[${user}]}"
    done
    exit 0
    ;;

  verify)
    failed=0
    for user in "${CREDENTIAL_USERS[@]}"; do
      code=$(credentials_authenticate "${user}" "${CREDENTIALS[${user}]}")
      if [ "${code}" = "200" ]; then
        printf '  ok    %-16s\n' "${user}"
      else
        printf '  FAIL  %-16s HTTP %s\n' "${user}" "${code:-no answer}"
        failed=1
      fi
    done
    exit "${failed}"
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
    CREDENTIALS["${user}"]="${new_password}"
  else
    CREDENTIALS["${user}"]=$(credentials_generate)
  fi
done

credentials_store || { credentials_error "could not write ${CREDENTIALS_FILE}"; exit 1; }
credentials_write_users || exit 1

# internal_users.yml is read by the cluster only when the security index is
# created, so the new hashes have to be loaded into the running one.
if ! FILE="${INTERNAL_USERS_FILE}" TYPE=internalusers /securityadmin.sh > /tmp/securityadmin.$$ 2>&1; then
  credentials_error "securityadmin could not load the user database:"
  sed 's/^/  /' /tmp/securityadmin.$$ >&2
  rm -f /tmp/securityadmin.$$
  exit 1
fi
rm -f /tmp/securityadmin.$$

failed=0
for user in "${selected[@]}"; do
  code=$(credentials_authenticate "${user}" "${CREDENTIALS[${user}]}")
  if [ "${code}" = "200" ]; then
    printf '  ok    %-16s %s\n' "${user}" "${CREDENTIALS[${user}]}"
  else
    printf '  FAIL  %-16s HTTP %s\n' "${user}" "${code:-no answer}"
    failed=1
  fi
done

for user in "${selected[@]}"; do
  case "${user}" in
    kibanaserver)
      credentials_log "Restart the dashboard container so it reads the new password: docker compose restart wazuh.dashboard" ;;
    wazuh-manager)
      credentials_log "Restart the manager containers so they read the new password: docker compose restart wazuh.manager" ;;
  esac
done

exit "${failed}"
