#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

##############################################################################
# Downloading Cert Gen Tool
##############################################################################

## Variables
CERT_TOOL=wazuh-certs-tool.sh
PASSWORD_TOOL=wazuh-passwords-tool.sh
PACKAGES_URL=https://packages.wazuh.com/$CERT_TOOL_VERSION/
PACKAGES_DEV_URL=https://packages-dev.wazuh.com/$CERT_TOOL_VERSION/

# Repository tried first when downloading the certificates tool: "prod" (default) or "dev".
# Use "dev" to deploy a release candidate with the tool published for it in packages-dev.
CERT_TOOL_REPOSITORY="${CERT_TOOL_REPOSITORY:-prod}"
CERT_TOOL_REPOSITORY="${CERT_TOOL_REPOSITORY,,}"

OUTPUT_FILE="/$CERT_TOOL"

download_package() {
    local url=$1
    echo "Checking $url$CERT_TOOL ..."
    if curl -fsL "$url$CERT_TOOL" -o "$OUTPUT_FILE"; then
        echo "Downloaded $CERT_TOOL from $url"
        return 0
    else
        return 1
    fi
}

# Try first the repository selected with CERT_TOOL_REPOSITORY, if it fails try the other one
case "$CERT_TOOL_REPOSITORY" in
    prod)
        FIRST_URL="$PACKAGES_URL"
        SECOND_URL="$PACKAGES_DEV_URL"
        ;;
    dev)
        FIRST_URL="$PACKAGES_DEV_URL"
        SECOND_URL="$PACKAGES_URL"
        ;;
    *)
        echo "ERROR: CERT_TOOL_REPOSITORY must be 'prod' or 'dev' (got '$CERT_TOOL_REPOSITORY')"
        exit 1
        ;;
esac

if download_package "$FIRST_URL"; then
    :
elif download_package "$SECOND_URL"; then
    echo "WARNING: $CERT_TOOL not found in $FIRST_URL, used $SECOND_URL instead"
else
    echo "The tool to create the certificates does not exist in any bucket"
    echo "ERROR: certificates were not created"
    exit 1
fi

cp /config/certs.yml /config.yml
chmod 700 "$OUTPUT_FILE"

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

