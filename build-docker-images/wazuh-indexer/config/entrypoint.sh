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
SERVICE_USER=wazuh-indexer

# Credentials are resolved as root, from the environment (see
# tools/utils/deployment/credentials-conf.sh), and the indexer itself runs as
# SERVICE_USER: the entrypoint re-executes itself once they are stored.
if [ "$(id -u)" = "0" ]; then
    export WAZUH_INDEXER_CONFIG_DIR="$OPENSEARCH_PATH_CONF"

    # The marker is on the data volume, the digests in this container's
    # internal_users.yml. A recreated container has the placeholders again
    # while the marker says resolution is done, and a cluster that has not
    # initialized its security index yet would load them: resolve again.
    if [ -f /var/lib/wazuh-indexer/.initialized ] && \
       grep -qE 'hash: "\$\{WAZUH_INDEXER_[A-Z]+_PASSWORD\}"' "$OPENSEARCH_PATH_CONF/opensearch-security/internal_users.yml"; then
        rm -f /var/lib/wazuh-indexer/.initialized
    fi

    # Until the node is initialized, the resolver would generate these itself,
    # inside this container, where nobody could read them back.
    if [ ! -f /var/lib/wazuh-indexer/.initialized ]; then
        missing=""
        for key in WAZUH_INDEXER_ADMIN_PASSWORD WAZUH_INDEXER_KIBANASERVER_PASSWORD WAZUH_INDEXER_MANAGER_PASSWORD; do
            [ -n "${!key}" ] && continue
            [ "$key" = WAZUH_INDEXER_KIBANASERVER_PASSWORD ] && [ -n "$DASHBOARD_PASSWORD" ] && continue
            missing="$missing $key"
        done
        if [ -n "$missing" ]; then
            for key in $missing; do
                echo "credentials: MISSING $key" >&2
            done
            echo "credentials: create the deployment credentials with tools/utils/deployment/credentials-conf.sh" >&2
            exit 1
        fi
    fi

    if ! "$OPENSEARCH_HOME/bin/resolve-credentials.sh" --prestart; then
        echo "credentials: the indexer cannot start until the keys above are set in its environment" >&2
        echo "credentials: (config/credentials/indexer.env, created by tools/utils/deployment/credentials-conf.sh)" >&2
        exit 1
    fi
    unset WAZUH_INDEXER_ADMIN_PASSWORD WAZUH_INDEXER_KIBANASERVER_PASSWORD \
          WAZUH_INDEXER_MANAGER_PASSWORD DASHBOARD_PASSWORD

    exec setpriv --reuid="$SERVICE_USER" --regid="$SERVICE_USER" --init-groups "$0" "$@"
fi


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

    # Start Wazuh Engine
    if [ -x "$OPENSEARCH_HOME/engine/run_engine.sh" ]; then
        nohup "$OPENSEARCH_HOME/engine/run_engine.sh" > /dev/null 2>&1 &
        echo $! > /run/wazuh-indexer/wazuh-engine.pid
    fi

    # Start opensearch
    exec "$@" "${opensearch_opts[@]}"

}

# Replaces the list under a top-level opensearch.yml key with the given
# semicolon-separated DNs.
function set_dn_list {
  local key="$1" list="$2" clean yaml
  clean=$(echo "$list" | sed 's/^["'\'']//; s/["'\'']$//; s/""/"/g')
  yaml=$(echo "$clean" | tr ';' '\n' | sed 's/^/- "/; s/$/"/')
  awk -v key="$key" -v repl="$yaml" '
    index($0, key ":") == 1 { print key ":"; print repl; skip=1; next }
    skip && /^[[:space:]]*#?[[:space:]]*-[[:space:]]/ { next }
    { skip=0; print }
  ' "$CONFIG_FILE" > "${CONFIG_FILE}.new" && cat "${CONFIG_FILE}.new" > "$CONFIG_FILE"
  rm -f "${CONFIG_FILE}.new"
}

# The package ships both lists empty and fills them only when it issues the
# certificates itself; here the certificates are mounted, so their DNs come
# from the environment.
function configureOpensearch {
  if [ -n "$NODES_DN" ]; then
    set_dn_list plugins.security.nodes_dn "$NODES_DN"
  fi
  set_dn_list plugins.security.authcz.admin_dn "${ADMIN_DN:-CN=admin,OU=Wazuh,O=Wazuh,L=California,C=US}"
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