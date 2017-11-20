#!/bin/bash

set -e

host="$1"
shift
cmd="kibana"
WAZUH_KIBANA_PLUGIN_URL=${WAZUH_KIBANA_PLUGIN_URL:-https://packages.wazuh.com/wazuhapp/wazuhapp-2.1.1_5.6.4.zip}

until curl -XGET $host:9200; do
  >&2 echo "Elastic is unavailable - sleeping"
  sleep 5
done

>&2 echo "Elastic is up - executing command"

if /usr/share/kibana/bin/kibana-plugin list | grep wazuh; then
  echo "Wazuh APP already installed"
else
  /usr/share/kibana/bin/kibana-plugin install ${WAZUH_KIBANA_PLUGIN_URL}
fi

sleep 30

echo "Configuring defaultIndex to wazuh-alerts-*"

curl -s -XPUT http://$host:9200/.kibana/config/5.6.4 -H 'Content-Type: application/json' -d '{"defaultIndex" : "wazuh-alerts-*"}' > /dev/null

echo "Setting API credentials into Wazuh APP"

CONFIG_CODE=$(curl -s -o /dev/null -w "%{http_code}" -XGET http://$host:9200/.wazuh/wazuh-configuration/apiconfig)
if [ "x$CONFIG_CODE" = "x404" ]; then
  curl -s -XPOST http://$host:9200/.wazuh/wazuh-configuration/apiconfig -H 'Content-Type: application/json' -d'
  {
    "api_user": "foo",
    "api_password": "YmFy",
    "url": "https://wazuh",
    "api_port": "55000",
    "insecure": "true",
    "component": "API",
    "active": "true",
    "manager": "wazuh-manager",
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
