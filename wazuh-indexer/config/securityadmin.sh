# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)
sleep 30
bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh -cd /usr/share/wazuh-indexer/plugins/opensearch-security/securityconfig/ -nhnv -cacert  $CACERT -cert $CERT -key $KEY -p 9800 -icl