#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

##############################################################################
# Decrypt credentials.
# Remove the credentials file for security reasons.
##############################################################################

if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
  echo "CREDENTIALS - Security credentials file not used. Nothing to do."
else
  echo "CREDENTIALS - Remove credentiasl file."
  shred -zvu ${SECURITY_CREDENTIALS_FILE}
fi