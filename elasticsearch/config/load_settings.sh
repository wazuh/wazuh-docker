#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

if [ "x${ELASTICSEARCH_URL}" = "x" ]; then
  el_url="http://elasticsearch:9200"
else
  el_url="${ELASTICSEARCH_URL}"
fi

until curl -XGET $el_url; do
  >&2 echo "Elastic is unavailable - sleeping"
  sleep 5
done

>&2 echo "Elastic is up - executing command"

#Insert default templates

sed -i 's|    "index.refresh_interval": "5s"|    "index.refresh_interval": "5s",    "number_of_shards" :   '"${ALERTS_SHARDS}"',    "number_of_replicas" : '"${ALERTS_REPLICAS}"'|' /usr/share/elasticsearch/config/wazuh-elastic6-template-alerts.json

cat /usr/share/elasticsearch/config/wazuh-elastic6-template-alerts.json | curl -XPUT "$el_url/_template/wazuh" -H 'Content-Type: application/json' -d @-
sleep 5


API_PASS_Q=`echo "$API_PASS" | tr -d '"'`
API_USER_Q=`echo "$API_USER" | tr -d '"'`
API_PASSWORD=`echo -n $API_PASS_Q | base64`

echo "Setting API credentials into Wazuh APP"
CONFIG_CODE=$(curl -s -o /dev/null -w "%{http_code}" -XGET $el_url/.wazuh/wazuh-configuration/1513629884013)
if [ "x$CONFIG_CODE" = "x404" ]; then
  curl -s -XPOST $el_url/.wazuh/wazuh-configuration/1513629884013 -H 'Content-Type: application/json' -d'
  {
    "api_user": "'"$API_USER_Q"'",
    "api_password": "'"$API_PASSWORD"'",
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
      "virustotal": true,
      "gdpr": true,
      "ciscat": true
    }
  }
  ' > /dev/null
else
  echo "Wazuh APP already configured"
fi
sleep 5

curl -XPUT "$el_url/_cluster/settings" -H 'Content-Type: application/json' -d'
{
  "persistent": {
    "xpack.monitoring.collection.enabled": true
  }
}
'

#Disabling xpack features

elasticsearch_config_file="/usr/share/elasticsearch/config/elasticsearch.yml"
if grep -Fq  "#xpack features" "$elasticsearch_config_file";
then 
  declare -A CONFIG_MAP=(
  [xpack.ml.enabled]=$XPACK_ML
  )
  for i in "${!CONFIG_MAP[@]}"
  do
    if [ "${CONFIG_MAP[$i]}" != "" ]; then
      sed -i 's/.'"$i"'.*/'"$i"': '"${CONFIG_MAP[$i]}"'/' $elasticsearch_config_file
    fi
  done
else
  echo "
#xpack features
xpack.ml.enabled: $XPACK_ML
 " >> $elasticsearch_config_file
fi

echo "Elasticsearch is ready."
