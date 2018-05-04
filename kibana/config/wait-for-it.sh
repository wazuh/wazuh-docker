#!/bin/bash
# Wazuh App Copyright (C) 2018 Wazuh Inc. (License GPLv2)

set -e

host="$1"
shift
cmd="kibana"

until curl -XGET $host:9200; do
  >&2 echo "Elastic is unavailable - sleeping"
  sleep 5
done

>&2 echo "Elastic is up - executing command"

sleep 5
#Insert default templates
cat /usr/share/kibana/config/wazuh-elastic6-template-alerts.json | curl -XPUT "http://$host:9200/_template/wazuh" -H 'Content-Type: application/json' -d @-

sleep 5
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
        "pci": true,
        "aws": true,
        "virustotal": true
      }
    }
    ' > /dev/null
else
  echo "Wazuh APP already configured"
fi

sleep 5

exec $cmd
