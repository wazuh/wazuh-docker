#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

##############################################################################
# Adapt elasticsearch.yml configuration file 
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then
    echo "SECURITY - Elasticserach security configuration."

    echo "SECURITY - Setting configuration options."

    # Settings for elasticsearch.yml to be added by the user. 
    # Example: 
    #     echo "
    # # Required to set the passwords and TLS options
    # xpack.security.enabled: true
    # xpack.security.transport.ssl.enabled: true
    # xpack.security.transport.ssl.verification_mode: certificate
    # xpack.security.transport.ssl.key: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.key
    # xpack.security.transport.ssl.certificate: /usr/share/elasticsearch/config/elasticsearch.cert.pem
    # xpack.security.transport.ssl.certificate_authorities: [\"/usr/share/elasticsearch/config/ca.cert.pem\"]

    # # HTTP layer
    # xpack.security.http.ssl.enabled: true
    # xpack.security.http.ssl.verification_mode: certificate
    # xpack.security.http.ssl.key: /usr/share/elasticsearch/config/elasticsearch/elasticsearch.key
    # xpack.security.http.ssl.certificate: /usr/share/elasticsearch/config/elasticsearch.cert.pem
    # xpack.security.http.ssl.certificate_authorities: [\"/usr/share/elasticsearch/config/ca.cert.pem\"]
    # " >> /usr/share/elasticsearch/config/elasticsearch.yml

fi
