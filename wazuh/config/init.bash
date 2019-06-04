#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

#
# Initialize the custom data directory layout
#
source /data_files.env

cd /var/ossec

MIRRORING_PATH=/var/ossec/docker-backups
mkdir ${MIRRORING_PATH}
Update=${MIRRORING_PATH}/update
mkdir ${Update}

for ossecfile in "${DATA_FILES[@]}"; do
  if [ ! -e ${Update}/${ossecfile}  ]
  then
    DIR=$(dirname "${ossecfile}")
    mkdir -p ${Update}/${DIR}
  fi
  mv ${ossecfile} ${Update}/${ossecfile}
done

source /data_dirs.env

Mount=${MIRRORING_PATH}/mount
mkdir ${Mount}

for ossecdir in "${DATA_DIRS[@]}"; do
  if [ ! -e ${Mount}/${ossecdir}  ]
  then
    DIR=$(dirname "${ossecdir}")
    mkdir -p ${Mount}/${DIR}
  fi
  mv ${ossecdir} ${Mount}/${ossecdir}
done
