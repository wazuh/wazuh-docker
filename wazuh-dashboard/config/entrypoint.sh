#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Start Wazuh dashboard
##############################################################################

/wazuh_app_config.sh

/usr/share/wazuh-dashboard/bin/opensearch-dashboards -c /etc/wazuh-dashboard/opensearch_dashboards.yml