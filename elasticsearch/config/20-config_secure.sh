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

  ELASTIC_HOSTNAME=`hostname`

  # Create instances.yml for elasticsearch .p12 certificate and key
  echo "
instances:
- name: \"$ELASTIC_HOSTNAME\"
  dns: 
    - $SECURITY_CERTIFICATE_DNS
" > instances.yml

  cp instances.yml /usr/share/elasticsearch

  # Change permissions and owner of ca
  chown elasticsearch: /usr/share/elasticsearch/config/$SECURITY_CA_PEM
  chmod 440 /usr/share/elasticsearch/config/$SECURITY_CA_PEM
 

  # Genereate .p12 certificate and key
  SECURITY_KEY_PASSPHRASE=`date +%s | sha256sum | base64 | head -c 32 ; echo`
  /usr/share/elasticsearch/bin/elasticsearch-certutil csr --in instances.yml --out certs.zip --pass $SECURITY_KEY_PASSPHRASE
  mv /usr/share/elasticsearch/certs.zip /usr/share/elasticsearch/config/certs.zip
  unzip certs.zip
  rm certs.zip 

  # Change permissions and owner of certificates
  chown -R elasticsearch: /usr/share/elasticsearch/config/$ELASTIC_HOSTNAME
  chmod -R 770 /usr/share/elasticsearch/config/$ELASTIC_HOSTNAME
  chmod 400 /usr/share/elasticsearch/config/$ELASTIC_HOSTNAME/$ELASTIC_HOSTNAME.csr

  # Prepare directories for openssl
  mkdir /root/ca
  mkdir /root/ca/certs /root/ca/crl /root/ca/newcerts /root/ca/private
  chmod 700 /root/ca/private
  touch /root/ca/index.txt
  echo 1000 > /root/ca/serial

  mkdir /root/ca/intermediate
  mkdir /root/ca/intermediate/certs /root/ca/intermediate/crl /root/ca/intermediate/csr /root/ca/intermediate/newcerts /root/ca/intermediate/private
  chmod 700 /root/ca/intermediate/private
  touch /root/ca/intermediate/index.txt
  echo 1000 > /root/ca/intermediate/serial
  echo 1000 > /root/ca/intermediate/crlnumber

  if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then

    openssl ca -batch -config $SECURITY_OPENSSL_CONF  -in $ELASTIC_HOSTNAME/$ELASTIC_HOSTNAME.csr -cert $SECURITY_CA_PEM  -keyfile $SECURITY_CA_KEY  -key $SECURITY_CA_PASSPHRASE -out elasticsearch.cert.pem
  
  else
    input=${SECURITY_CREDENTIALS_FILE}
    CA_PASSPHRASE_FROM_FILE=""
    while IFS= read -r line
    do
      if [[ $line == *"CA_PASSPHRASE"* ]]; then
        arrIN=(${line//:/ })
        CA_PASSPHRASE_FROM_FILE=${arrIN[1]}
      fi
    done < "$input"
    
    openssl ca -batch -config $SECURITY_OPENSSL_CONF  -in $ELASTIC_HOSTNAME/$ELASTIC_HOSTNAME.csr -cert $SECURITY_CA_PEM  -keyfile $SECURITY_CA_KEY  -key $CA_PASSPHRASE_FROM_FILE -out elasticsearch.cert.pem 
  
  fi
  
  chmod 440 /usr/share/elasticsearch/config/elasticsearch.cert.pem

  # remove CA key
  rm $SECURITY_CA_KEY

  popd

  echo "Setting configuration options."
  
  # Settings for elasticsearch.yml
  echo "
# Required to set the passwords and TLS options
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.key: /usr/share/elasticsearch/config/$ELASTIC_HOSTNAME/$ELASTIC_HOSTNAME.key
xpack.security.transport.ssl.certificate: /usr/share/elasticsearch/config/elasticsearch.cert.pem
xpack.security.transport.ssl.certificate_authorities: [\"/usr/share/elasticsearch/config/$SECURITY_CA_TRUST\"]

# HTTP layer
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.verification_mode: certificate
xpack.security.http.ssl.key: /usr/share/elasticsearch/config/$ELASTIC_HOSTNAME/$ELASTIC_HOSTNAME.key
xpack.security.http.ssl.certificate: /usr/share/elasticsearch/config/elasticsearch.cert.pem
xpack.security.http.ssl.certificate_authorities: [\"/usr/share/elasticsearch/config/$SECURITY_CA_TRUST\"]
" >> $elastic_config_file

  # Create keystore
  /usr/share/elasticsearch/bin/elasticsearch-keystore create

  # Add keys to keystore
  echo -e "$SECURITY_KEY_PASSPHRASE" | /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.transport.ssl.secure_key_passphrase --stdin
  echo -e "$SECURITY_KEY_PASSPHRASE" | /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.http.ssl.secure_key_passphrase --stdin

fi

