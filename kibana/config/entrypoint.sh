#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

##############################################################################
# Waiting for elasticsearch
##############################################################################

if [ "x${ELASTICSEARCH_URL}" = "x" ]; then
  el_url="http://elasticsearch:9200"
else
  el_url="${ELASTICSEARCH_URL}"
fi


if [ ${SETUP_PASSWORDS} != "no" ]; then
  auth="-u elastic:${ELASTIC_PASS}"
elif [ ${ENABLED_XPACK} != "true" || "x${ELASTICSEARCH_USERNAME}" = "x" || "x${ELASTICSEARCH_PASSWORD}" = "x" ]; then
  auth=""
else
  auth="--user ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}"
fi

until curl -XGET $el_url ${auth}; do
  >&2 echo "Elastic is unavailable - sleeping"
  sleep 5
done

sleep 2

>&2 echo "Elasticsearch is up."


##############################################################################
# Waiting for wazuh alerts template
##############################################################################

strlen=0

while [[ $strlen -eq 0 ]]
do
  template=$(curl $auth $el_url/_cat/templates/wazuh -s)
  strlen=${#template}
  >&2 echo "Wazuh alerts template not loaded - sleeping."
  sleep 2
done

sleep 2

>&2 echo "Wazuh alerts template is loaded."


##############################################################################
# If Secure access to Kibana is enabled, we must set the credentials.
# We must create the ssl certificate.
##############################################################################

if [[ $SETUP_PASSWORDS == "yes" ]]; then


  echo "Setting security Kibana configuiration options."

  echo "
# Required set the passwords
elasticsearch.username: \"elastic\"
elasticsearch.password: \"$ELASTIC_PASS\"
server.ssl.enabled: true
server.ssl.key: $KIBANA_SSL_KEY_PATH/kibana-access.key
server.ssl.certificate: $KIBANA_SSL_CERT_PATH/kibana-access.pem
elasticsearch.ssl.verificationMode: none
" >> /usr/share/kibana/config/kibana.yml

  echo "Create SSL directories."

  mkdir -p $KIBANA_SSL_KEY_PATH $KIBANA_SSL_CERT_PATH

  echo "Creating SSL certificates."
  openssl req -x509 -batch -nodes -days 365 -newkey rsa:2048 -keyout $KIBANA_SSL_KEY_PATH/kibana-access.key -out $KIBANA_SSL_CERT_PATH/kibana-access.pem  >/dev/null

fi

##############################################################################
# Run more configuration scripts.
##############################################################################

./wazuh_app_config.sh

sleep 5

./kibana_settings.sh &

/usr/local/bin/kibana-docker
