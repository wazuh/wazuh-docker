#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

##############################################################################
# Downloading Cert Gen Tool
##############################################################################

## Variables
CERT_TOOL=wazuh-certs-tool.sh
PASSWORD_TOOL=wazuh-passwords-tool.sh
PACKAGES_URL=https://packages.wazuh.com/4.9/
PACKAGES_DEV_URL=https://packages-dev.wazuh.com/4.9/

## Check if the cert tool exists in S3 buckets
CERT_TOOL_PACKAGES=$(curl --silent -I $PACKAGES_URL$CERT_TOOL | grep -E "^HTTP" | awk  '{print $2}')
CERT_TOOL_PACKAGES_DEV=$(curl --silent -I $PACKAGES_DEV_URL$CERT_TOOL | grep -E "^HTTP" | awk  '{print $2}')

## If cert tool exists in some bucket, download it, if not exit 1
if [ "$CERT_TOOL_PACKAGES" = "200" ]; then
  curl -o $CERT_TOOL $PACKAGES_URL$CERT_TOOL -s
  echo "The tool to create the certificates exists in the in Packages bucket"
elif [ "$CERT_TOOL_PACKAGES_DEV" = "200" ]; then
  curl -o $CERT_TOOL $PACKAGES_DEV_URL$CERT_TOOL -s
  echo "The tool to create the certificates exists in Packages-dev bucket"
else
  echo "The tool to create the certificates does not exist in any bucket"
  echo "ERROR: certificates were not created"
  exit 1
fi

cp /config/certs.yml /config.yml

chmod 700 /$CERT_TOOL

##############################################################################
# Creating Cluster certificates
##############################################################################

## Execute cert tool and parsin cert.yml to set UID permissions
source /$CERT_TOOL -A
nodes_server=$( cert_parseYaml /config.yml | grep -E "nodes[_]+server[_]+[0-9]+=" | sed -e 's/nodes__server__[0-9]=//' | sed 's/"//g' )
node_names=($nodes_server)

echo "Moving created certificates to the destination directory"
cp /wazuh-certificates/* /certificates/
echo "Changing certificate permissions"
chmod -R 500 /certificates
chmod -R 400 /certificates/*
echo "Setting UID indexer and dashboard"
chown 1000:1000 /certificates/*
echo "Setting UID for wazuh manager and worker"
cp /certificates/root-ca.pem /certificates/root-ca-manager.pem
cp /certificates/root-ca.key /certificates/root-ca-manager.key
chown 999:999 /certificates/root-ca-manager.pem
chown 999:999 /certificates/root-ca-manager.key

for i in ${node_names[@]};
do
  chown 999:999 "/certificates/${i}.pem"
  chown 999:999 "/certificates/${i}-key.pem"
done

