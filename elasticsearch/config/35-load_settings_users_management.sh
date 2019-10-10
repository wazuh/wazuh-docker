#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e


##############################################################################
# Set Elasticsearch API url
##############################################################################

if [[ "x${ELASTICSEARCH_PROTOCOL}" = "x" || "x${ELASTICSEARCH_IP}" = "x" || "x${ELASTICSEARCH_PORT}" = "x" ]]; then
  el_url="http://elasticsearch:9200"
else
  el_url="${ELASTICSEARCH_PROTOCOL}://${ELASTICSEARCH_IP}:${ELASTICSEARCH_PORT}"
fi

echo "USERS - Elasticsearch url: $el_url"


##############################################################################
# If Elasticsearch security is enabled get the elastic user password.
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
# If Elasticsearch security is enabled get the users credentials.
##############################################################################

# The user must get the credentials of the users.
# TO DO. 

##############################################################################
# Set authentication for curl if Elasticsearch security is enabled.
##############################################################################

if [ ${SECURITY_ENABLED} != "no" ]; then
  auth="-uelastic:${ELASTIC_PASS} -k"
  echo "USERS - authentication for curl established."
elif [[ ${ENABLED_XPACK} != "true" || "x${ELASTICSEARCH_USERNAME}" = "x" || "x${ELASTICSEARCH_PASSWORD}" = "x" ]]; then
  auth=""
  echo "USERS - authentication for curl not established."
else
  auth="--user ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}"
  echo "USERS - authentication for curl established."
fi


##############################################################################
# Wait until Elasticsearch is active. 
##############################################################################

until curl ${auth} -XGET $el_url; do
  >&2 echo "USERS - Elastic is unavailable - sleeping"
  sleep 5
done

>&2 echo "USERS - Elastic is up - executing command"


##############################################################################
# Setup passwords for Elastic Stack users.
##############################################################################

# The user must add the credentials of the users.
# TO DO.
# Example 
# echo "USERS - Add custom_user password and role:"
# curl ${auth} -k -XPOST -H 'Content-Type: application/json' 'https://localhost:9200/_xpack/security/role/custom_user_role ' -d '
# { "indices": [ { "names": [ ".kibana*" ],  "privileges": ["read"] }, { "names": [ "wazuh-monitoring*"],  "privileges": ["all"] }] }'
# curl ${auth} -k -XPOST -H 'Content-Type: application/json' 'https://localhost:9200/_xpack/security/user/custom_user'  -d '
# { "password":"'$CUSTOM_USER_PASSWORD'", "roles" : [ "kibana_system", "custom_user_role"],  "full_name" : "Custom User" }'


##############################################################################
# Remove credentials file.
##############################################################################

if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
  echo "USERS - Security credentials file not used. Nothing to do."
else
  shred -zvu ${SECURITY_CREDENTIALS_FILE}
  echo "USERS - Security credentials file removed."
fi

