#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

elastic_config_file="/usr/share/elasticsearch/config/elasticsearch.yml"

remove_single_node_conf(){
  if grep -Fq "discovery.type" $1; then
    sed -i '/discovery.type\: /d' $1 
  fi
}

# If Elasticsearch cluster is enable, then set up the elasticsearch.yml
if [[ $ELASTIC_CLUSTER == "true" && $CLUSTER_NODE_MASTER != "" && $CLUSTER_NODE_DATA != "" && $CLUSTER_NODE_INGEST != "" ]];then

  remove_single_node_conf $elastic_config_file

  # Remove the old configuration
  sed -i '/# cluster node/,/# end cluster config/d' $elastic_config_file

  # Add the current cluster configuration
cat > $elastic_config_file << EOF
# cluster node
network.host: 0.0.0.0
node.name: $CLUSTER_NODE_NAME
node.master: $CLUSTER_NODE_MASTER

cluster.initial_master_nodes: 
  - $CLUSTER_INITIAL_MASTER_NODES
# end cluster config" 
EOF

# If the cluster is disabled, then set a single-node configuration
else
  sed -i '/# cluster node/,/# end cluster config/d' $elastic_config_file
  # If it's not already configured
  remove_single_node_conf $elastic_config_file
  echo "discovery.type: single-node" >> $elastic_config_file
fi