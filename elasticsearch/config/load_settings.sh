#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

el_url=${ELASTICSEARCH_URL}


until curl -XGET $el_url; do
  >&2 echo "Elastic is unavailable - sleeping"
  sleep 5
done

>&2 echo "Elastic is up - executing command"

if [ $ENABLE_CONFIGURE_S3 ]; then
  #Wait for Elasticsearch to be ready to create the repository
  sleep 10
  IP_PORT="${ELASTICSEARCH_IP}:${ELASTICSEARCH_PORT}"

  if [ "x$S3_PATH" != "x" ]; then 

    if [ "x$S3_ELASTIC_MAJOR" != "x" ]; then 
      ./config/configure_s3.sh $IP_PORT $S3_BUCKET_NAME $S3_PATH $S3_REPOSITORY_NAME $S3_ELASTIC_MAJOR 

    else
      ./config/configure_s3.sh $IP_PORT $S3_BUCKET_NAME $S3_PATH $S3_REPOSITORY_NAME 

    fi

  fi

fi


# Set cluster delayed timeout when node falls
curl -X PUT "$el_url/_all/_settings" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "index.unassigned.node_left.delayed_timeout": "'"$CLUSTER_DELAYED_TIMEOUT"'"
  }
}
'

echo "Elasticsearch is ready."
