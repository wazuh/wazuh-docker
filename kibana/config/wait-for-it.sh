#!/bin/bash

set -e

host="$1"
shift
cmd="kibana"
WAZUH_KIBANA_PLUGIN_URL=${WAZUH_KIBANA_PLUGIN_URL:-https://packages.wazuh.com/wazuhapp/wazuhapp-3.1.0_6.1.1.zip}

until curl -XGET $host:9200; do
  >&2 echo "Elastic is unavailable - sleeping"
  sleep 5
done

>&2 echo "Elastic is up - executing command"

#Insert default templates
curl https://raw.githubusercontent.com/wazuh/wazuh/3.0/extensions/elasticsearch/wazuh-elastic6-template-alerts.json | curl -XPUT 'http://elasticsearch:9200/_template/wazuh' -H 'Content-Type: application/json' -d @-
sleep 5

curl https://raw.githubusercontent.com/wazuh/wazuh/3.0/extensions/elasticsearch/wazuh-elastic6-template-monitoring.json | curl -XPUT 'http://elasticsearch:9200/_template/wazuh-agent' -H 'Content-Type: application/json' -d @-

#Insert sample alert:
sleep 5
curl https://raw.githubusercontent.com/wazuh/wazuh/3.0/extensions/elasticsearch/alert_sample.json | curl -XPUT "http://elasticsearch:9200/wazuh-alerts-3.x-"`date +%Y.%m.%d`"/wazuh/sample" -H 'Content-Type: application/json' -d @-
sleep 5


if /usr/share/kibana/bin/kibana-plugin list | grep wazuh; then
  echo "Wazuh APP already installed"
else
  /usr/share/kibana/bin/kibana-plugin install ${WAZUH_KIBANA_PLUGIN_URL}
fi

sleep 30

echo "Setting API credentials into Wazuh APP"

CONFIG_CODE=$(curl -s -o /dev/null -w "%{http_code}" -XGET http://$host:9200/.wazuh/wazuh-configuration/1513629884013)
if [ "x$CONFIG_CODE" = "x404" ]; then
  curl -s -XPOST http://$host:9200/.wazuh/wazuh-configuration/1513629884013 -H 'Content-Type: application/json' -d'
    {
      "api_user": "foo",
      "api_password": "YmFy",
      "url": "https://wazuh",
      "api_port": "55000",
      "insecure": "true",
      "component": "API",
      "cluster_info": {
        "manager": "wazuh-manager",
        "cluster": "Disabled",
        "status": "disabled"
       },
      "extensions": {
        "oscap": true,
        "audit": true,
        "pci": true
      }
    }
    ' > /dev/null
else
  echo "Wazuh APP already configured"
fi

sleep 5

exec $cmd
