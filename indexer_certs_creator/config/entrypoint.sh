#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Downloading Cert Gen Tool
##############################################################################

FILE=wazuh-cert-tool.sh

#Download from packages.wazuh.com with first parameter
curl -o $FILE https://packages.wazuh.com/4.x/wazuh-cert-tool.sh
var=`grep NoSuchKey $FILE`

#If the content of the file contains NoSuchKey, download from packages-dev.wazuh.com
if [ ! -z "$var" ]; then
  curl -o $FILE  https://packages-dev.wazuh.com/4.3/wazuh-certs-tool.sh
fi

##############################################################################
# Creating Cluster certificates
##############################################################################

/wazuh-cert-tool.sh
echo "Moving created certificates to destination directory"
cp /certs/* /certificates/
echo "changing certificate permissions"
chmod -R 666 /certificates/*
