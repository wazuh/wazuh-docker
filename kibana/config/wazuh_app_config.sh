#!/bin/bash
# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)

wazuh_url="${WAZUH_API_URL:-https://wazuh}"
wazuh_port="${API_PORT:-55000}"
api_user="${API_USER:-foo}"
api_password="${API_PASS:-bar}"

kibana_config_file="/usr/share/kibana/optimize/wazuh/config/wazuh.yml"
mkdir -p /usr/share/kibana/optimize/wazuh/config/
touch $kibana_config_file

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

# remove default API entry (new in 3.11.0_7.5.1)
sed -ie '/- default:/,+4d' $kibana_config_file

CONFIG_CODE=$(curl -s -o /dev/null -w "%{http_code}" -XGET $el_url/.wazuh/_doc/1513629884013 ${auth})

grep -q 1513629884013 $kibana_config_file
_config_exists=$?

if [[ "x$CONFIG_CODE" != "x200" && $_config_exists -ne 0 ]]; then
cat << EOF > $kibana_config_file
hosts:
  - 1513629884013:
      url: $wazuh_url
      port: $wazuh_port
      user: $api_user
      password: $api_password
EOF
else
  echo "Wazuh APP already configured"
fi
