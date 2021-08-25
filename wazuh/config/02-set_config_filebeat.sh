#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

##############################################################################
# Set Filebeat config.  

##############################################################################

WAZUH_FILEBEAT_MODULE=wazuh-filebeat-0.1.tar.gz

echo "FILEBEAT - Copy Filebeat config file"
cp filebeat.yml /etc/filebeat/filebeat.yml

echo "FILEBEAT - Set permissions"

chmod go-w /etc/filebeat/filebeat.yml

echo "FILEBEAT - Get Filebeat Wazuh module"

>&2 echo "FILEBEAT - Install Wazuh Filebeat Module."
curl -s "https://packages.wazuh.com/4.x/filebeat/${WAZUH_FILEBEAT_MODULE}" | tar -xvz -C /usr/share/filebeat/module
chmod 755 -R /usr/share/filebeat/module/wazuh
