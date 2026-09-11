#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Asserts that no account of a deployment authenticates with its own username
# as its password, and that the Wazuh indexer image carries none of the
# OpenSearch demo accounts.
#
# The images ship documented default passwords, so a deployment that has not
# been through the first-start password change fails this check. That is what
# it is for: see docs/ref/credentials.md.
#
# The Wazuh API accounts are checked twice: over HTTP on the published API, and
# in the RBAC database of every manager node. Only the second one sees a worker
# that was left on the defaults, because the API answers on the master alone.
#
# Usage, from single-node/ or multi-node/:
#
#   ../tools/tests/check-default-credentials.sh
#
# Options:
#   -f, --file <compose file>   Compose file to use. Default: docker-compose.yml
#   -i, --indexer <service>     Indexer service. Default: guessed from the file
#   -a, --api-url <url>         Wazuh API base URL. Default: https://localhost:55000

set -o pipefail

COMPOSE_FILE="docker-compose.yml"
INDEXER_SERVICE=""
API_URL="https://localhost:55000"

# Accounts OpenSearch ships for its demo configuration. None of them has a role
# in a Wazuh deployment and the image must not contain them at all.
DEMO_USERS="anomalyadmin kibanaro logstash readall snapshotrestore"

# Accounts the Wazuh indexer image keeps.
INDEXER_USERS="admin kibanaserver wazuh-manager wazuh-admin wazuh-readonly wazuh-demo"

# Accounts the Wazuh API seeds its user database with.
API_USERS="wazuh wazuh-wui"

failures=0
checks=0

pass() { checks=$((checks + 1)); printf '  \033[32mok\033[0m    %s\n' "$1"; }
fail() { checks=$((checks + 1)); failures=$((failures + 1)); printf '  \033[31mFAIL\033[0m  %s\n' "$1"; }
info() { printf '%s\n' "$1"; }

usage() {
  awk 'NR > 2 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "$0"
  exit "${1:-0}"
}

while [ -n "$1" ]; do
  case "$1" in
    -h|--help) usage 0 ;;
    -f|--file) COMPOSE_FILE="$2"; shift 2 ;;
    -i|--indexer) INDEXER_SERVICE="$2"; shift 2 ;;
    -a|--api-url) API_URL="$2"; shift 2 ;;
    *) usage 2 ;;
  esac
done

compose() { docker compose -f "${COMPOSE_FILE}" "$@"; }

# One "service<TAB>image" line per service of the Compose file, read from the
# resolved configuration so extends, overrides and variables are already
# applied.
service_images() {
  compose config 2>/dev/null | awk '
    /^[^[:space:]]/ { services = ($0 == "services:"); service = ""; next }
    !services { next }
    /^  [^[:space:]][^:]*:[[:space:]]*$/ {
      service = $0; sub(/^  /, "", service); sub(/:[[:space:]]*$/, "", service); next
    }
    /^    image:[[:space:]]/ && service != "" { print service "\t" $2 }
  '
}

if [ ! -f "${COMPOSE_FILE}" ]; then
  echo "check-default-credentials: ${COMPOSE_FILE} not found. Run this from single-node/ or multi-node/." >&2
  exit 2
fi

if [ -z "${INDEXER_SERVICE}" ]; then
  for candidate in wazuh.indexer wazuh1.indexer; do
    if compose ps --services 2>/dev/null | grep -qx "${candidate}"; then
      INDEXER_SERVICE="${candidate}"
      break
    fi
  done
fi

if [ -z "${INDEXER_SERVICE}" ]; then
  echo "check-default-credentials: no indexer service found in ${COMPOSE_FILE}." >&2
  exit 2
fi

# Every service running a manager image is a node whose RBAC database has to be
# checked, master and workers alike.
MANAGER_SERVICES=$(service_images | awk -F'\t' '$2 ~ /wazuh-manager/ {print $1}')

# Authenticates from inside the indexer container, so the check does not need
# the port to be published on the host, and cannot be made to pass by
# publishing it.
indexer_auth_code() {
  compose exec -T "${INDEXER_SERVICE}" \
    curl -sk -o /dev/null -w '%{http_code}' --max-time 15 \
    -u "$1:$2" 'https://localhost:9200/_plugins/_security/authinfo' 2>/dev/null
}

# POST, which is the method the endpoint accepts: a GET answers 405 whatever
# the credentials are, and a check that cannot tell a good password from a bad
# one is worse than no check.
api_auth_code() {
  curl -sk -o /dev/null -w '%{http_code}' --max-time 15 -X POST \
    -u "$1:$2" "${API_URL}/security/user/authenticate" 2>/dev/null
}

# Rate limiting is transient and says nothing about the password, so a 429 is
# retried before the check gives up on the account.
auth_code() {
  local code=""
  local attempt
  for attempt in 1 2 3; do
    code=$("$@")
    [ "${code}" = "429" ] || break
    sleep 5
  done
  printf '%s' "${code}"
}

# Prints "<account> default|changed|missing|absent" for each Wazuh API account,
# read from the RBAC database inside a manager container with the interpreter
# that has the framework. The API daemon runs on the master alone, so this is
# the only way to see the accounts of a worker.
#
# The database is opened read-only and through sqlite rather than the framework
# session manager, which creates the file when it is missing: a check must not
# change the deployment it is checking, and a node that has never served the
# API has no database to read.
api_db_state() {
  compose exec -T -w /var/wazuh-manager "$1" \
    /var/wazuh-manager/framework/python/bin/python3 - ${API_USERS} 2>/dev/null <<'PROBE'
import os
import sqlite3
import sys

try:
    from api.constants import SECURITY_PATH
    from werkzeug.security import check_password_hash

    database = os.path.join(SECURITY_PATH, "rbac.db")
    users = {}

    if os.path.exists(database):
        connection = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
        try:
            if connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'users'"
            ).fetchone():
                users = dict(connection.execute("SELECT username, password FROM users"))
        finally:
            connection.close()

    for username in sys.argv[1:]:
        if not users:
            print(username, "absent")
        elif username not in users:
            print(username, "missing")
        elif check_password_hash(users[username], username):
            print(username, "default")
        else:
            print(username, "changed")
except Exception:
    sys.exit(1)
PROBE
}

################################################################################
info ""
info "The Wazuh indexer image"
################################################################################

image=$(service_images | awk -F'\t' -v s="${INDEXER_SERVICE}" '$1 == s {print $2; exit}')

if [ -z "${image}" ]; then
  fail "could not read the indexer image name from ${COMPOSE_FILE}"
else
  users_file=$(docker run --rm --entrypoint cat "${image}" \
    /usr/share/wazuh-indexer/config/opensearch-security/internal_users.yml 2>/dev/null)

  if [ -z "${users_file}" ]; then
    fail "could not read internal_users.yml from ${image}"
  else
    for user in ${DEMO_USERS}; do
      if echo "${users_file}" | grep -q "^${user}:"; then
        fail "${image} still ships the OpenSearch demo account '${user}'"
      else
        pass "${image} does not ship the OpenSearch demo account '${user}'"
      fi
    done
  fi
fi

################################################################################
info ""
info "Wazuh indexer accounts (${INDEXER_SERVICE})"
################################################################################

if ! compose exec -T "${INDEXER_SERVICE}" true >/dev/null 2>&1; then
  fail "the ${INDEXER_SERVICE} container is not running"
else
  for user in ${INDEXER_USERS} ${DEMO_USERS}; do
    code=$(auth_code indexer_auth_code "${user}" "${user}")
    if [ -z "${code}" ] || [ "${code}" = "000" ]; then
      # Everything here is a check that a password is refused, and a cluster
      # that answers nothing would pass all of them.
      fail "${INDEXER_SERVICE} did not answer while checking '${user}'"
    elif [ "${code}" = "200" ]; then
      fail "${user} authenticates with '${user}' as its password"
    elif [ "${code}" = "401" ]; then
      pass "${user} is refused with '${user}' as its password (HTTP 401)"
    else
      # Only a 401 is a refusal. A busy cluster answers 429, and counting that
      # as a refusal would turn a deployment on the defaults into a pass.
      fail "${INDEXER_SERVICE} answered HTTP ${code} while checking '${user}', which is neither a refusal nor an acceptance"
    fi
  done
fi

################################################################################
info ""
info "Wazuh API accounts (${API_URL})"
################################################################################

for user in ${API_USERS}; do
  code=$(auth_code api_auth_code "${user}" "${user}")
  if [ -z "${code}" ] || [ "${code}" = "000" ]; then
    fail "no answer from ${API_URL} while checking '${user}'; pass --api-url if it is published elsewhere"
  elif [ "${code}" = "200" ]; then
    fail "${user} authenticates with '${user}' as its password"
  elif [ "${code}" = "401" ]; then
    pass "${user} is refused with '${user}' as its password (HTTP 401)"
  else
    fail "${API_URL} answered HTTP ${code} while checking '${user}', which is neither a refusal nor an acceptance"
  fi
done

################################################################################
info ""
info "Wazuh API accounts of each manager node"
################################################################################

if [ -z "${MANAGER_SERVICES}" ]; then
  fail "no manager service found in ${COMPOSE_FILE}"
fi

for service in ${MANAGER_SERVICES}; do
  if ! compose exec -T "${service}" true >/dev/null 2>&1; then
    fail "the ${service} container is not running"
    continue
  fi

  db_state=$(api_db_state "${service}")
  if [ -z "${db_state}" ]; then
    fail "could not read the Wazuh API user database of ${service}"
    continue
  fi

  for user in ${API_USERS}; do
    case "$(printf '%s\n' "${db_state}" | awk -v u="${user}" '$1 == u {print $2}')" in
      changed) pass "${service}: ${user} does not have '${user}' as its password" ;;
      default) fail "${service}: ${user} has '${user}' as its password" ;;
      missing) fail "${service}: ${user} is not in the Wazuh API user database" ;;
      absent)  fail "${service}: no Wazuh API user database, so ${user} would be seeded with '${user}' as its password" ;;
      *)       fail "${service}: could not read the state of '${user}'" ;;
    esac
  done
done

info ""
if [ "${failures}" -eq 0 ]; then
  info "${checks} checks, all passed."
  exit 0
fi
info "${checks} checks, ${failures} failed."
info "A deployment that has not been through the first-start password change fails here."
info "See docs/ref/credentials.md."
exit 1
