#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

wazuh_url="${WAZUH_API_URL:-https://wazuh}"
wazuh_port="${API_PORT:-55000}"
api_username="${API_USERNAME:-wazuh-wui}"
api_password="${API_PASSWORD:-wazuh-wui}"

dashboard_config_file="/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml"

cat << EOF > $dashboard_config_file
hosts:
  - 1513629884013:
      url: $wazuh_url
      port: $wazuh_port
      username: $api_username
      password: $api_password
EOF


