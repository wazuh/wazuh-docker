#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Start Wazuh indexer
##############################################################################

export USER=wazuh-indexer
export OPENSEARCH_PATH_CONF=/etc/wazuh-indexer 
export INSTALLATION_DIR=/usr/share/wazuh-indexer
export JAVA_HOME=${INSTALLATION_DIR}/jdk
export FILE=${INSTALLATION_DIR}/start

if [ -f $FILE ] 
  then 
    echo "second or more start"
  else 
    if [ $NODE_TYPE == "worker" ] 
      then
        echo "node_type start"
        echo $NODE_TYPE
        echo "node_type end"
        rm -rf /var/lib/wazuh-indexer/*
        sleep 70
        echo "worker restart"
        touch $FILE
      else
        echo "hostname start"
        echo $HOSTNAME
        echo "hostname end"
        echo "node_type start"
        echo $NODE_TYPE
        echo "node_type end"
        service wazuh-indexer start
        sleep 5
        service wazuh-indexer status
        sleep 55
        /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh -cd /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig -icl -p 9800 -cd /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig -nhnv -cacert /etc/wazuh-indexer/certs/root-ca.pem -cert /etc/wazuh-indexer/certs/admin.pem -key /etc/wazuh-indexer/certs/admin-key.pem -h $HOSTNAME
        touch $FILE
    fi  
fi



sed -i '/path.logs:/d' /etc/wazuh-indexer/opensearch.yml

service wazuh-indexer stop
service wazuh-indexer start
#CLK_TK=`getconf CLK_TCK` runuser ${USER} --shell="/bin/bash" --command="${INSTALLATION_DIR}/bin/opensearch"

if [ -f /var/log/wazuh-indexer/wazuh-cluster.log ] 
  then
    tail -f /var/log/wazuh-indexer/wazuh-cluster.log
  else
    while true; do sleep 1000; done
fi
    
