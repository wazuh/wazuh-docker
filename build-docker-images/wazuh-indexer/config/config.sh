# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
# This has to be exported to make some magic below work.
export DH_OPTIONS

export NAME=wazuh-indexer

# Package build options
export USER=${NAME}
export GROUP=${NAME}
export INSTALLATION_DIR=/usr/share/${NAME}
export CONFIG_DIR=${INSTALLATION_DIR}/config

# Modify opensearch.yml config paths
if [ -d "/etc/wazuh-indexer" ]; then
    mkdir -p ${CONFIG_DIR}
    mkdir -p ${CONFIG_DIR}/certs
    mv /etc/wazuh-indexer/* ${CONFIG_DIR}/
    rmdir /etc/wazuh-indexer
fi
sed -i "s|/etc/wazuh-indexer|${CONFIG_DIR}|g" ${CONFIG_DIR}/opensearch.yml

sed -i 's/-Djava.security.policy=file:\/\/\/etc\/wazuh-indexer\/opensearch-performance-analyzer\/opensearch_security.policy/-Djava.security.policy=file:\/\/\/usr\/share\/wazuh-indexer\/opensearch-performance-analyzer\/opensearch_security.policy/g' ${CONFIG_DIR}/jvm.options

