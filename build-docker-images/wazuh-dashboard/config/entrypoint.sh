#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

INSTALL_DIR=/usr/share/wazuh-dashboard
DASHBOARD_USERNAME="${DASHBOARD_USERNAME:-kibanaserver}"
DASHBOARD_PASSWORD="${DASHBOARD_PASSWORD:-kibanaserver}"

set_correct_permOwner() {
  find / -group 1000 -exec chown :999 {} +;
  find / -user 1000 -exec chown 999 {} +;
}

# Create and configure Wazuh dashboard keystore

yes | $INSTALL_DIR/bin/opensearch-dashboards-keystore create --allow-root && \
echo $DASHBOARD_USERNAME | $INSTALL_DIR/bin/opensearch-dashboards-keystore add opensearch.username --stdin --allow-root && \
echo $DASHBOARD_PASSWORD | $INSTALL_DIR/bin/opensearch-dashboards-keystore add opensearch.password --stdin --allow-root

##############################################################################
# Start Wazuh dashboard
##############################################################################

set_correct_permOwner

/wazuh_app_config.sh $WAZUH_UI_REVISION

/usr/share/wazuh-dashboard/bin/opensearch-dashboards -c /usr/share/wazuh-dashboard/config/opensearch_dashboards.yml