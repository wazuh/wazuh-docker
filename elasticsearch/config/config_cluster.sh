#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

elastic_config_file="/usr/share/elasticsearch/config/elasticsearch.yml"


# If Elasticsearch cluster is enable
if [[ $ELASTIC_CLUSTER == "true" ]]
then
  
  # Set the cluster.name and discovery.zen.minimun_master_nodes variables
  sed -i 's:cluster.name\: "docker-cluster":cluster.name\: "'$CLUSTER_NAME'":g' $elastic_config_file
  #sed -i 's:discovery.zen.minimum_master_nodes\: 1:discovery.zen.minimum_master_nodes\: '$CLUSTER_NUMBER_OF_MASTERS':g' $elastic_config_file

  # Add the cluster configuration
  echo "
#cluster node
node:
  master: ${CLUSTER_NODE_MASTER}
  data: ${CLUSTER_NODE_DATA}
  ingest: ${CLUSTER_NODE_INGEST}
  name: ${CLUSTER_NODE_NAME}
  max_local_storage_nodes: ${CLUSTER_MAX_NODES}

bootstrap:
  memory_lock: ${CLUSTER_MEMORY_LOCK} 

cluster.initial_master_nodes:
  - '${CLUSTER_INITIAL_MASTER_NODES}'

" >> $elastic_config_file
else

cat >> $elastic_config_file <<'EOF'
cluster.initial_master_nodes:
  - 'elasticsearch'
EOF

# echo 'discovery.type: single-node'

fi
