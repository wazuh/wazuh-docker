#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

##############################################################################
# Decrypt credentials.
# If the credentials of the API user to be created are encrypted,
# it must be decrypted for later use. 
##############################################################################

if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
    echo "CREDENTIALS - Security credentials file not used. Nothing to do."
else
    echo "CREDENTIALS - TO DO"
fi
# TO DO