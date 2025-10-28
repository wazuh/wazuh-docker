# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
# This has to be exported to make some magic below work.
export DH_OPTIONS

export NAME=wazuh-indexer

# Package build options
export USER=${NAME}
export GROUP=${NAME}
export VERSION=${WAZUH_VERSION}-${WAZUH_TAG_REVISION}
export LOG_DIR=/var/log/${NAME}
export LIB_DIR=/var/lib/${NAME}
export PID_DIR=/run/${NAME}
export INSTALLATION_DIR=/usr/share/${NAME}
export CONFIG_DIR=${INSTALLATION_DIR}/config


##############################################################################
# Downloading Cert Gen Tool
##############################################################################

## Variables
CERT_TOOL=wazuh-certs-tool.sh
CERT_CONFIG_FILE=config.yml
CERT_TOOL_VERSION="${WAZUH_VERSION%.*}"
PACKAGES_URL=https://packages.wazuh.com/$CERT_TOOL_VERSION/
PACKAGES_DEV_URL=https://packages-dev.wazuh.com/$CERT_TOOL_VERSION/

download_package() {
    local url=$1
    local package=$2
    local output=$2
    echo "Checking $url$package ..."
    if curl -fsL "$url$package" -o "$output"; then
        echo "Downloaded $package from $url"
        return 0
    else
        return 1
    fi
}

# Download the tool to create the certificates
echo "Downloading the tool to create the certificates..."
# Try first the prod URL, if it fails try the dev URL
if download_package "$PACKAGES_URL" "$CERT_TOOL"; then
    :
elif download_package "$PACKAGES_DEV_URL" "$CERT_TOOL"; then
    :
else
    echo "The tool to create the certificates does not exist in any bucket"
    echo "ERROR: certificates were not created"
    exit 1
fi

# Download the config file for the certificate tool
echo "Downloading the config file for the certificate tool..."
# Try first the prod URL, if it fails try the dev URL
if download_package "$PACKAGES_URL" "$CERT_CONFIG_FILE"; then
    :
elif download_package "$PACKAGES_DEV_URL" "$CERT_CONFIG_FILE"; then
    :
else
    echo "The config file for the certificate tool does not exist in any bucket"
    echo "ERROR: certificates were not created"
    exit 1
fi

# Modify the config file to set the IP to localhost
sed -i 's/  ip:.*/  ip: "127.0.0.1"/' $CERT_CONFIG_FILE

chmod 700 "$CERT_CONFIG_FILE"
# Create the certificates
chmod 755 "$CERT_TOOL" && bash "$CERT_TOOL" -A

# Copy Wazuh indexer's certificates and config files to $CONFIG_DIR
mkdir -p ${CONFIG_DIR}/certs
mv /etc/wazuh-indexer/* ${CONFIG_DIR}/
cp -pr /wazuh-certificates/node-1.pem ${CONFIG_DIR}/certs/indexer.pem
cp -pr /wazuh-certificates/node-1-key.pem ${CONFIG_DIR}/certs/indexer-key.pem
cp -pr /wazuh-certificates/root-ca.key ${CONFIG_DIR}/certs/root-ca.key
cp -pr /wazuh-certificates/root-ca.pem ${CONFIG_DIR}/certs/root-ca.pem
cp -pr /wazuh-certificates/admin.pem ${CONFIG_DIR}/certs/admin.pem
cp -pr /wazuh-certificates/admin-key.pem ${CONFIG_DIR}/certs/admin-key.pem

# Modify opensearch.yml config paths
sed -i "s|/etc/wazuh-indexer|${CONFIG_DIR}|g" ${CONFIG_DIR}/opensearch.yml

# Delete xms and xmx parameters in jvm.options
sed -i 's/-Djava.security.policy=file:\/\/\/etc\/wazuh-indexer\/opensearch-performance-analyzer\/opensearch_security.policy/-Djava.security.policy=file:\/\/\/usr\/share\/wazuh-indexer\/opensearch-performance-analyzer\/opensearch_security.policy/g' /etc/wazuh-indexer/jvm.options

chown -R ${USER}:${GROUP} ${CONFIG_DIR}
chmod -R 500 ${CONFIG_DIR}/certs
chmod -R 400 ${CONFIG_DIR}/certs/*