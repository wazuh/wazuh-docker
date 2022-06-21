## Variables
WAZUH_IMAGE_VERSION=$(echo $WAZUH_VERSION | sed -e 's/\.//g')
WAZUH_CURRENT_VERSION=$(curl --silent https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '\"tag_name\":' | sed -E 's/.*\"([^\"]+)\".*/\1/' | cut -c 2- | sed -e 's/\.//g')
## If wazuh manager exists in apt dev repository, change variables, if not exit 1
if [ "$WAZUH_IMAGE_VERSION" -le "$WAZUH_CURRENT_VERSION" ]; then
  APT_KEY=https://packages.wazuh.com/key/GPG-KEY-WAZUH
  REPOSITORY="deb https://packages.wazuh.com/4.x/apt/ stable main"
else
  APT_KEY=https://packages-dev.wazuh.com/key/GPG-KEY-WAZUH
  REPOSITORY="deb https://packages-dev.wazuh.com/pre-release/apt/ unstable main"
fi
apt-key adv --fetch-keys ${APT_KEY}
echo ${REPOSITORY} | tee -a /etc/apt/sources.list.d/wazuh.list