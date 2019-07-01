#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

#
# Initialize the custom data directory layout
#
source /permanent_data.env

WAZUH_INSTALL_PATH=/var/ossec
DATA_TMP_PATH=${WAZUH_INSTALL_PATH}/data_tmp
mkdir ${DATA_TMP_PATH}
EXCLUSION_PATH=${DATA_TMP_PATH}/exclusion
mkdir ${EXCLUSION_PATH}

for exclusion_file in "${PERMANENT_DATA_EXCP[@]}"; do
  if [ ! -e ${EXCLUSION_PATH}/${exclusion_file}  ]
  then
    DIR=$(dirname "${exclusion_file}")
    mkdir -p ${EXCLUSION_PATH}/${DIR}
  fi
  mv ${exclusion_file} ${EXCLUSION_PATH}/${exclusion_file}
done

PERMANENT_PATH=${DATA_TMP_PATH}/permanent
mkdir ${PERMANENT_PATH}

for permanent_dir in "${PERMANENT_DATA[@]}"; do
  if [ ! -e ${PERMANENT_PATH}${permanent_dir}  ]
  then
    DIR=$(dirname "${permanent_dir}")
    mkdir -p ${PERMANENT_PATH}${DIR}
  fi
  mv ${permanent_dir} ${PERMANENT_PATH}${permanent_dir}

done