#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)


WAZUH_MAJOR=3

##############################################################################
# Wait for the Kibana API to start. It is necessary to do it in this container
# because the others are running Elastic Stack and we can not interrupt them. 
# 
# The following actions are performed:
#
# Add the wazuh alerts index as default.
# Set the Discover time interval to 24 hours instead of 15 minutes.
# Do not ask user to help providing usage statistics to Elastic.
##############################################################################

while [[ "$(curl -XGET -I  -s -o /dev/null -w ''%{http_code}'' kibana:5601/status)" != "200" ]]; do
  echo "Waiting for Kibana API. Sleeping 5 seconds"
  sleep 5
done

# Prepare index selection. 
echo "Kibana API is running"

default_index="/tmp/default_index.json"

cat > ${default_index} << EOF
{
  "changes": {
    "defaultIndex": "wazuh-alerts-${WAZUH_MAJOR}.x-*"
  }
}
EOF

sleep 5
# Add the wazuh alerts index as default.
curl -POST "http://kibana:5601/api/kibana/settings" -H "Content-Type: application/json" -H "kbn-xsrf: true" -d@${default_index}
rm -f ${default_index}

sleep 5
# Configuring Kibana TimePicker.
curl -POST "http://kibana:5601/api/kibana/settings" -H "Content-Type: application/json" -H "kbn-xsrf: true" -d \
'{"changes":{"timepicker:timeDefaults":"{\n  \"from\": \"now-24h\",\n  \"to\": \"now\",\n  \"mode\": \"quick\"}"}}'

sleep 5
# Do not ask user to help providing usage statistics to Elastic
curl -POST "http://kibana:5601/api/telemetry/v1/optIn" -H "Content-Type: application/json" -H "kbn-xsrf: true" -d '{"enabled":false}'


kibana_config_file="/usr/share/kibana/plugins/wazuh/config.yml"
if grep -vq  "#xpack features" "$kibana_config_file";
then 

echo "
#xpack features
xpack.apm.ui.enabled: false
xpack.grokdebugger.enabled: false
xpack.searchprofiler.enabled: false
xpack.security.enabled: false
xpack.graph.enabled: false
xpack.ml.enabled: false
xpack.monitoring.enabled: false
xpack.reporting.enabled: false
xpack.watcher.enabled: false
" >> /usr/share/kibana/config/kibana.yml

else


declare -A CONFIG_MAP=(

[xpack.apm.ui.enabled]= $XPACK_APM
[xpack.grokdebugger.enabled]= $XPACK_DEVTOOLS
[xpack.searchprofiler.enabled]= $XPACK_DEVTOOLS
[xpack.security.enable]= $XPACK_SECURITY
[xpack.graph.enabled]= $XPACK_GRAPHS
[xpack.ml.enabled]=$XPACK_MACHINELEARNING
[xpack.monitoring.enabled]= $XPACK_MONITORING
[xpack.reporting.enable]= $XPACK_REPORTING
[xpack.watcher.enabled]= $XPACK_WATCHER
)

for i in "${!CONFIG_MAP[@]}"
do
    if [ "${CONFIG_MAP[$i]}" != "" ]; then
        sed -i 's/.*'"$i"'.*/'"$i"': '"${CONFIG_MAP[$i]}"'/' $kibana_config_file
    fi
done

fi


echo "End settings"
