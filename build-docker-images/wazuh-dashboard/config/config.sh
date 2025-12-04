# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
# This has to be exported to make some magic below work.
export DH_OPTIONS

export NAME=wazuh-dashboard
export INSTALLATION_DIR=/usr/share/${NAME}
export CONFIG_DIR=${INSTALLATION_DIR}/config

# Modify opensearch.yml config paths
sed -i "s|/etc/wazuh-dashboard|${CONFIG_DIR}|g" ${CONFIG_DIR}/opensearch_dashboards.yml
