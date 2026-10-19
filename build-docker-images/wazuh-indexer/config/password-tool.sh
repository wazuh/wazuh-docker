#!/bin/bash
# Wazuh Docker Copyright (C) Wazuh Inc. (License GPLv2)
#
# Changes the passwords of the Wazuh indexer internal users of the running
# deployment, and prints the new ones with the commands that apply them to the
# components consuming them and to config/credentials/*.env. It stores
# nothing itself. See docs/ref/credentials.md.

set -o pipefail

OPENSEARCH_HOME="${OPENSEARCH_HOME:-/usr/share/wazuh-indexer}"
OPENSEARCH_PATH_CONF="${OPENSEARCH_PATH_CONF:-${OPENSEARCH_HOME}/config}"
HASH_TOOL="${OPENSEARCH_HOME}/plugins/opensearch-security/tools/hash.sh"

USERS=(admin kibanaserver wazuh-manager)

# Where each account is recorded (config/credentials/<file>.env) and which
# component stores it: the dashboard keystore entry, or the manager keystore.
declare -A ENV_KEY=([admin]="WAZUH_INDEXER_ADMIN_PASSWORD" [kibanaserver]="WAZUH_INDEXER_KIBANASERVER_PASSWORD" [wazuh-manager]="WAZUH_INDEXER_MANAGER_PASSWORD")
declare -A ENV_FILES=([admin]="indexer" [kibanaserver]="indexer dashboard" [wazuh-manager]="indexer manager")
declare -A CONSUMERS=([kibanaserver]="dashboard:opensearch.password" [wazuh-manager]="manager:indexer")

error() {
  echo "password-tool.sh: $*" >&2
}

# Password generation and policy: the rule the package resolvers apply.
PASSWORD_POLICY="/password-policy.sh"
if ! . "${PASSWORD_POLICY}" 2>/dev/null || ! declare -F common_passwordGenerate >/dev/null; then
  error "cannot load ${PASSWORD_POLICY}"
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

# The rule the package resolvers apply (password-policy.sh), so a rotated
# password is one every component would also accept at start.
generate_password() {
  common_passwordGenerate
}

validate_password() {
  local reason
  if ! reason=$(common_passwordValidate "$1" 2>&1); then
    error "${reason}"
    return 1
  fi
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

# How a rotated password reaches the rest of the deployment. The other
# components keep the value they stored at their first start (their keystore
# wins over the environment), so recreating them is not enough: each one that
# consumes the account gets the new value in its keystore and is restarted.
# config/credentials/*.env is the operator's record, updated so a deployment
# started from scratch uses the same passwords.
print_follow_up() {
  local user password key files consumer
  echo "Apply the new passwords to the rest of the deployment, from the directory of"
  echo "its docker-compose.yml (single-node service names; in multi-node the manager"
  echo "commands go to wazuh.master and to wazuh.worker):"
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
          printf "    printf '%%s' '%s' | docker compose exec -T -e OSD_PATH_CONF=/usr/share/wazuh-dashboard/config wazuh.dashboard /usr/share/wazuh-dashboard/bin/opensearch-dashboards-keystore add --allow-root -f --stdin %s\n" "${password}" "${consumer#dashboard:}"
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

print_follow_up
