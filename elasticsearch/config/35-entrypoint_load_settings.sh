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
WAZH_API_USER=""
WAZH_API_PASS=""

if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
  ELASTIC_PASS=${SECURITY_ELASTIC_PASSWORD}
  WAZH_API_USER=${API_USER}
  WAZH_API_PASS=${API_PASS}
else
  input=${SECURITY_CREDENTIALS_FILE}
  while IFS= read -r line
  do
    if [[ $line == *"ELASTIC_PASSWORD"* ]]; then
      arrIN=(${line//:/ })
      ELASTIC_PASS=${arrIN[1]}
    elif [[ $line == *"WAZUH_API_USER"* ]]; then
      arrIN=(${line//:/ })
      WAZH_API_USER=${arrIN[1]}
    elif [[ $line == *"WAZUH_API_PASSWORD"* ]]; then
      arrIN=(${line//:/ })
      WAZH_API_PASS=${arrIN[1]}
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
# Modify wazuh-alerts template shards and replicas
##############################################################################

echo "LOAD SETTINGS - Change shards and replicas of wazuh-alerts template."
sed -i 's:"index.number_of_shards"\: "3":"index.number_of_shards"\: "'$WAZUH_ALERTS_SHARDS'":g' /usr/share/elasticsearch/config/wazuh-template.json
sed -i 's:"index.number_of_replicas"\: "0":"index.number_of_replicas"\: "'$WAZUH_ALERTS_REPLICAS'":g' /usr/share/elasticsearch/config/wazuh-template.json


##############################################################################
# Load default templates
##############################################################################

if [ -f "$WAZUH_TEMPLATE_PATH" ]; then
  echo "LOAD SETTINGS - Loading wazuh-alerts template from $WAZUH_TEMPLATE_PATH."
  cat $WAZUH_TEMPLATE_PATH | curl -XPUT "$el_url/_template/wazuh" ${auth} -H 'Content-Type: application/json' -d @-
  sleep 5

else
  echo "LOAD SETTINGS - ERROR: wazuh-alerts template not found."
  exit
fi

##############################################################################
# Prepare Wazuh API credentials
##############################################################################

API_PASS_Q=`echo "$WAZH_API_PASS" | tr -d '"'`
API_USER_Q=`echo "$WAZH_API_USER" | tr -d '"'`
API_PASSWORD=`echo -n $API_PASS_Q | base64`

echo "LOAD SETTINGS - Setting API credentials into Wazuh APP"
CONFIG_CODE=$(curl -s -o /dev/null -w "%{http_code}" -XGET $el_url/.wazuh/_doc/1513629884013 ${auth})

if [ "x$CONFIG_CODE" != "x200" ]; then
  curl -s -XPOST $el_url/.wazuh/_doc/1513629884013 ${auth} -H 'Content-Type: application/json' -d'
  {
    "api_user": "'"$API_USER_Q"'",
    "api_password": "'"$API_PASSWORD"'",
    "url": "'"$wazuh_url"'",
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
  echo "LOAD SETTINGS - Wazuh APP already configured"
fi
sleep 5

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