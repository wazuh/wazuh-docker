#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

##############################################################################
# Set Elasticsearch API url.
##############################################################################

if [ "x${ELASTICSEARCH_URL}" = "x" ]; then
  el_url="http://elasticsearch:9200"
else
  el_url="${ELASTICSEARCH_URL}"
fi

echo "ENTRYPOINT - Set Elasticsearc url:${ELASTICSEARCH_URL}"


##############################################################################
# If there are credentials for Kibana they are obtained. 
##############################################################################

KIBANA_USER=""
KIBANA_PASS=""

if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
  KIBANA_USER=${SECURITY_KIBANA_USER}
  KIBANA_PASS=${SECURITY_KIBANA_PASS}
else
  input=${SECURITY_CREDENTIALS_FILE}
  while IFS= read -r line
  do
    if [[ $line == *"KIBANA_PASSWORD"* ]]; then
      arrIN=(${line//:/ })
      KIBANA_PASS=${arrIN[1]}
    elif [[ $line == *"KIBANA_USER"* ]]; then
      arrIN=(${line//:/ })
      KIBANA_USER=${arrIN[1]}
    fi
  done < "$input"
 
fi

echo "ENTRYPOINT - Kibana credentials obtained."

##############################################################################
# Establish the way to run the curl command, with or without authentication. 
##############################################################################

if [ ${SECURITY_ENABLED} != "no" ]; then
  auth="-u ${KIBANA_USER}:${KIBANA_PASS} -k"
elif [ ${ENABLED_XPACK} != "true" || "x${ELASTICSEARCH_USERNAME}" = "x" || "x${ELASTICSEARCH_PASSWORD}" = "x" ]; then
  auth=""
else
  auth="--user ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}"
fi

echo "ENTRYPOINT - Kibana authentication established."

##############################################################################
# Waiting for elasticsearch.
##############################################################################

until curl -XGET $el_url ${auth}; do
  >&2 echo "ENTRYPOINT - Elastic is unavailable: sleeping"
  sleep 5
done

sleep 2

>&2 echo "ENTRYPOINT - Elasticsearch is up."


##############################################################################
# Waiting for wazuh alerts template.
##############################################################################

strlen=0

while [[ $strlen -eq 0 ]]
do
  template=$(curl $auth $el_url/_cat/templates/wazuh -s)
  strlen=${#template}
  >&2 echo "ENTRYPOINT - Wazuh alerts template not loaded - sleeping."
  sleep 2
done

sleep 2

>&2 echo "ENTRYPOINT - Wazuh alerts template is loaded."


##############################################################################
# Create keystore if security is enabled.
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then

  echo "ENTRYPOINT - Create Keystore."
  /usr/share/kibana/bin/kibana-keystore create
  # Add keys to keystore
  echo -e "$KIBANA_PASS" | /usr/share/kibana/bin/kibana-keystore add elasticsearch.password --stdin
  echo -e "$KIBANA_USER" | /usr/share/kibana/bin/kibana-keystore add elasticsearch.username --stdin

  echo "ENTRYPOINT - Keystore created."
fi

##############################################################################
# If security is enabled set Kibana configuration.
# Create the ssl certificate.
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then

  bash /usr/share/kibana/20-entrypoint_certs_management.sh &
  bash /usr/share/kibana/20-entrypoint_security_configuration.sh &

fi


##############################################################################
# Run kibana_settings.sh script.
##############################################################################

bash /usr/share/kibana/20-entrypoint_kibana_settings.sh &

/usr/local/bin/kibana-docker
