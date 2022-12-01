## Variables
WAZUH_CURRENT_VERSION=$(curl --silent https://api.github.com/repos/wazuh/wazuh/releases/latest | grep '\"tag_name\":' | sed -E 's/.*\"([^\"]+)\".*/\1/' | cut -c 2-)
MAJOR_BUILD=$(echo $WAZUH_VERSION | cut -d. -f1)
MID_BUILD=$(echo $WAZUH_VERSION | cut -d. -f2)
MINOR_BUILD=$(echo $WAZUH_VERSION | cut -d. -f3)
MAJOR_CURRENT=$(echo $WAZUH_CURRENT_VERSION | cut -d. -f1)
MID_CURRENT=$(echo $WAZUH_CURRENT_VERSION | cut -d. -f2)
MINOR_CURRENT=$(echo $WAZUH_CURRENT_VERSION | cut -d. -f3)

## If wazuh manager exists in apt dev repository, change variables, if not exit 1
if [ "$MAJOR_BUILD" -ge "$MAJOR_CURRENT" ]; then
  APT_KEY=https://packages-dev.wazuh.com/key/GPG-KEY-WAZUH
  REPOSITORY="deb https://packages-dev.wazuh.com/pre-release/apt/ unstable main"
elif [ "$MAJOR_BUILD" -eq "$MAJOR_CURRENT" ]; then
  if [ "$MID_BUILD" -ge "$MID_CURRENT" ]; then
    APT_KEY=https://packages-dev.wazuh.com/key/GPG-KEY-WAZUH
    REPOSITORY="deb https://packages-dev.wazuh.com/pre-release/apt/ unstable main"
  elif [ "$MID_BUILD" -eq "$MID_CURRENT" ]; then
    if [ "$MINOR_BUILD" -ge "$MINOR_CURRENT" ]; then
      APT_KEY=https://packages-dev.wazuh.com/key/GPG-KEY-WAZUH
      REPOSITORY="deb https://packages-dev.wazuh.com/pre-release/apt/ unstable main"
    else
      APT_KEY=https://packages.wazuh.com/key/GPG-KEY-WAZUH
      REPOSITORY="deb https://packages.wazuh.com/4.x/apt/ stable main"
    fi
  else
    APT_KEY=https://packages.wazuh.com/key/GPG-KEY-WAZUH
    REPOSITORY="deb https://packages.wazuh.com/4.x/apt/ stable main"
  fi
else
  APT_KEY=https://packages.wazuh.com/key/GPG-KEY-WAZUH
  REPOSITORY="deb https://packages.wazuh.com/4.x/apt/ stable main"
fi
apt-key adv --fetch-keys ${APT_KEY}
echo ${REPOSITORY} | tee -a /etc/apt/sources.list.d/wazuh.list