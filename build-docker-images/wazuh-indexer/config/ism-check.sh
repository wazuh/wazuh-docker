#!/bin/bash
MIN_SHARD_SIZE=${MIN_SHARD_SIZE:-25}
MIN_INDEX_AGE=${MIN_INDEX_AGE:-"7d"}
MIN_DOC_COUNT=${MIN_DOC_COUNT:-600000000}
ISM_PRIORITY=${ISM_PRIORITY:-50}
WAZUH_TEMPLATE=${WAZUH_TEMPLATE:-"/usr/share/wazuh-indexer/wazuh-template.json"}
SERVER=`hostname`
if [[ -n "$INDEXER_PASSWORD"  ]]; then
    until [[ `curl -XGET https://$SERVER:9200/_cat/indices -u admin:SecretPassword -k -s  | grep .opendistro_security | wc -l`  -eq 1 ]]
    do
        echo "Wazuh indexer Security is not initiaized";
        sleep 30
    done
    bash /usr/share/wazuh-indexer/bin/indexer-ism-init.sh  -p $INDEXER_PASSWORD -i $SERVER -P $ISM_PRIORITY -d $MIN_DOC_COUNT -a $MIN_INDEX_AGE -s $MIN_SHARD_SIZE -t $WAZUH_TEMPLATE
fi
