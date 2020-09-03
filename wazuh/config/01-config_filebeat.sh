#!/bin/bash
# Wazuh App Copyright (C) 2020 Wazuh Inc. (License GPLv2)

set -e

# Modify the output to Elasticsearch if th ELASTICSEARCH_URL is set
if [ "$ELASTICSEARCH_URL" != "" ]; then
  >&2 echo "Customize Elasticsearch ouput IP."
  sed -i 's|http://elasticsearch:9200|'$ELASTICSEARCH_URL'|g' /etc/filebeat/filebeat.yml
fi
