#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

# For more information https://github.com/elastic/elasticsearch-docker/blob/6.8.1/build/elasticsearch/bin/docker-entrypoint.sh

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
if grep -Fq  "#xpack features" "$elasticsearch_config_file" ;
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

bash /usr/share/elasticsearch/35-entrypoint_load_settings.sh &

# Execute elasticsearch


if [[ $SECURITY_ENABLED == "yes" ]]; then
  echo "Change Elastic password"
  if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
    run_as_other_user_if_needed echo "$SECURITY_ELASTIC_PASSWORD" | elasticsearch-keystore add -xf 'bootstrap.password'
  else
    input=${SECURITY_CREDENTIALS_FILE}
    ELASTIC_PASSWORD_FROM_FILE=""
    while IFS= read -r line
    do
      if [[ $line == *"ELASTIC_PASSWORD"* ]]; then
        arrIN=(${line//:/ })
        ELASTIC_PASSWORD_FROM_FILE=${arrIN[1]}
      fi
    done < "$input"
    run_as_other_user_if_needed echo "$ELASTIC_PASSWORD_FROM_FILE" | elasticsearch-keystore add -xf 'bootstrap.password'
  fi
  echo "Elastic password changed"
fi

run_as_other_user_if_needed /usr/share/elasticsearch/bin/elasticsearch 