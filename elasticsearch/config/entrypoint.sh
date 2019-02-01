#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

# For more information https://github.com/elastic/elasticsearch-docker/blob/6.5.4/build/elasticsearch/bin/docker-entrypoint.sh

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

# Run load settings script.

./load_settings.sh &

# Execute elasticsearch

run_as_other_user_if_needed /usr/share/elasticsearch/bin/elasticsearch 
