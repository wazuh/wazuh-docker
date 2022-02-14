#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Creating Cluster certificates
##############################################################################

/unattended_installer/install_functions/wazuh-cert-tool.sh
echo "Moving created certificates to destination directory"
cp /unattended_installer/install_functions/certs/* /certificates/
echo "changing certificate permissions"
chmod -R 666 /certificates/*
