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
  [extensions.pci]=$EXTENSIONS_PCI
  [extensions.gdpr]=$EXTENSIONS_GDPR
  [extensions.hipaa]=$EXTENSIONS_HIPAA
  [extensions.nist]=$EXTENSIONS_NIST
  [extensions.tsc]=$EXTENSIONS_TSC
  [extensions.audit]=$EXTENSIONS_AUDIT
  [extensions.oscap]=$EXTENSIONS_OSCAP
  [extensions.ciscat]=$EXTENSIONS_CISCAT
  [extensions.aws]=$EXTENSIONS_AWS
  [extensions.gcp]=$EXTENSIONS_GCP
  [extensions.github]=$EXTENSIONS_GITHUB
  [extensions.office]=$EXTENSIONS_OFFICE
  [extensions.virustotal]=$EXTENSIONS_VIRUSTOTAL
  [extensions.osquery]=$EXTENSIONS_OSQUERY
  [extensions.docker]=$EXTENSIONS_DOCKER
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


grep -q 1513629884013 $dashboard_config_file
_config_exists=$?

if [[ $_config_exists -ne 0 ]]; then
cat << EOF >> $dashboard_config_file
hosts:
  - 1513629884013:
      url: $wazuh_url
      port: $wazuh_port
      username: $api_username
      password: $api_password
      run_as: $api_run_as
EOF
else
  echo "Wazuh APP already configured"
fi

