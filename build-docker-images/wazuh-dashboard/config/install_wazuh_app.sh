## Variables
WAZUH_IMAGE_VERSION=$(echo $WAZUH_VERSION | sed -e 's/\.//g')
WAZUH_ACTUAL_VERSION=$(curl --silent https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '\"tag_name\":' | sed -E 's/.*\"([^\"]+)\".*/\1/' | cut -c 2- | sed -e 's/\.//g')
echo $WAZUH_IMAGE_VERSION
echo $WAZUH_ACTUAL_VERSION
## If wazuh manager exists in apt dev repository, change variables, if not exit 1
if [ "$WAZUH_IMAGE_VERSION" -le "$WAZUH_ACTUAL_VERSION" ]; then
  WAZUH_APP=https://packages.wazuh.com/4.x/ui/dashboard/wazuh-${WAZUH_VERSION}.zip
else
  WAZUH_APP=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuh-${WAZUH_VERSION}.zip
fi

# Install Wazuh App
$INSTALL_DIR/bin/opensearch-dashboards-plugin install $WAZUH_APP --allow-root