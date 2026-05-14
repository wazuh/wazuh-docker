#!/usr/bin/env bash
# Wazuh manager bind-mounts ./wazuh-alerts-export -> /var/ossec/logs/alerts for Alloy/Loki.
# Docker creates the host directory as root; wazuh-analysisd runs as uid 999 and must
# create subdirs (e.g. 2026/) under alerts — fix ownership or analysisd stays down and the API returns 500.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="${ROOT}/wazuh-alerts-export"
OWNER="${WAZUH_ALERTS_UID:-999}:${WAZUH_ALERTS_GID:-999}"

mkdir -p "${DIR}"
if chown -R "${OWNER}" "${DIR}" 2>/dev/null; then
  echo "OK: ${DIR} -> ${OWNER}"
  exit 0
fi

echo "Could not chown ${DIR} (need root). Run:"
echo "  sudo chown -R ${OWNER} \"${DIR}\""
echo "Then: cd \"${ROOT}\" && docker compose restart wazuh.manager"
exit 1
