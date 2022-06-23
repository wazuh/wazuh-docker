WAZUH_CURRENT_VERSION=$(curl --silent https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '\"tag_name\":' | sed -E 's/.*\"([^\"]+)\".*/\1/' | cut -c 2- | sed -e 's/\.//g') && \
WAZUH_IMAGE_VERSION=$(echo $WAZUH_VERSION | sed -e 's/\.//g') && \


if [ "$WAZUH_IMAGE_VERSION" -le "$WAZUH_CURRENT_VERSION" ]; then
 REPOSITORY="packages.wazuh.com"
else 
 REPOSITORY="packages-dev.wazuh.com"
fi
 
curl -o wazuh-dashboard-base.tar.xz https://${REPOSITORY}/stack/dashboard/base/wazuh-dashboard-base-${WAZUH_VERSION}-${WAZUH_TAG_REVISION}-linux-x64.tar.xz
tar -xf wazuh-dashboard-base.tar.xz --directory  $INSTALL_DIR --strip-components=1
