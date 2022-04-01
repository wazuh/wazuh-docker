#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Downloading Cert Gen Tool
##############################################################################

## Variables
CERT_TOOL=wazuh-certs-tool.sh
PASSWORD_TOOL=wazuh-passwords-tool.sh
PACKAGES_URL=https://packages.wazuh.com/4.3/
PACKAGES_DEV_URL=https://packages-dev.wazuh.com/4.3/

## Check if the cert tool exists in S3 buckets
CERT_TOOL_PACKAGES=$(curl --silent -I $PACKAGES_URL$CERT_TOOL | grep -E "^HTTP" | awk  '{print $2}')
CERT_TOOL_PACKAGES_DEV=$(curl --silent -I $PACKAGES_DEV_URL$CERT_TOOL | grep -E "^HTTP" | awk  '{print $2}')

## If cert tool exists in some bucket, download it, if not exit 1
if [ "$CERT_TOOL_PACKAGES" = "200" ]; then
  curl -o $CERT_TOOL $PACKAGES_URL$CERT_TOOL
  echo "Cert tool exists in Packages bucket"
elif [ "$CERT_TOOL_PACKAGES_DEV" = "200" ]; then
  curl -o $CERT_TOOL $PACKAGES_DEV_URL$CERT_TOOL
  echo "Cert tool exists in Packages-dev bucket"
else
  echo "Cert tool does not exist in any bucket"
  echo "ERROR: certificates were not created"
  exit 1
fi

chmod 700 /$CERT_TOOL

##############################################################################
# Creating Cluster certificates
##############################################################################

/$CERT_TOOL -A
echo "Moving created certificates to destination directory"
cp /wazuh-certificates/* /certificates/
echo "changing certificate permissions"
chmod -R 666 /certificates/*
