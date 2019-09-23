#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

##############################################################################
# Adapt elasticsearch.yml keystore management
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then
    echo "SECURITY - Elasticserach keystore management."

    # Create keystore
    /usr/share/elasticsearch/bin/elasticsearch-keystore create

    # Add keys to keystore by the user. 
    # Example
    # echo -e "$abcd_1234" | /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.transport.ssl.secure_key_passphrase --stdin
    # echo -e "$abcd_1234" | /usr/share/elasticsearch/bin/elasticsearch-keystore add xpack.security.http.ssl.secure_key_passphrase --stdin

else
    echo "SECURITY - Elasticsearch security not established."
fi