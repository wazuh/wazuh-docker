#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

elastic_config_file="/usr/share/elasticsearch/config/elasticsearch.yml"


##############################################################################
# Setup bootstrap password to chagne all Elastic Stack passwords.
# Set xpack.security.enabled to true. In Elastic 7 must add ssl options
##############################################################################

if [[ $SETUP_PASSWORDS == "yes" ]]; then

echo "Creating certificate and set elasticsearch configuration options"

pushd /usr/share/elasticsearch/config/

unzip elastic-CA.zip
/usr/share/elasticsearch/bin/elasticsearch-certutil cert --pem --out certs.zip --ca-cert server.CA-signed.crt --ca-key server.CA.key  --ca-pass $CA_PASS
unzip certs.zip

popd

  echo "
# Required to set the passwords and TLS options
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.key: /usr/share/elasticsearch/config/instance/instance.key
xpack.security.transport.ssl.certificate: /usr/share/elasticsearch/config/instance/instance.crt
xpack.security.transport.ssl.certificate_authorities: [ \"/usr/share/elasticsearch/config/server.CA-signed.crt\" ]
" >> $elastic_config_file

fi

