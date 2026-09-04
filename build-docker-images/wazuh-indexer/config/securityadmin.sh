#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Loads the security configuration files of this container into the security
# index of the running cluster. Used by password-tool.sh; can also be run on
# its own. See docs/ref/credentials.md.
#
# Overridable: CACERT, CERT, KEY, HOST, PORT, FILE, TYPE, WAIT_SECONDS.

set -o pipefail

OPENSEARCH_HOME=${OPENSEARCH_HOME:-/usr/share/wazuh-indexer}
OPENSEARCH_PATH_CONF=${OPENSEARCH_PATH_CONF:-${OPENSEARCH_HOME}/config}

CACERT=${CACERT:-${OPENSEARCH_PATH_CONF}/certs/root-ca.pem}
CERT=${CERT:-${OPENSEARCH_PATH_CONF}/certs/admin.pem}
KEY=${KEY:-${OPENSEARCH_PATH_CONF}/certs/admin-key.pem}
HOST=${HOST:-localhost}
PORT=${PORT:-9200}
SECURITY_CONFIG_DIR=${SECURITY_CONFIG_DIR:-${OPENSEARCH_PATH_CONF}/opensearch-security}
WAIT_SECONDS=${WAIT_SECONDS:-120}

for file in "${CACERT}" "${CERT}" "${KEY}"; do
    if [ ! -r "${file}" ]; then
        echo "securityadmin.sh: cannot read ${file}." >&2
        echo "securityadmin.sh: set CACERT, CERT and KEY to the admin certificate of this deployment." >&2
        exit 1
    fi
done

waited=0
until curl -sk --max-time 5 "https://${HOST}:${PORT}/" >/dev/null 2>&1; do
    if [ "${waited}" -ge "${WAIT_SECONDS}" ]; then
        echo "securityadmin.sh: ${HOST}:${PORT} did not answer after ${WAIT_SECONDS}s." >&2
        exit 1
    fi
    sleep 5
    waited=$((waited + 5))
done

args=()
if [ -n "${FILE}" ]; then
    args+=(-f "${FILE}")
else
    args+=(-cd "${SECURITY_CONFIG_DIR}")
fi
[ -n "${TYPE}" ] && args+=(-t "${TYPE}")

OPENSEARCH_JAVA_HOME=${OPENSEARCH_JAVA_HOME:-${OPENSEARCH_HOME}/jdk} \
OPENSEARCH_PATH_CONF=${OPENSEARCH_PATH_CONF} \
bash "${OPENSEARCH_HOME}/plugins/opensearch-security/tools/securityadmin.sh" \
    "${args[@]}" \
    -icl -nhnv \
    -h "${HOST}" -p "${PORT}" \
    -cacert "${CACERT}" -cert "${CERT}" -key "${KEY}" \
    "$@"
