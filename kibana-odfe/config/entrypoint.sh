#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

set -e

##############################################################################
# Waiting for elasticsearch
##############################################################################

if [ "x${ELASTICSEARCH_URL}" == "x" ]; then
  if [[ ${ENABLED_SECURITY} == "false" ]]; then
    export el_url="http://elasticsearch:9200"
  else
    export el_url="https://elasticsearch:9200"
  fi
else
  export el_url="${ELASTICSEARCH_URL}"
fi

if [[ ${ENABLED_SECURITY} == "false" || "x${ELASTICSEARCH_USERNAME}" == "x" || "x${ELASTICSEARCH_PASSWORD}" == "x" ]]; then
  auth=""
  # remove security plugin from kibana if elasticsearch is not using it either
  /usr/share/kibana/bin/kibana-plugin remove opendistro_security
else
  export auth="--user ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD} -k"
fi

until curl -XGET $el_url ${auth}; do
  >&2 echo "Elastic is unavailable - sleeping"
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
  template=$(curl ${auth} $el_url/_cat/templates/wazuh -s)
  strlen=${#template}
  >&2 echo "Wazuh alerts template not loaded - sleeping."
  sleep 2
done

sleep 2

>&2 echo "Wazuh alerts template is loaded."


./wazuh_app_config.sh

sleep 5

./kibana_settings.sh &

sleep 2

/usr/local/bin/kibana-docker
