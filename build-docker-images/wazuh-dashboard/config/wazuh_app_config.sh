#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

wazuh_url="${WAZUH_API_URL:-https://wazuh}"
wazuh_port="${API_PORT:-55000}"
api_username="${API_USERNAME:-wazuh-wui}"
api_password="${API_PASSWORD:-wazuh-wui}"
api_run_as="${RUN_AS:-false}"

dashboard_config_file="/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml"

declare -A CONFIG_MAP=(
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
        sed -i 's/.*#'"$i"'.*/'"$i"': '"${CONFIG_MAP[$i]}"'/' $dashboard_config_file
    fi
done

cat << EOF >> $dashboard_config_file
hosts:
  - 1513629884013:
      url: $wazuh_url
      port: $wazuh_port
      username: $api_username
      password: $api_password
      run_as: $api_run_as
EOF

