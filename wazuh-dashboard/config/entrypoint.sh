#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Start Wazuh dashboard
##############################################################################

sed -i 's/<wazuh-indexer-ip>:9700/wazuh-indexer:9700/' /etc/wazuh-dashboard/dashboard.yml
sed -i 's/<wazuh-dashboard-ip>/0.0.0.0/' /etc/wazuh-dashboard/dashboard.yml
sed -i '/logging.dest:/d' /etc/wazuh-dashboard/dashboard.yml

runuser wazuh-dashboard --shell="/bin/bash" --command="/usr/share/wazuh-dashboard/bin/opensearch-dashboards -c /etc/wazuh-dashboard/dashboard.yml"
