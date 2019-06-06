#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

elastic_config_file="/usr/share/elasticsearch/config/elasticsearch.yml"


##############################################################################
# Setup bootstrap password to chagne all Elastic Stack passwords.
# Set xpack.security.enabled to true. In Elastic 7 must add ssl options
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then

  echo "Creating certificate."

  pushd /usr/share/elasticsearch/config/

  echo "Setting configuration options."

  echo "
instances:
- name: \"elasticsearch\"
  dns: 
    - $SECURITY_CERTIFICATE_DNS
" > instances.yml

  /usr/share/elasticsearch/bin/elasticsearch-certutil cert --pem -in instances.yml --out certs.zip --ca-cert $SECURITY_CA_PEM --ca-key $SECURITY_ENABLED_CA_KEY --ca-pass $SECURITY_ENABLED_CA_PASSPHRASE
  unzip certs.zip
  rm certs.zip

  popd

  chown elasticsearch: /usr/share/elasticsearch/config/$SECURITY_CA_PEM
  chown -R elasticsearch: /usr/share/elasticsearch/config/elasticsearch
  chmod 770 /usr/share/elasticsearch/config/$SECURITY_CA_PEM
  chmod -R 770 /usr/share/elasticsearch/config/elasticsearch

  echo "Setting configuration options."

  echo "
# Required to set the passwords and TLS options
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.key: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.key
xpack.security.transport.ssl.certificate: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.crt
xpack.security.transport.ssl.certificate_authorities: [ \"/usr/share/elasticsearch/config/$SECURITY_CA_PEM\" ]

# HTTP layer
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.verification_mode: certificate
xpack.security.http.ssl.key: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.key
xpack.security.http.ssl.certificate: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.crt
xpack.security.http.ssl.certificate_authorities: [ \"/usr/share/elasticsearch/config/$SECURITY_CA_PEM\" ]
" >> $elastic_config_file

fi

