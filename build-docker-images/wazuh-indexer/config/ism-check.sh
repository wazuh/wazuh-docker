#!/bin/bash

if [[ -n "$INDEXER_PASSWORD"  ]]; then
    until [[ `curl -XGET https://0.0.0.0:9200/_cat/indices -u admin:SecretPassword -k -s  | grep .opendistro_security | wc -l`  -eq 1 ]]
    do
        echo "Wazuh indexer Security is not initiaized";
        sleep 30
    done
    bash /usr/share/wazuh-indexer/bin/indexer-ism-init.sh -i 127.0.0.1 -p $INDEXER_PASSWORD
fi