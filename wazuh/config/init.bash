#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

#
# Initialize the custom data directory layout
#
source /data_files.env

WAZUH_INSTALL_PATH=/var/ossec
MIRRORING_PATH=${WAZUH_INSTALL_PATH}/docker-backups
mkdir ${MIRRORING_PATH}
Update=${MIRRORING_PATH}/update
mkdir ${Update}

for ossecfile in "${DATA_FILES[@]}"; do
  if [ ! -e ${Update}/${ossecfile}  ]
  then
    DIR=$(dirname "${ossecfile}")
    mkdir -p ${Update}/${DIR}
  fi
  mv ${WAZUH_INSTALL_PATH}/${ossecfile} ${Update}/${ossecfile}
done

source /data_dirs.env

mount=${MIRRORING_PATH}/mount
mkdir ${mount}

for ossecdir in "${DATA_DIRS[@]}"; do
  if [[ $ossecdir == /* ]]
  then
    if [ ! -e ${mount}${ossecdir}  ]
    then
      DIR=$(dirname "${ossecdir}")
      mkdir -p ${mount}${DIR}
    fi
    mv ${ossecdir} ${mount}${ossecdir}
  else
    if [ ! -e ${mount}${WAZUH_INSTALL_PATH}/${ossecdir}  ]
    then
      DIR=$(dirname "${ossecdir}")
      mkdir -p ${mount}${WAZUH_INSTALL_PATH}/${DIR}
    fi
    mv ${WAZUH_INSTALL_PATH}/${ossecdir} ${mount}${WAZUH_INSTALL_PATH}/${ossecdir}
  fi
done