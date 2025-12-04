# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
# This has to be exported to make some magic below work.
export DH_OPTIONS

export NAME=wazuh-dashboard
export INSTALLATION_DIR=/usr/share/${NAME}
export CONFIG_DIR=${INSTALLATION_DIR}/config

# Modify opensearch_dashboards.yml config paths
if [ -d "/etc/wazuh-dashboard" ]; then
    mkdir -p ${CONFIG_DIR}
    mkdir -p ${CONFIG_DIR}/certs
    mv /etc/wazuh-dashboard/* ${CONFIG_DIR}/
    rmdir /etc/wazuh-dashboard
fi
sed -i "s|/etc/wazuh-dashboard|${CONFIG_DIR}|g" ${CONFIG_DIR}/opensearch_dashboards.yml
