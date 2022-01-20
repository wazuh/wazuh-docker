#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

set -e


#sed -i 's/localhost:9700/elasticsearch:9200/' /etc/wazuh-dashboard/wazuh-dashboard.yml

service wazuh-dashboard start

while true; do sleep 1000; done