#!/bin/bash

set -m

# Add elasticsearch as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- elasticsearch "$@"
fi

if [ "$NODE_NAME" = "" ]; then
	export NODE_NAME=$HOSTNAME
fi

if [ "x${ELASTICSEARCH_URL}" = "x" ]; then
  el_url="https://elasticsearch:9200"
else
  el_url="${ELASTICSEARCH_URL}"
fi

# Run as user "elasticsearch" if the command is "elasticsearch"
if [ "$1" = 'elasticsearch' -a "$(id -u)" = '0' ]; then
	set -- su-exec eulasticsearch "$@"
	ES_JAVA_OPTS="-Des.network.host=$NETWORK_HOST -Des.logger.level=$LOG_LEVEL -Xms$HEAP_SIZE -Xmx$HEAP_SIZE"  "$@" &
else
	"$@" &
fi

./load_settings.sh &

su -c "elasticsearch " elasticsearch