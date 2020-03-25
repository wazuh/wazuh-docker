#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

##############################################################################
# Set Elasticsearch API url and Wazuh API url.
##############################################################################

if [[ "x${ELASTICSEARCH_PROTOCOL}" = "x" || "x${ELASTICSEARCH_IP}" = "x" || "x${ELASTICSEARCH_PORT}" = "x" ]]; then
  el_url="http://elasticsearch:9200"
else
  el_url="${ELASTICSEARCH_PROTOCOL}://${ELASTICSEARCH_IP}:${ELASTICSEARCH_PORT}"
fi

if [[ "x${WAZUH_API_URL}" = "x" ]]; then
  wazuh_url="https://wazuh"
else
  wazuh_url="${WAZUH_API_URL}"
fi

echo "LOAD SETTINGS - Elasticsearch url: $el_url"


##############################################################################
# If Elasticsearch security is enabled get the elastic user password and
# WAZUH API credentials.
##############################################################################

ELASTIC_PASS=""

if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
  ELASTIC_PASS=${SECURITY_ELASTIC_PASSWORD}
else
  input=${SECURITY_CREDENTIALS_FILE}
  while IFS= read -r line
  do
    if [[ $line == *"ELASTIC_PASSWORD"* ]]; then
      arrIN=(${line//:/ })
      ELASTIC_PASS=${arrIN[1]}
    fi
  done < "$input"
 
fi


##############################################################################
# Set authentication for curl if Elasticsearch security is enabled.
##############################################################################

if [ ${SECURITY_ENABLED} != "no" ]; then
  auth="-uelastic:${ELASTIC_PASS} -k"
  echo "LOAD SETTINGS - authentication for curl established."
elif [[ ${ENABLED_XPACK} != "true" || "x${ELASTICSEARCH_USERNAME}" = "x" || "x${ELASTICSEARCH_PASSWORD}" = "x" ]]; then
  auth=""
  echo "LOAD SETTINGS - authentication for curl not established."
else
  auth="--user ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}"
  echo "LOAD SETTINGS - authentication for curl established."
fi


##############################################################################
# Wait until Elasticsearch is active. 
##############################################################################

until curl ${auth} -XGET $el_url; do
  >&2 echo "LOAD SETTINGS - Elastic is unavailable - sleeping"
  sleep 5
done

>&2 echo "LOAD SETTINGS - Elastic is up - executing command"


##############################################################################
# Configure S3 repository for Elasticsearch snapshots. 
##############################################################################

if [ $ENABLE_CONFIGURE_S3 ]; then
  #Wait for Elasticsearch to be ready to create the repository
  sleep 10
  >&2 echo "S3 - Configure S3"
  if [ "x$S3_PATH" != "x" ]; then
    >&2 echo "S3 - Path: $S3_PATH"
    if [ "x$S3_ELASTIC_MAJOR" != "x" ]; then
      >&2 echo "S3 - Elasticsearch major version: $S3_ELASTIC_MAJOR"
      echo "LOAD SETTINGS - Run 35-load_settings_configure_s3.sh."
      bash /usr/share/elasticsearch/config/35-load_settings_configure_s3.sh $el_url $S3_BUCKET_NAME $S3_PATH $S3_REPOSITORY_NAME $S3_ELASTIC_MAJOR
    else
      >&2 echo "S3 - Elasticserach major version not given."
      echo "LOAD SETTINGS - Run 35-load_settings_configure_s3.sh."
      bash /usr/share/elasticsearch/config/35-load_settings_configure_s3.sh $el_url $S3_BUCKET_NAME $S3_PATH $S3_REPOSITORY_NAME
    fi

  fi

fi


##############################################################################
# Load custom policies.
##############################################################################

echo "LOAD SETTINGS - Loading custom Elasticsearch policies."
bash /usr/share/elasticsearch/35-load_settings_policies.sh


##############################################################################
# Modify wazuh-alerts template shards and replicas
##############################################################################

echo "LOAD SETTINGS - Change shards and replicas of wazuh-alerts template."
sed -i 's:"index.number_of_shards"\: "3":"index.number_of_shards"\: "'$WAZUH_ALERTS_SHARDS'":g' /usr/share/elasticsearch/config/wazuh-template.json
sed -i 's:"index.number_of_replicas"\: "0":"index.number_of_replicas"\: "'$WAZUH_ALERTS_REPLICAS'":g' /usr/share/elasticsearch/config/wazuh-template.json


##############################################################################
# Load default templates
##############################################################################

echo "LOAD SETTINGS - Loading wazuh-alerts template"
bash /usr/share/elasticsearch/35-load_settings_templates.sh


##############################################################################
# Load custom aliases.
##############################################################################

echo "LOAD SETTINGS - Loading custom Elasticsearch aliases."
bash /usr/share/elasticsearch/35-load_settings_aliases.sh


##############################################################################
# Elastic Stack users creation. 
# Only security main node can manage users. 
##############################################################################

echo "LOAD SETTINGS - Run users_management.sh."
MY_HOSTNAME=`hostname`
echo "LOAD SETTINGS - Hostname: $MY_HOSTNAME"
if [[ $SECURITY_MAIN_NODE == $MY_HOSTNAME ]]; then
  bash /usr/share/elasticsearch/35-load_settings_users_management.sh &
fi


##############################################################################
# Enable xpack.monitoring.collection
##############################################################################

curl -XPUT "$el_url/_cluster/settings" ${auth} -H 'Content-Type: application/json' -d'
{
  "persistent": {
    "xpack.monitoring.collection.enabled": true
  }
}
'


##############################################################################
# Set cluster delayed timeout when node falls
##############################################################################

curl -X PUT "$el_url/_all/_settings" ${auth} -H 'Content-Type: application/json' -d'
{
  "settings": {
    "index.unassigned.node_left.delayed_timeout": "'"$CLUSTER_DELAYED_TIMEOUT"'"
  }
}
'
echo "LOAD SETTINGS - cluster delayed timeout changed."

echo "LOAD SETTINGS - Elasticsearch is ready."
