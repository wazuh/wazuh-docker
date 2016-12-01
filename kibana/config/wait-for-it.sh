#!/bin/bash

set -e

host="$1"
shift
cmd="kibana"

until curl -XGET $host:9200; do
  >&2 echo "Elastic is unavailable - sleeping"
  sleep 1
done

sleep 60

>&2 echo "Elastic is up - executing command"
exec $cmd
