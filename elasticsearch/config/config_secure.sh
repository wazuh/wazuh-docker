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

  # Create instances.yml for elasticsearch .p12 certificate and key
  echo "
instances:
- name: \"elasticsearch\"
  dns: 
    - $SECURITY_CERTIFICATE_DNS
" > instances.yml

  # Genereate .p12 certificate and key
  SECURITY_KEY_PASSPHRASE=`date +%s | sha256sum | base64 | head -c 32 ; echo`
  /usr/share/elasticsearch/bin/elasticsearch-certutil cert -in instances.yml --out certs.zip --ca-cert $SECURITY_CA_PEM --ca-key $SECURITY_CA_KEY --ca-pass $SECURITY_CA_PASSPHRASE --pass $SECURITY_KEY_PASSPHRASE
  unzip certs.zip
  rm certs.zip

  popd

  # Change permissions and owner of certificates
  chown elasticsearch: /usr/share/elasticsearch/config/$SECURITY_CA_PEM
  chown -R elasticsearch: /usr/share/elasticsearch/config/elasticsearch
  chmod 770 /usr/share/elasticsearch/config/$SECURITY_CA_PEM
  chmod -R 770 /usr/share/elasticsearch/config/elasticsearch

  echo "Setting configuration options."
  
  # Settings for elasticsearch.yml
  echo "
# Required to set the passwords and TLS options
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.p12
xpack.security.transport.ssl.truststore.path: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.p12

# HTTP layer
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.verification_mode: certificate
xpack.security.http.ssl.keystore.path: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.p12
xpack.security.http.ssl.truststore.path: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.p12
" >> $elastic_config_file

  # Create keystore
  /usr/share/elasticsearch/bin/elasticsearch-keystore create

  # Add keys to keystore
  echo -e "$SECURITY_KEY_PASSPHRASE" | /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.transport.ssl.keystore.secure_password --stdin
  echo -e "$SECURITY_KEY_PASSPHRASE" | /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.transport.ssl.truststore.secure_password --stdin
  echo -e "$SECURITY_KEY_PASSPHRASE" | /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.http.ssl.keystore.secure_password --stdin
  echo -e "$SECURITY_KEY_PASSPHRASE" | /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.http.ssl.truststore.secure_password --stdin

fi

