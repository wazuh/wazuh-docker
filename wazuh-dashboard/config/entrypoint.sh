#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

set -e

##############################################################################
# Waiting for Wazuh indexer
##############################################################################

if [ "x${INDEXER_URL}" == "x" ]; then
  if [[ ${ENABLED_SECURITY} == "false" ]]; then
    export idx_url="http://wazuh1.indexer:9200"
  else
    export idx_url="https://wazuh1.indexer:9200"
  fi
else
  export idx_url="${INDEXER_URL}"
fi

export auth="--user ${INDEXER_USERNAME}:${INDEXER_PASSWORD} -k"

until curl -XGET $idx_url ${auth}; do
  >&2 echo "Wazuh indexer is unavailable - sleeping"
  sleep 5
done

sleep 2

>&2 echo "Elasticsearch is up."


##############################################################################
# Waiting for wazuh alerts template
##############################################################################

strlen=0

while [[ $strlen -eq 0 ]]
do
  template=$(curl ${auth} $idx_url/_cat/templates/wazuh -s)
  strlen=${#template}
  >&2 echo "Wazuh alerts template not loaded - sleeping."
  sleep 2
done

sleep 2

>&2 echo "Wazuh alerts template is loaded."

##############################################################################
# Start Wazuh dashboard
##############################################################################

/wazuh_app_config.sh

runuser wazuh-dashboard --shell="/bin/bash" --command="/usr/share/wazuh-dashboard/bin/opensearch-dashboards -c /etc/wazuh-dashboard/opensearch_dashboards.yml"
