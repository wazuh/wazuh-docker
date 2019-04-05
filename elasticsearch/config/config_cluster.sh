#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

elastic_config_file="/usr/share/elasticsearch/config/elasticsearch.yml"

if [[ $ELASTIC_CLUSTER == "true" ]]
then
  
  sed -i 's:cluster.name\: "docker-cluster":cluster.name\: "'$CLUSTER_NAME'":g' $elastic_config_file
  sed -i 's:discovery.zen.minimum_master_nodes\: 1:discovery.zen.minimum_master_nodes\: '$NUMBER_OF_MASTERS':g' $elastic_config_file


  echo "
#cluster node
node:
  master: ${NODE_MASTER}
  data: ${NODE_DATA}
  ingest: ${NODE_INGEST}
  name: ${NODE_NAME}
  max_local_storage_nodes: ${MAX_NODES}

bootstrap:
  memory_lock: ${MEMORY_LOCK}

discovery:
  zen:
    ping.unicast.hosts: ${DISCOVERY_SERVICE}
  
" >> $elastic_config_file
fi
