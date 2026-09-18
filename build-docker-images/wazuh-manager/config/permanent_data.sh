#!/bin/bash
# Wazuh App Copyright (C) 2017, Wazuh Inc. (License GPLv2)

# Variables
source /permanent_data.env

WAZUH_INSTALL_PATH=/var/wazuh-manager
DATA_TMP_PATH=${WAZUH_INSTALL_PATH}/data_tmp
mkdir ${DATA_TMP_PATH}

# Move exclusion files to EXCLUSION_PATH
EXCLUSION_PATH=${DATA_TMP_PATH}/exclusion
mkdir ${EXCLUSION_PATH}

for exclusion_path in "${PERMANENT_DATA_EXCP[@]}"; do
  # Create the parent directory for the exclusion entry if it does not exist
  DIR=$(dirname "${exclusion_path}")
  if [ ! -e ${EXCLUSION_PATH}/${DIR}  ]
  then
    mkdir -p ${EXCLUSION_PATH}/${DIR}
  fi

  # Copy rather than move, and use -a so a directory is taken whole. The entry has
  # to stay in place: a deployment with no volume on that path reads it directly
  # from the image, and Docker populates a new named volume from it.
  cp -a ${exclusion_path} ${EXCLUSION_PATH}/${exclusion_path}
done

# Move permanent files to PERMANENT_PATH
PERMANENT_PATH=${DATA_TMP_PATH}/permanent
mkdir ${PERMANENT_PATH}

for permanent_dir in "${PERMANENT_DATA[@]}"; do
  # Create the directory for the permanent file if it does not exist
  DIR=$(dirname "${permanent_dir}")
  mkdir -p ${PERMANENT_PATH}${DIR}
  cp -ar ${permanent_dir} ${PERMANENT_PATH}${DIR}

done
