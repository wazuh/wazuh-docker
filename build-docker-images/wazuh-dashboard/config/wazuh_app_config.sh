#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

declare -A CONFIG_MAP=(
  [url]=$WAZUH_API_URL
  [port]=$API_PORT
  [username]=$API_USERNAME
  [password]=$API_PASSWORD
  [run_as]=$RUN_AS
  [pattern]=$PATTERN
  [checks.pattern]=$CHECKS_PATTERN
  [checks.template]=$CHECKS_TEMPLATE
  [checks.api]=$CHECKS_API
  [checks.setup]=$CHECKS_SETUP
  [timeout]=$APP_TIMEOUT
  [api.selector]=$API_SELECTOR
  [ip.selector]=$IP_SELECTOR
  [ip.ignore]=$IP_IGNORE
  [wazuh.monitoring.enabled]=$WAZUH_MONITORING_ENABLED
  [wazuh.monitoring.frequency]=$WAZUH_MONITORING_FREQUENCY
  [wazuh.monitoring.shards]=$WAZUH_MONITORING_SHARDS
  [wazuh.monitoring.replicas]=$WAZUH_MONITORING_REPLICAS

)

for i in "${!CONFIG_MAP[@]}"
do
    if [ "${CONFIG_MAP[$i]}" != "" ]; then
        sed -i 's/.*#'"$i"'.*/'"$i"': '"${CONFIG_MAP[$i]}"'/' $OPENSEARCH_DASHBOARDS_CONFIG
    fi
done
