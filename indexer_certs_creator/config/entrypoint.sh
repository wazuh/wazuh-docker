#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Start Wazuh indexer
##############################################################################

/unattended_installer/install_functions/wazuh-cert-tool.sh
mkdir -p /unattended_installer/install_functions/certificates/
cp /unattended_installer/install_functions/certs/* /unattended_installer/install_functions/certificates/
chmod -R 664 /unattended_installer/install_functions/certificates/*
