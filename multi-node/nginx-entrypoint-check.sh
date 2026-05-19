#!/bin/bash

wait_for_upstream() {
  host=$1
  port=$2

  echo "Waiting for $host:$port..."
  while ! nc -z "$host" "$port"; do
    echo "Still waiting for $host:$port..."
    sleep 1
  done
  echo "$host:$port is available!"
}

wait_for_upstream wazuh-master 1514
wait_for_upstream wazuh-worker 1514

echo "All upstreams are reachable, starting native entrypoint..."

exec /docker-entrypoint.sh nginx -g "daemon off;"
