#!/bin/bash
set -xe

OSSEC_CONF="ossec.conf"

# --------------------------
# Defaults based on OSSEC_CONF
# --------------------------
if [[ -z "$WAZUH_CLUSTER_KEY" ]]; then
    WAZUH_CLUSTER_KEY=$(sed -n '/<cluster>/,/<\/cluster>/s/.*<key>\(.*\)<\/key>.*/\1/p' "$OSSEC_CONF" | head -n1)
fi

if [[ -z "$WAZUH_CLUSTER_PORT" ]]; then
    WAZUH_CLUSTER_PORT=$(sed -n '/<cluster>/,/<\/cluster>/s/.*<port>\(.*\)<\/port>.*/\1/p' "$OSSEC_CONF" | head -n1)
fi

# Node type logic
if [[ -z "$WAZUH_NODE_TYPE" ]]; then
    if [[ "$HOSTNAME" == "manager" || "$HOSTNAME" == "aio_node" ]]; then
        WAZUH_NODE_TYPE="master"
    else
        WAZUH_NODE_TYPE="worker"
    fi
fi

# Default node name → HOSTNAME if not defined
WAZUH_NODE_NAME="${WAZUH_NODE_NAME:-$HOSTNAME}"

# --------------------------
# Replace Indexer Hosts
# --------------------------
if [[ -n "$WAZUH_INDEXER_HOSTS" ]]; then
    TMP_HOSTS=$(mktemp)
    {
        echo "    <hosts>"
        for NODE in $WAZUH_INDEXER_HOSTS; do
            IP="${NODE%:*}"
            PORT="${NODE#*:}"
            echo "      <host>https://$IP:$PORT</host>"
        done
        echo "    </hosts>"
    } > "$TMP_HOSTS";
    sed -i -e '/<indexer>/,/<\/indexer>/{ /<hosts>/,/<\/hosts>/{ /<hosts>/r '"$TMP_HOSTS" \
            -e 'd }}' "$OSSEC_CONF";
    rm -f "$TMP_HOSTS";
fi

# --------------------------
# Cluster: node_name
# --------------------------
sed -i "/<cluster>/,/<\/cluster>/ s|<node_name>.*</node_name>|<node_name>$WAZUH_NODE_NAME</node_name>|" "$OSSEC_CONF"

# --------------------------
# Cluster: node_type
# --------------------------
sed -i "/<cluster>/,/<\/cluster>/ s|<node_type>.*</node_type>|<node_type>$WAZUH_NODE_TYPE</node_type>|" "$OSSEC_CONF"

# --------------------------
# Cluster: key
# --------------------------
sed -i "/<cluster>/,/<\/cluster>/ s|<key>.*</key>|<key>$WAZUH_CLUSTER_KEY</key>|" "$OSSEC_CONF"

# --------------------------
# Cluster: port
# --------------------------
sed -i "/<cluster>/,/<\/cluster>/ s|<port>.*</port>|<port>$WAZUH_CLUSTER_PORT</port>|" "$OSSEC_CONF"

# --------------------------
# Cluster: nodes list
# --------------------------
if [[ -n "$WAZUH_CLUSTER_NODES" ]]; then
    TMP_NODES=$(mktemp)
    {
        echo "    <nodes>"
        for N in $WAZUH_CLUSTER_NODES; do
            echo "        <node>$N</node>"
        done
        echo "    </nodes>"
    } > "$TMP_NODES";
    sed -i -e '/<cluster>/,/<\/cluster>/{ /<nodes>/,/<\/nodes>/{ /<nodes>/r '"$TMP_NODES" \
            -e 'd }}' "$OSSEC_CONF";
    rm -f "$TMP_NODES";
fi

echo "Wazuh manager config modified successfully."
