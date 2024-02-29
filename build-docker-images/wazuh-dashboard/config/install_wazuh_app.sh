## variables
WAZUH_APP=https://packages.wazuh.com/4.x/ui/dashboard/wazuh-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
WAZUH_CHECK_UPDATES=https://packages.wazuh.com/4.x/ui/dashboard/wazuhCheckUpdates-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
WAZUH_CORE=https://packages.wazuh.com/4.x/ui/dashboard/wazuhCore-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
WAZUH_CURRENT_VERSION=$(curl --silent https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '["]tag_name["]:' | sed -E 's/.*\"([^\"]+)\".*/\1/' | cut -c 2-)
MAJOR_BUILD=$(echo $WAZUH_VERSION | cut -d. -f1)
MID_BUILD=$(echo $WAZUH_VERSION | cut -d. -f2)
MINOR_BUILD=$(echo $WAZUH_VERSION | cut -d. -f3)
MAJOR_CURRENT=$(echo $WAZUH_CURRENT_VERSION | cut -d. -f1)
MID_CURRENT=$(echo $WAZUH_CURRENT_VERSION | cut -d. -f2)
MINOR_CURRENT=$(echo $WAZUH_CURRENT_VERSION | cut -d. -f3)

## check version to use the correct repository
if [ "$MAJOR_BUILD" -gt "$MAJOR_CURRENT" ]; then
  WAZUH_APP=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuh-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
  WAZUH_CHECK_UPDATES=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuhCheckUpdates-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
  WAZUH_CORE=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuhCore-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
elif [ "$MAJOR_BUILD" -eq "$MAJOR_CURRENT" ]; then
  if [ "$MID_BUILD" -gt "$MID_CURRENT" ]; then
    WAZUH_APP=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuh-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
    WAZUH_CHECK_UPDATES=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuhCheckUpdates-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
    WAZUH_CORE=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuhCore-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
  elif [ "$MID_BUILD" -eq "$MID_CURRENT" ]; then
    if [ "$MINOR_BUILD" -gt "$MINOR_CURRENT" ]; then
      WAZUH_APP=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuh-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
      WAZUH_CHECK_UPDATES=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuhCheckUpdates-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
      WAZUH_CORE=https://packages-dev.wazuh.com/pre-release/ui/dashboard/wazuhCore-${WAZUH_VERSION}-${WAZUH_UI_REVISION}.zip
    fi
  fi
fi

# Install Wazuh App
$INSTALL_DIR/bin/opensearch-dashboards-plugin install $WAZUH_APP --allow-root
$INSTALL_DIR/bin/opensearch-dashboards-plugin install $WAZUH_CHECK_UPDATES --allow-root
$INSTALL_DIR/bin/opensearch-dashboards-plugin install $WAZUH_CORE --allow-root