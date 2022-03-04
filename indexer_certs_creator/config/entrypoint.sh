#!/bin/bash
# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

##############################################################################
# Creating Cluster certificates
##############################################################################

/wazuh-cert-tool.sh
echo "Moving created certificates to destination directory"
cp /certs/* /certificates/
echo "changing certificate permissions"
chmod -R 666 /certificates/*
