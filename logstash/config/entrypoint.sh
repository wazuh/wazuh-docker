#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
#
# OSSEC container bootstrap. See the README for information of the environment
# variables expected by this script.
#

set -e

##############################################################################
# Waiting for elasticsearch
##############################################################################

if [ "x${ELASTICSEARCH_URL}" = "x" ]; then
  el_url="http://elasticsearch:9200"
else
  el_url="${ELASTICSEARCH_URL}"
fi

until curl -XGET $el_url; do
  >&2 echo "Elastic is unavailable - sleeping."
  sleep 5
done

sleep 2

>&2 echo "Elasticsearch is up."

##############################################################################
# Waiting for wazuh alerts template
##############################################################################

strlen=0

while [[ $strlen -eq 0 ]]
do
  template=$(curl $el_url/_cat/templates/wazuh -s)
  strlen=${#template}
  >&2 echo "Wazuh alerts template not loaded - sleeping."
  sleep 2
done

sleep 2

>&2 echo "Wazuh alerts template is loaded."

##############################################################################
# Customize logstash output ip
##############################################################################

if [ "$LOGSTASH_OUTPUT" != "" ]; then
  >&2 echo "Customize Logstash ouput ip."
  sed -i "s/elasticsearch:9200/$LOGSTASH_OUTPUT/" /usr/share/logstash/pipeline/01-wazuh.conf
  sed -i "s/elasticsearch:9200/$LOGSTASH_OUTPUT/" /usr/share/logstash/config/logstash.yml 
fi

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
