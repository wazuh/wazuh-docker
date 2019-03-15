#!/bin/bash
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

/usr/local/bin/docker-entrypoint
