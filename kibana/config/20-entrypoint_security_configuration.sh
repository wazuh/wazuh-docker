#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

##############################################################################
# Adapt kibana.yml configuration file 
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then

    echo "CONFIGURATION - Setting security Kibana configuiration options."

    # Example:

    #     echo "
    # # Elasticsearch from/to Kibana
    # elasticsearch.ssl.certificateAuthorities: [\"/usr/share/kibana/config/CA.pem\"]

    # server.ssl.enabled: true
    # server.ssl.certificate: /usr/share/kibana/config/ssl/certs/cert.pem
    # server.ssl.key: /usr/share/kibana/config/ssl/private/cert.key
    # server.ssl.supportedProtocols: 
    #     - TLSv1.1
    #     - TLSv1.2
    # " >> /usr/share/kibana/config/kibana.yml

fi