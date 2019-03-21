#!/bin/bash -e
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
#
# OSSEC container bootstrap. See the README for information of the environment
# variables expected by this script.
#



##############################################################################
# Customize logstash output ip
##############################################################################
if [ "$LOGSTASH_OUTPUT" != "" ]; then
  sed -i "s/elasticsearch:9200/$LOGSTASH_OUTPUT:9200/" /usr/share/logstash/pipeline/01-wazuh.conf
  sed -i "s/elasticsearch:9200/$LOGSTASH_OUTPUT:9200/" /usr/share/logstash/config/logstash.yml 
fi

# Map environment variables to entries in logstash.yml.
# Note that this will mutate logstash.yml in place if any such settings are found.
# This may be undesirable, especially if logstash.yml is bind-mounted from the
# host system.

env2yaml /usr/share/logstash/config/logstash.yml

export LS_JAVA_OPTS="-Dls.cgroup.cpuacct.path.override=/ -Dls.cgroup.cpu.path.override=/ $LS_JAVA_OPTS"

if [[ -z $1 ]] || [[ ${1:0:1} == '-' ]] ; then
  exec logstash "$@"
else
  exec "$@"
fi
