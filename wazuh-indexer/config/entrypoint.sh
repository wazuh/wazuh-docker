#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Start Wazuh indexer
##############################################################################

rm -rf /var/lib/wazuh-indexer/*

service wazuh-indexer start

sleep 20

echo "inicio ver hostname"
echo $HOSTNAME
echo "fin ver hostname"
export OPENSEARCH_PATH_CONF=/etc/wazuh-indexer 
export JAVA_HOME=/usr/share/wazuh-indexer/jdk
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh -cd /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig -icl -p 9800 -cd /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig -nhnv -cacert /etc/wazuh-indexer/certs/root-ca.pem -cert /etc/wazuh-indexer/certs/admin.pem -key /etc/wazuh-indexer/certs/admin-key.pem

#export JAVA_HOME=/usr/share/wazuh-indexer/jdk/ &&  bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh -cd /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig/ -nhnv -cacert /etc/wazuh-indexer/certs/root-ca.pem -cert /etc/wazuh-indexer/certs/admin.pem -key /etc/wazuh-indexer/certs/admin-key.pem -p 9800 -icl

tail -f /var/log/wazuh-indexer/wazuh-cluster.log
