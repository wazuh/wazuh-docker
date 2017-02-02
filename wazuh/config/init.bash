#!/bin/bash

#
# Initialize the custom data directory layout
#
source /data_dirs.env

cd /var/ossec
for ossecdir in "${DATA_DIRS[@]}"; do
  mv ${ossecdir} ${ossecdir}-template
  ln -s $(realpath --relative-to=$(dirname ${ossecdir}) data)/${ossecdir} ${ossecdir}
done
