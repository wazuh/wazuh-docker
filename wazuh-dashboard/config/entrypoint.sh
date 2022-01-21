#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Start Wazuh dashboard
##############################################################################

sed -i 's/localhost:9700/elasticsearch:9700/' /etc/wazuh-dashboard/wazuh-dashboard.yml

service wazuh-dashboard start

sleep 20

tail -f /var/log/wazuh-dashboard/wazuh-dashboard.log
