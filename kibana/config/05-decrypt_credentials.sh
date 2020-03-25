#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

##############################################################################
# Decrypt credentials.
# If the credentials of the users to be created are encrypted,
# they must be decrypted for later use. 
##############################################################################

if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
    echo "Security credentials file not used. Nothing to do."
else
    echo "TO DO"
fi
# TO DO