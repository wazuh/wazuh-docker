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

echo "POLICIES - Elasticsearch url: $el_url"


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
  echo "POLICIES - authentication for curl established."
elif [[ ${ENABLED_XPACK} != "true" || "x${ELASTICSEARCH_USERNAME}" = "x" || "x${ELASTICSEARCH_PASSWORD}" = "x" ]]; then
  auth=""
  echo "POLICIES - authentication for curl not established."
else
  auth="--user ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}"
  echo "POLICIES - authentication for curl established."
fi


##############################################################################
# Wait until Elasticsearch is active. 
##############################################################################

until curl ${auth} -XGET $el_url; do
  >&2 echo "POLICIES - Elastic is unavailable - sleeping"
  sleep 5
done

>&2 echo "POLICIES - Elastic is up - executing command"


##############################################################################
# Add custom policies.
##############################################################################

# The user must add the credentials of the users.
# TO DO.
# Example 
# echo "POLICIES - Add custom_user password and role:"
# curl ${auth} -k -XPOST -H 'Content-Type: application/json' 'https://localhost:9200/_ilm/policy/my_policy?pretty' -d'
# {  "policy": { "phases": { "hot": { "actions": { "rollover": {"max_size": "50GB", "max_age": "5m"}}}}}}'

