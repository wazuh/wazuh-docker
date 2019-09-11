#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

kibana_config_file="/usr/share/kibana/plugins/wazuh/config.yml"

declare -A CONFIG_MAP=(
  [pattern]=$PATTERN
  [checks.pattern]=$CHECKS_PATTERN
  [checks.template]=$CHECKS_TEMPLATE
  [checks.api]=$CHECKS_API
  [checks.setup]=$CHECKS_SETUP
  [extensions.pci]=$EXTENSIONS_PCI
  [extensions.gdpr]=$EXTENSIONS_GDPR
  [extensions.audit]=$EXTENSIONS_AUDIT
  [extensions.oscap]=$EXTENSIONS_OSCAP
  [extensions.ciscat]=$EXTENSIONS_CISCAT
  [extensions.aws]=$EXTENSIONS_AWS
  [extensions.virustotal]=$EXTENSIONS_VIRUSTOTAL
  [extensions.osquery]=$EXTENSIONS_OSQUERY
  [timeout]=$APP_TIMEOUT
  [wazuh.shards]=$WAZUH_SHARDS
  [wazuh.replicas]=$WAZUH_REPLICAS
  [wazuh-version.shards]=$WAZUH_VERSION_SHARDS
  [wazuh-version.replicas]=$WAZUH_VERSION_REPLICAS
  [ip.selector]=$IP_SELECTOR
  [ip.ignore]=$IP_IGNORE
  [xpack.rbac.enabled]=$XPACK_RBAC_ENABLED
  [wazuh.monitoring.enabled]=$WAZUH_MONITORING_ENABLED
  [wazuh.monitoring.frequency]=$WAZUH_MONITORING_FREQUENCY
  [wazuh.monitoring.shards]=$WAZUH_MONITORING_SHARDS
  [wazuh.monitoring.replicas]=$WAZUH_MONITORING_REPLICAS
  [admin]=$ADMIN_PRIVILEGES
)

for i in "${!CONFIG_MAP[@]}"
do
    if [ "${CONFIG_MAP[$i]}" != "" ]; then
        sed -i 's/.*#'"$i"'.*/'"$i"': '"${CONFIG_MAP[$i]}"'/' $kibana_config_file
    fi
done
