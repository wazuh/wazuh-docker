#!/bin/bash

#
# Initialize the custom data directory layout
#
source /data_dirs.env

API_USER="wazadmin"
API_PASSWD=`openssl rand -base64 32 | head -c 16`
echo "API credentials are ${API_USER} - ${API_PASSWD}"

/bin/node /var/ossec/api/configuration/auth/htpasswd -c /var/ossec/api/configuration/auth/user -b ${API_USER} ${API_PASSWD}

cd /var/ossec
for ossecdir in "${DATA_DIRS[@]}"; do
  mv ${ossecdir} ${ossecdir}-template
  ln -s $(realpath --relative-to=$(dirname ${ossecdir}) data)/${ossecdir} ${ossecdir}
done
