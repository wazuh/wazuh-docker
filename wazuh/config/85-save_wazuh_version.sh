#!/bin/bash
# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)

# Copy /var/ossec/etc/ossec-init.conf contents in /var/ossec/etc/VERSION to be able to check the previous Wazuh version in pod.
echo "Adding Wazuh version to /var/ossec/etc/VERSION"
/var/ossec/bin/wazuh-control info > /var/ossec/etc/VERSION