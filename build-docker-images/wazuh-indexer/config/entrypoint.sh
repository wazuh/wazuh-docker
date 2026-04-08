#!/bin/bash

# Copyright OpenSearch Contributors
# SPDX-License-Identifier: Apache-2.0

# This script specify the entrypoint startup actions for opensearch
# It will start both opensearch and performance analyzer plugin cli
# If either process failed, the entire docker container will be removed
# in favor of a newly started container

# Export OpenSearch Home
export OPENSEARCH_HOME=/usr/share/wazuh-indexer
export OPENSEARCH_PATH_CONF=$OPENSEARCH_HOME/config
export CONFIG_FILE=${OPENSEARCH_PATH_CONF}/opensearch.yml
export PATH=$OPENSEARCH_HOME/bin:$PATH


# The virtual file /proc/self/cgroup should list the current cgroup
# membership. For each hierarchy, you can follow the cgroup path from
# this file to the cgroup filesystem (usually /sys/fs/cgroup/) and
# introspect the statistics for the cgroup for the given
# hierarchy. Alas, Docker breaks this by mounting the container
# statistics at the root while leaving the cgroup paths as the actual
# paths. Therefore, OpenSearch provides a mechanism to override
# reading the cgroup path from /proc/self/cgroup and instead uses the
# cgroup path defined the JVM system property
# opensearch.cgroups.hierarchy.override. Therefore, we set this value here so
# that cgroup statistics are available for the container this process
# will run in.
export OPENSEARCH_JAVA_OPTS="-Dopensearch.cgroups.hierarchy.override=/ $OPENSEARCH_JAVA_OPTS"

# Start up the opensearch and performance analyzer agent processes.
# When either of them halts, this script exits, or we receive a SIGTERM or SIGINT signal then we want to kill both these processes.
function runOpensearch {
    # Files created by OpenSearch should always be group writable too
    umask 0002

    if [[ "$(id -u)" == "0" ]]; then
        echo "Wazuh indexer cannot run as root. Please start your container as another user."
        exit 1
    fi

    # Parse Docker env vars to customize Wazuh indexer / OpenSearch configuration
    #
    # e.g. Setting the env var cluster.name=testcluster
    # will cause Wazuh indexer to be invoked with -Ecluster.name=testcluster
    opensearch_opts=()
    while IFS='=' read -r envvar_key envvar_value
    do
        # OpenSearch settings need to have at least two dot separated lowercase
        # words, e.g. `cluster.name`, except for `processors` which we handle
        # specially
        if [[ "$envvar_key" =~ ^[a-z0-9_]+\.[a-z0-9_]+ || "$envvar_key" == "processors" ]]; then
            if [[ ! -z $envvar_value ]]; then
            opensearch_opt="-E${envvar_key}=${envvar_value}"
            opensearch_opts+=("${opensearch_opt}")
            fi
        fi
    done < <(env)

    # Start opensearch
    exec "$@" "${opensearch_opts[@]}"

}

function configureOpensearch {
# Update opensearch.yml with NODES_DN if set
if [ -n "$NODES_DN" ]; then

  CLEAN_NODES_DN=$(echo "$NODES_DN" | sed 's/^["'\'']//; s/["'\'']$//; s/""/"/g')
  NODES_DN_YAML=$(echo $CLEAN_NODES_DN | tr ';' '\n' | sed 's/^/- "/; s/$/"/')

  awk '
    /^plugins\.security\.nodes_dn:/ {in_block=1; print; next}
    in_block && /^[^#[:space:]-]/ {in_block=0}
    !in_block || /^plugins\.security\.nodes_dn:/ {next}
    {print}
  ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"

  awk -v repl="$NODES_DN_YAML" '
    /^plugins\.security\.nodes_dn:/ {
      print "plugins.security.nodes_dn:";
      print repl;
      skip=1; next
    }
    skip && /^[^#[:space:]-]/ {skip=0}
    !skip
  ' "${CONFIG_FILE}" > "${CONFIG_FILE}.new"
  mv "${CONFIG_FILE}.new" "$CONFIG_FILE"
  rm -f "${CONFIG_FILE}.tmp"
fi
}

# Prepend "opensearch" command if no argument was provided or if the first
# argument looks like a flag (i.e. starts with a dash).

configureOpensearch

if [ $# -eq 0 ] || [ "${1:0:1}" = '-' ]; then
    set -- opensearch "$@"
fi

if [ "$1" = "opensearch" ]; then
    # If the first argument is opensearch, then run the setup script.
    runOpensearch "$@"
else
    # Otherwise, just exec the command.
    exec "$@"
fi