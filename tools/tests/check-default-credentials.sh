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
  sed -n '3,22p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ -n "$1" ]; do
  case "$1" in
    -h|--help) usage 0 ;;
    -f|--file) COMPOSE_FILE="$2"; shift 2 ;;
    -i|--indexer) INDEXER_SERVICE="$2"; shift 2 ;;
    -a|--api-url) API_URL="$2"; shift 2 ;;
    *) usage 1 ;;
  esac
done

compose() { docker compose -f "${COMPOSE_FILE}" "$@"; }

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

################################################################################
info ""
info "The Wazuh indexer image"
################################################################################

image=$(compose config --format json 2>/dev/null \
  | sed -n "s/.*\"${INDEXER_SERVICE//./\\.}\"[^}]*\"image\":[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1)
[ -n "${image}" ] || image=$(compose config 2>/dev/null | awk -v s="  ${INDEXER_SERVICE}:" '
  $0 == s {found=1; next} found && /^    image:/ {print $2; exit}')

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
    code=$(indexer_auth_code "${user}" "${user}")
    if [ -z "${code}" ] || [ "${code}" = "000" ]; then
      # Everything here is a check that a password is refused, and a cluster
      # that answers nothing would pass all of them.
      fail "${INDEXER_SERVICE} did not answer while checking '${user}'"
    elif [ "${code}" = "200" ]; then
      fail "${user} authenticates with '${user}' as its password"
    else
      pass "${user} is refused with '${user}' as its password (HTTP ${code})"
    fi
  done
fi

################################################################################
info ""
info "Wazuh API accounts (${API_URL})"
################################################################################

for user in ${API_USERS}; do
  code=$(api_auth_code "${user}" "${user}")
  if [ -z "${code}" ] || [ "${code}" = "000" ]; then
    fail "no answer from ${API_URL} while checking '${user}'; pass --api-url if it is published elsewhere"
  elif [ "${code}" = "200" ]; then
    fail "${user} authenticates with '${user}' as its password"
  else
    pass "${user} is refused with '${user}' as its password (HTTP ${code})"
  fi
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
