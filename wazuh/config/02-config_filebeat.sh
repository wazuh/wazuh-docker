#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

WAZUH_FILEBEAT_MODULE=wazuh-filebeat-0.1.tar.gz

# Modify the output to Elasticsearch if th ELASTICSEARCH_URL is set
if [ "$ELASTICSEARCH_URL" != "" ]; then
  >&2 echo "Customize Elasticsearch ouput IP."
  sed -i 's|http://elasticsearch:9200|'$ELASTICSEARCH_URL'|g' /etc/filebeat/filebeat.yml
fi


# Modify wazuh-alerts shards and replicas
sed -i 's:"index.number_of_shards"\: "3":"index.number_of_shards"\: "'$WAZUH_ALERTS_SHARDS'":g' /etc/filebeat/wazuh-template.json
sed -i 's:"index.number_of_replicas"\: "0":"index.number_of_replicas"\: "'$WAZUH_ALERTS_REPLICAS'":g' /etc/filebeat/wazuh-template.json

# Install Wazuh Filebeat Module
curl -s "https://packages.wazuh.com/3.x/filebeat/${WAZUH_FILEBEAT_MODULE}" | tar -xvz -C /usr/share/filebeat/module
mkdir -p /usr/share/filebeat/module/wazuh
chmod 755 -R /usr/share/filebeat/module/wazuh
