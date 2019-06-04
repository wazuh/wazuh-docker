#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

elastic_config_file="/usr/share/elasticsearch/config/elasticsearch.yml"


##############################################################################
# Setup bootstrap password to chagne all Elastic Stack passwords.
# Set xpack.security.enabled to true. In Elastic 7 must add ssl options
##############################################################################

if [[ $XPACK_SECURITY_ENABLED == "yes" ]]; then

  echo "Creating certificate."

  pushd /usr/share/elasticsearch/config/

  echo "Setting configuration options."

  echo "
instances:
- name: \"elasticsearch\"
  dns: 
    - $XPACK_SECURITY_CERTIFICATE_DNS
" > instances.yml

  unzip elastic-CA.zip
  /usr/share/elasticsearch/bin/elasticsearch-certutil cert --pem -in instances.yml --out certs.zip --ca-cert server.CA-signed.pem --ca-key server.CA.key  --ca-pass $XPACK_SECURITY_ENABLED_CA_PASSPHRASE
  unzip certs.zip

  rm certs.zip
  rm elastic-CA.zip

  popd

  chown elasticsearch: /usr/share/elasticsearch/config/server.CA-signed.pem
  chown -R elasticsearch: /usr/share/elasticsearch/config/elasticsearch
  chmod 440 /usr/share/elasticsearch/config/server.CA-signed.pem
  chmod -R 440 /usr/share/elasticsearch/config/elasticsearch

  echo "Setting configuration options."

  echo "
# Required to set the passwords and TLS options
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.key: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.key
xpack.security.transport.ssl.certificate: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.crt
xpack.security.transport.ssl.certificate_authorities: [ \"/usr/share/elasticsearch/config/server.CA-signed.pem\" ]

# HTTP layer
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.verification_mode: certificate
xpack.security.http.ssl.key: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.key
xpack.security.http.ssl.certificate: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.crt
xpack.security.http.ssl.certificate_authorities: [ \"/usr/share/elasticsearch/config/server.CA-signed.pem\" ]
" >> $elastic_config_file

fi

