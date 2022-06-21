## Variables
WAZUH_IMAGE_VERSION=$(echo $WAZUH_VERSION | sed -e 's/\.//g')
WAZUH_CURRENT_VERSION=$(curl --silent https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '\"tag_name\":' | sed -E 's/.*\"([^\"]+)\".*/\1/' | cut -c 2- | sed -e 's/\.//g')
## If wazuh manager exists in apt dev repository, change variables, if not exit 1
if [ "$WAZUH_IMAGE_VERSION" -le "$WAZUH_CURRENT_VERSION" ]; then
  WAZUH_APP=https://packages.wazuh.com/4.x/ui/dashboard/wazuh-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
else
  WAZUH_APP=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuh-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
fi

# Install Wazuh App
$INSTALL_DIR/bin/opensearch-dashboards-plugin install $WAZUH_APP --allow-root