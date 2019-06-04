#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

#
# Initialize the custom data directory layout
#
source /data_files.env

MIRRORING_PATH=/var/ossec/docker-backups
mkdir ${MIRRORING_PATH}
cd /var/ossec

for ossecfile in "${DATA_FILES[@]}"; do
  if [ ! -e ${MIRRORING_PATH}/${ossecfile}  ]
  then
    DIR=$(dirname "${ossecfile}")
    mkdir -p ${MIRRORING_PATH}/${DIR}
  fi
  mv ${ossecfile} docker-backups/${ossecfile}
done
