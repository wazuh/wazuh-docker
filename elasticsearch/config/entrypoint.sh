#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

# For more information https://github.com/elastic/elasticsearch-docker/blob/6.8.0/build/elasticsearch/bin/docker-entrypoint.sh

set -e

# Files created by Elasticsearch should always be group writable too
umask 0002

run_as_other_user_if_needed() {
  if [[ "$(id -u)" == "0" ]]; then
    # If running as root, drop to specified UID and run command
    exec chroot --userspec=1000 / "${@}"
  else
    # Either we are running in Openshift with random uid and are a member of the root group
    # or with a custom --user
    exec "${@}"
  fi
}


#Disabling xpack features

elasticsearch_config_file="/usr/share/elasticsearch/config/elasticsearch.yml"
if grep -Fq  "#xpack features" "$elasticsearch_config_file";
then 
  declare -A CONFIG_MAP=(
  [xpack.ml.enabled]=$XPACK_ML
  )
  for i in "${!CONFIG_MAP[@]}"
  do
    if [ "${CONFIG_MAP[$i]}" != "" ]; then
      sed -i 's/.'"$i"'.*/'"$i"': '"${CONFIG_MAP[$i]}"'/' $elasticsearch_config_file
    fi
  done
else
  echo "
#xpack features
xpack.ml.enabled: $XPACK_ML
 " >> $elasticsearch_config_file
fi

# Run load settings script.

./config_cluster.sh

./load_settings.sh &

# Execute elasticsearch

run_as_other_user_if_needed /usr/share/elasticsearch/bin/elasticsearch 
