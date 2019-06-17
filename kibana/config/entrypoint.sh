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


if [ ${SECURITY_ENABLED} != "no" ]; then
  auth="-u elastic:${SECURITY_ELASTIC_PASSWORD} -k"
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

if [[ $SECURITY_ENABLED == "yes" ]]; then


  # Create keystore
  /usr/share/kibana/bin/kibana-keystore create
  
  echo "Setting security Kibana configuiration options."

  echo "
# Elasticsearch from/to Kibana
elasticsearch.ssl.certificateAuthorities: [\"/usr/share/kibana/config/$SECURITY_CA_PEM\"]

server.ssl.enabled: true
server.ssl.certificate: $SECURITY_KIBANA_SSL_CERT_PATH/kibana-access.pem
server.ssl.key: $SECURITY_KIBANA_SSL_KEY_PATH/kibana-access.key
" >> /usr/share/kibana/config/kibana.yml

  echo "Create SSL directories."

  mkdir -p $SECURITY_KIBANA_SSL_KEY_PATH $SECURITY_KIBANA_SSL_CERT_PATH
  CA_PATH="/usr/share/kibana/config"

  echo "Creating SSL certificates."
  
  pushd $CA_PATH

  chown kibana: $CA_PATH/$SECURITY_CA_PEM
  chmod 440 $CA_PATH/$SECURITY_CA_PEM
  SECURITY_KEY_PASS=`openssl rand -base64 32`
  openssl req -batch -x509 -days 18250 -newkey rsa:2048 -keyout $SECURITY_KIBANA_SSL_KEY_PATH/kibana-access.key -out $SECURITY_KIBANA_SSL_CERT_PATH/kibana-access.pem -passout pass:"$SECURITY_KEY_PASS" >/dev/null
  chown -R kibana: $CA_PATH/ssl
  chmod -R 770 $CA_PATH/ssl

  popd
  echo "SSL certificates created."

  # Add keys to keystore
  echo -e "$SECURITY_KIBANA_PASS" | /usr/share/kibana/bin/kibana-keystore add elasticsearch.password --stdin
  echo -e "$SECURITY_KEY_PASS" | /usr/share/kibana/bin/kibana-keystore add server.ssl.keyPassphrase --stdin
  echo -e "$SECURITY_KIBANA_USER" | /usr/share/kibana/bin/kibana-keystore add elasticsearch.username --stdin

fi

##############################################################################
# Run more configuration scripts.
##############################################################################

./wazuh_app_config.sh

sleep 5

./kibana_settings.sh &

/usr/local/bin/kibana-docker
