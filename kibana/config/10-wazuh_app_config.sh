#!/bin/bash
# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)

##############################################################################
# If Elasticsearch security is enabled get the kibana user, the Kibana 
# password and WAZUH API credentials.
##############################################################################

KIBANA_USER=""
KIBANA_PASS=""
WAZH_API_USER=""
WAZH_API_PASS=""

if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
  KIBANA_USER=${SECURITY_KIBANA_USER}
  KIBANA_PASS=${SECURITY_KIBANA_PASS}
  WAZH_API_USER=${API_USER}
  WAZH_API_PASS=${API_PASS}
  echo "USERS - Credentials obtained from environment variables."
else
  input=${SECURITY_CREDENTIALS_FILE}
  while IFS= read -r line
  do
    if [[ $line == *"KIBANA_USER"* ]]; then
      arrIN=(${line//:/ })
      KIBANA_USER=${arrIN[1]}
    elif [[ $line == *"KIBANA_PASSWORD"* ]]; then
      arrIN=(${line//:/ })
      KIBANA_PASS=${arrIN[1]}
    elif [[ $line == *"WAZUH_API_USER"* ]]; then
      arrIN=(${line//:/ })
      WAZH_API_USER=${arrIN[1]}
    elif [[ $line == *"WAZUH_API_PASSWORD"* ]]; then
      arrIN=(${line//:/ })
      WAZH_API_PASS=${arrIN[1]}
    fi
  done < "$input"
  echo "USERS - Credentials obtained from file."
fi

##############################################################################
# Establish the way to run the curl command, with or without authentication. 
##############################################################################

if [ ${SECURITY_ENABLED} != "no" ]; then
  auth="-u ${KIBANA_USER}:${KIBANA_PASS} -k"
elif [ ${ENABLED_XPACK} != "true" || "x${ELASTICSEARCH_USERNAME}" = "x" || "x${ELASTICSEARCH_PASSWORD}" = "x" ]; then
  auth=""
else
  auth="--user ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}"
fi

##############################################################################
# Set custom wazuh.yml config
##############################################################################

kibana_config_file="/usr/share/kibana/plugins/wazuh/wazuh.yml"

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

# If this is an update to 3.11
CONFIG_CODE=$(curl -s -o /dev/null -w "%{http_code}" -XGET $ELASTICSEARCH_URL/.wazuh/_doc/1513629884013 ${auth})

grep -q 1513629884013 $kibana_config_file
_config_exists=$?

if [[ "x$CONFIG_CODE" != "x200" && $_config_exists -ne 0 ]]; then
cat << EOF >> $kibana_config_file 
  - 1513629884013:
      url: $wazuh_url
      port: 55000
      user: $WAZH_API_USER
      password: $WAZH_API_PASS
EOF
else
  echo "Wazuh APP already configured"
fi
