#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

##############################################################################
# Creation and management of certificates. 
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then
    echo "SECURITY - Elasticserach security certificates."
    
    # Creation of the certificate for Elasticsearch.
    # After the execution of this script will have generated 
    # the Elasticsearch certificate and related keys and passphrase. 
    # Example: TO DO

fi
