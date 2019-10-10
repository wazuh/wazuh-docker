#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
#
# OSSEC container bootstrap. See the README for information of the environment
# variables expected by this script.
#

set -e

##############################################################################
# Adapt 01-wazuh.conf pipeline. Adapt pipeline if it is necessary.
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then

  echo "PIPELINE - TO DO"
  # Settings for 01-wazuh.conf
  # TO DO

fi
  