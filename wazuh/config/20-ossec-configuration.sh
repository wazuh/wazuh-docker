#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

##############################################################################
# Change Wazuh manager configuration. 
##############################################################################


# # Example 
# # Change remote protocol from udp to tcp
# PROTOCOL="tcp"
# sed -i -e '/<remote>/,/<\/remote>/ s|<protocol>udp</protocol>|<protocol>'$PROTOCOL'</protocol>|g' /var/ossec/etc/ossec.conf
# # It is necessary to restart the service in order to apply the new configuration. 
# service wazuh-manager restart