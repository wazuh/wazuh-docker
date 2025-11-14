##############################################################################
# Downloading Cert Gen Tool
##############################################################################
# Variables for certificate generation
CERT_TOOL="wazuh-certs-tool.sh"
CERT_CONFIG_FILE="config.yml"
CERT_DIR=/etc/filebeat/certs
download_package() {
    local url=$1
    local package=$2
    if curl -fsL "$url" -o "$package"; then
        echo "Downloaded $package"
        return 0
    else
        echo "Error downloading $package from $url"
        return 1
    fi
}
mkdir -p $CERT_DIR
# Download the tool to create the certificates
echo "Downloading the tool to create the certificates..."
download_package "$wazuh_cert_tool" $CERT_TOOL
# Download the config file for the certificate tool
echo "Downloading the config file for the certificate tool..."
download_package "$wazuh_config_yml" $CERT_CONFIG_FILE

# Modify the config file to set the IP to localhost
sed -i 's/  ip:.*/  ip: "127.0.0.1"/' $CERT_CONFIG_FILE

chmod 700 "$CERT_CONFIG_FILE"
# Create the certificates
chmod 755 "$CERT_TOOL" && bash "$CERT_TOOL" -A

echo "files in pwd"
ls -la

# Copy Wazuh manager certs
cp -pr /wazuh-certificates/wazuh-1.pem ${CERT_DIR}/wazuh-1.pem
cp -pr /wazuh-certificates/wazuh-1-key.pem ${CERT_DIR}/wazuh-1-key.pem
cp -pr /wazuh-certificates/root-ca.key ${CERT_DIR}/root-ca.key
cp -pr /wazuh-certificates/root-ca.pem ${CERT_DIR}/root-ca.pem
cp -pr /wazuh-certificates/admin.pem ${CERT_DIR}/admin.pem
cp -pr /wazuh-certificates/admin-key.pem ${CERT_DIR}/admin-key.pem