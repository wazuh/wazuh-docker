#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
#
# OSSEC container bootstrap. See the README for information of the environment
# variables expected by this script.
#

set -e

##############################################################################
# Set elasticsearch url.
##############################################################################

if [ "x${ELASTICSEARCH_URL}" = "x" ]; then
  el_url="http://elasticsearch:9200"
else
  el_url="${ELASTICSEARCH_URL}"
fi

echo "ENTRYPOINT - Elasticsearch url: $el_url"

##############################################################################
# Get Logstash credentials.
##############################################################################

LOGSTASH_USER=""
LOGSTASH_PASS=""

if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
  LOGSTASH_USER=${SECURITY_LOGSTASH_USER}
  LOGSTASH_PASS=${SECURITY_LOGSTASH_PASS}
else
  input=${SECURITY_CREDENTIALS_FILE}
  while IFS= read -r line
  do
    if [[ $line == *"LOGSTASH_PASSWORD"* ]]; then
      arrIN=(${line//:/ })
      LOGSTASH_PASS=${arrIN[1]}
    elif [[ $line == *"LOGSTASH_USER"* ]]; then
      arrIN=(${line//:/ })
      LOGSTASH_USER=${arrIN[1]}
    fi
  done < "$input"
 
fi

echo "ENTRYPOINT - Logstash credentials obtained."

##############################################################################
# Set authentication for curl command. 
##############################################################################

if [ ${SECURITY_ENABLED} != "no" ]; then
  auth="-u ${LOGSTASH_USER}:${LOGSTASH_PASS} -k"
elif [ ${ENABLED_XPACK} != "true" || "x${ELASTICSEARCH_USERNAME}" = "x" || "x${ELASTICSEARCH_PASSWORD}" = "x" ]; then
  auth=""
else
  auth="--user ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}"
fi

echo "ENTRYPOINT - curl authentication established"


##############################################################################
# Customize logstash output ip.
##############################################################################

if [ "$LOGSTASH_OUTPUT" != "" ]; then
  >&2 echo "ENTRYPOINT - Customize Logstash ouput ip."
  sed -i 's|http://elasticsearch:9200|'$LOGSTASH_OUTPUT'|g' /usr/share/logstash/config/logstash.yml

  if [[ "$PIPELINE_FROM_FILE" == "false" ]]; then
    sed -i 's|elasticsearch:9200|'$LOGSTASH_OUTPUT'|g' /usr/share/logstash/pipeline/01-wazuh.conf
  fi
fi


##############################################################################
# Waiting for elasticsearch.
##############################################################################

until curl $auth -XGET $el_url; do
  >&2 echo "ENTRYPOINT - Elastic is unavailable - sleeping."
  sleep 5
done

sleep 2

>&2 echo "ENTRYPOINT - Elasticsearch is up."


##############################################################################
# Create keystore if security is enabled.
##############################################################################

if [[ $SECURITY_ENABLED == "yes" ]]; then

  echo "ENTRYPOINT - Create Keystore."

  ## Create secure keystore
  SECURITY_RANDOM_PASS=`date +%s | sha256sum | base64 | head -c 32 ; echo`
  export LOGSTASH_KEYSTORE_PASS=$SECURITY_RANDOM_PASS
  /usr/share/logstash/bin/logstash-keystore --path.settings /usr/share/logstash/config create

  ## Settings for logstash.yml
  bash /usr/share/logstash/config/10-entrypoint_configuration.sh 

  ## Add keys to the keystore
  echo -e "$LOGSTASH_USER" | /usr/share/logstash/bin/logstash-keystore --path.settings /usr/share/logstash/config add LOGSTASH_KS_USER
  echo -e "$LOGSTASH_PASS" | /usr/share/logstash/bin/logstash-keystore --path.settings /usr/share/logstash/config add LOGSTASH_KS_PASS

fi
  

##############################################################################
# Waiting for wazuh alerts template
##############################################################################

strlen=0

while [[ $strlen -eq 0 ]]
do
  template=$(curl $auth $el_url/_cat/templates/wazuh -s)
  strlen=${#template}
  >&2 echo "ENTRYPOINT - Wazuh alerts template not loaded - sleeping."
  sleep 2
done

sleep 2

>&2 echo "ENTRYPOINT - Wazuh alerts template is loaded."


##############################################################################
# Remove credentials file
##############################################################################

>&2 echo "ENTRYPOINT - Removing unnecessary files."

if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
  echo "ENTRYPOINT - Security credentials file not used. Nothing to do."
else
  shred -zvu ${SECURITY_CREDENTIALS_FILE}
fi

>&2 echo "ENTRYPOINT - Unnecessary files removed."

##############################################################################
# Map environment variables to entries in logstash.yml.
# Note that this will mutate logstash.yml in place if any such settings are found.
# This may be undesirable, especially if logstash.yml is bind-mounted from the
# host system.
##############################################################################

env2yaml /usr/share/logstash/config/logstash.yml

export LS_JAVA_OPTS="-Dls.cgroup.cpuacct.path.override=/ -Dls.cgroup.cpu.path.override=/ $LS_JAVA_OPTS"

if [[ -z $1 ]] || [[ ${1:0:1} == '-' ]] ; then
  exec logstash "$@"
else
  exec "$@"
fi
