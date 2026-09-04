#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Asserts that no account of a deployment authenticates with a password that
# can be known before the deployment exists.
#
# Three things are checked, and each of them has been true of a shipped image
# at some point, which is why they are checked and not assumed:
#
#   1. The Wazuh indexer image carries no usable password hash, and none of the
#      OpenSearch demo accounts.
#   2. No Wazuh indexer account authenticates with its own username as its
#      password, and neither do the OpenSearch demo accounts.
#   3. No Wazuh API account authenticates with its own username as its
#      password.
#
# A deployment credential is used at the end as a positive control: a check
# that only ever says "denied" would also pass against a cluster that is down.
#
# Usage, from single-node/ or multi-node/:
#
#   ../tools/tests/check-default-credentials.sh
#
# Options:
#   -f, --file <compose file>   Compose file to use. Default: docker-compose.yml
#   -i, --indexer <service>     Indexer service. Default: guessed from the file
#   -m, --manager <service>     Manager service. Default: guessed from the file
#   -a, --api-url <url>         Wazuh API base URL. Default: https://localhost:55000

set -o pipefail

COMPOSE_FILE="docker-compose.yml"
INDEXER_SERVICE=""
MANAGER_SERVICE=""
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
  sed -n '3,28p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ -n "$1" ]; do
  case "$1" in
    -h|--help) usage 0 ;;
    -f|--file) COMPOSE_FILE="$2"; shift 2 ;;
    -i|--indexer) INDEXER_SERVICE="$2"; shift 2 ;;
    -m|--manager) MANAGER_SERVICE="$2"; shift 2 ;;
    -a|--api-url) API_URL="$2"; shift 2 ;;
    *) usage 1 ;;
  esac
done

compose() { docker compose -f "${COMPOSE_FILE}" "$@"; }

if [ ! -f "${COMPOSE_FILE}" ]; then
  echo "check-default-credentials: ${COMPOSE_FILE} not found. Run this from single-node/ or multi-node/." >&2
  exit 2
fi

# The two deployments name their services differently.
if [ -z "${INDEXER_SERVICE}" ]; then
  for candidate in wazuh.indexer wazuh1.indexer; do
    if compose ps --services 2>/dev/null | grep -qx "${candidate}"; then
      INDEXER_SERVICE="${candidate}"
      break
    fi
  done
fi
if [ -z "${MANAGER_SERVICE}" ]; then
  for candidate in wazuh.manager wazuh.master; do
    if compose ps --services 2>/dev/null | grep -qx "${candidate}"; then
      MANAGER_SERVICE="${candidate}"
      break
    fi
  done
fi

if [ -z "${INDEXER_SERVICE}" ]; then
  echo "check-default-credentials: no indexer service found in ${COMPOSE_FILE}." >&2
  exit 2
fi

# Authenticates against the indexer from inside the indexer container, so the
# check does not need the port to be published on the host, and cannot be made
# to pass by publishing it.
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

    if echo "${users_file}" | grep -qE '^[[:space:]]+hash:[[:space:]]*"\$2'; then
      fail "${image} ships a usable password hash in internal_users.yml"
    else
      pass "${image} ships no usable password hash"
    fi
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
    if [ "${code}" = "200" ]; then
      fail "${user} authenticates with '${user}' as its password (HTTP ${code})"
    else
      pass "${user} is refused with '${user}' as its password (HTTP ${code:-no answer})"
    fi
  done
fi

################################################################################
info ""
info "Wazuh API accounts (${API_URL})"
################################################################################

if [ -z "$(api_auth_code probe probe)" ]; then
  fail "no answer from ${API_URL}; pass --api-url if it is published elsewhere"
else
  for user in ${API_USERS}; do
    code=$(api_auth_code "${user}" "${user}")
    if [ "${code}" = "200" ]; then
      fail "${user} authenticates with '${user}' as its password (HTTP ${code})"
    else
      pass "${user} is refused with '${user}' as its password (HTTP ${code})"
    fi
  done
fi

################################################################################
info ""
info "Positive control"
################################################################################

# Everything above is a check that a password is refused, and a cluster that
# refuses everything would pass all of it. The credential this deployment did
# generate has to work.
# The password recorded for the deployment on the shared credentials volume.
read_deployment_password() {
  compose exec -T "$1" \
    sh -c "sed -n \"s/^$3='\\(.*\\)'\$/\\1/p\" $2" 2>/dev/null | tr -d '\r\n'
}

admin_password=$(read_deployment_password "${INDEXER_SERVICE}" /wazuh-credentials/indexer-users.env INDEXER_ADMIN_PASSWORD)

if [ -z "${admin_password}" ]; then
  info "  skip  no indexer password recorded"
else
  code=$(indexer_auth_code admin "${admin_password}")
  if [ "${code}" = "200" ]; then
    pass "admin authenticates with the password of this deployment"
  else
    fail "admin does not authenticate with the password of this deployment (HTTP ${code})"
  fi
fi

if [ -n "${MANAGER_SERVICE}" ]; then
  api_password=$(read_deployment_password "${MANAGER_SERVICE}" /wazuh-credentials/api-users.env API_WAZUH_PASSWORD)
else
  api_password=""
fi

if [ -z "${api_password}" ]; then
  info "  skip  no API password recorded"
else
  code=$(api_auth_code wazuh "${api_password}")
  if [ "${code}" = "200" ]; then
    pass "wazuh authenticates with the API password of this deployment"
  else
    fail "wazuh does not authenticate with the API password of this deployment (HTTP ${code})"
  fi
fi

info ""
if [ "${failures}" -eq 0 ]; then
  info "${checks} checks, all passed."
  exit 0
fi
info "${checks} checks, ${failures} failed."
exit 1
