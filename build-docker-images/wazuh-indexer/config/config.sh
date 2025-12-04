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
sed -i "s|/etc/wazuh-indexer|${CONFIG_DIR}|g" ${CONFIG_DIR}/opensearch.yml

sed -i 's/-Djava.security.policy=file:\/\/\/etc\/wazuh-indexer\/opensearch-performance-analyzer\/opensearch_security.policy/-Djava.security.policy=file:\/\/\/usr\/share\/wazuh-indexer\/opensearch-performance-analyzer\/opensearch_security.policy/g' /etc/wazuh-indexer/jvm.options

chown -R ${USER}:${GROUP} ${CONFIG_DIR}
chmod -R 500 ${CONFIG_DIR}/certs
chmod -R 400 ${CONFIG_DIR}/certs/*
