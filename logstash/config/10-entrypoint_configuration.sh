#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
#
# OSSEC container bootstrap. See the README for information of the environment
# variables expected by this script.
#

set -e

##############################################################################
# Adapt logstash.yml configuration. 
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then

    echo "CONFIGURATION - TO DO"

    # Settings for logstash.yml
    # Example:
    #   echo "
    # xpack.monitoring.enabled: true
    # xpack.monitoring.elasticsearch.username: LOGSTASH_USER
    # xpack.monitoring.elasticsearch.password: LOGSTASH_PASS
    # xpack.monitoring.elasticsearch.ssl.certificate_authority: /usr/share/logstash/config/CA.pem
    # " >> /usr/share/logstash/config/logstash.yml

fi