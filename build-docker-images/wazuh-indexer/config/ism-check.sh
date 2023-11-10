#!/bin/bash
SERVER=`hostname`
if [[ -n "$INDEXER_PASSWORD"  ]]; then
    until [[ `curl -XGET https://$SERVER:9200/_cat/indices -u admin:SecretPassword -k -s  | grep .opendistro_security | wc -l`  -eq 1 ]]
    do
        echo "Wazuh indexer Security is not initiaized";
        sleep 30
    done
    bash /usr/share/wazuh-indexer/bin/indexer-ism-init.sh  -p $INDEXER_PASSWORD -i $SERVER
fi