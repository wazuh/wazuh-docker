#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Start Wazuh dashboard
##############################################################################

/wazuh_app_config.sh

/usr/share/wazuh-dashboard/bin/opensearch-dashboards -c /usr/share/wazuh-dashboard/config/opensearch_dashboards.yml