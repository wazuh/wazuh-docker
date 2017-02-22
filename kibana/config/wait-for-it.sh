#!/bin/bash

set -e

host="$1"
shift
cmd="kibana"

until curl -XGET $host:9200; do
  >&2 echo "Elastic is unavailable - sleeping"
  sleep 1
done

sleep 30

>&2 echo "Elastic is up - executing command"

if /usr/share/kibana/bin/kibana-plugin list | grep wazuh; then
  echo "Wazuh APP already installed"
else
  /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-2.0_5.2.1.zip
fi

exec $cmd
