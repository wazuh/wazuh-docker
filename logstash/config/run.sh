#!/bin/bash

#
# OSSEC container bootstrap. See the README for information of the environment
# variables expected by this script.
#

#

#
# Apply Templates
#

set -e

# Add logstash as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- logstash "$@"
fi

# Run as user "logstash" if the command is "logstash"
if [ "$1" = 'logstash' ]; then
	set -- gosu logstash "$@"
fi

exec "$@"

#echo "Wait one min to logstash restart"
#sleep 60
#curl -XPUT -v -H "Expect:"  "http://elasticsearch:9200/_template/ossec" -d@/etc/logstash/elastic5-ossec-template.json
