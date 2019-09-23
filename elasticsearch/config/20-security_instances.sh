#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

##############################################################################
# instances.yml
# This file is necessary for the creation of the Elasticsaerch certificate.
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then
    echo "SECURITY - Setting Elasticserach security."

    # instance.yml to be added by the user. 
    # Example:
    #       echo "
    # instances:
    # - name: \"elasticsearch\"
    #   dns:
    #     - \"elasticsearch\"
    # " > /user/share/elasticsearch/instances.yml

fi