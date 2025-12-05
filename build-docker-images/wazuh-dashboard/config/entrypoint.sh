#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

# Run Wazuh dashboard, using environment variables to
# set longopts defining Wazuh dashboard's configuration.
#
# eg. Setting the environment variable:
#
#       OPENSEARCH_STARTUPTIMEOUT=60
#
# will cause OpenSearch-Dashboards to be invoked with:
#
#       --opensearch.startupTimeout=60

# Setup Home Directory
export OPENSEARCH_DASHBOARDS_HOME=/usr/share/wazuh-dashboard
export PATH=$OPENSEARCH_DASHBOARDS_HOME/bin:$PATH
DASHBOARD_USERNAME="${DASHBOARD_USERNAME:-kibanaserver}"
DASHBOARD_PASSWORD="${DASHBOARD_PASSWORD:-kibanaserver}"
export OPENSEARCH_DASHBOARDS_CONFIG=/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml

# Create and configure Wazuh dashboard keystore

yes | $OPENSEARCH_DASHBOARDS_HOME/bin/opensearch-dashboards-keystore create --allow-root && \
echo $DASHBOARD_USERNAME | $OPENSEARCH_DASHBOARDS_HOME/bin/opensearch-dashboards-keystore add opensearch.username --stdin --allow-root && \
echo $DASHBOARD_PASSWORD | $OPENSEARCH_DASHBOARDS_HOME/bin/opensearch-dashboards-keystore add opensearch.password --stdin --allow-root

/wazuh_app_config.sh

opensearch_dashboards_vars=(
    opensearch.hosts
    server.port
    server.host
    opensearch.username
    opensearch.password
)

function runOpensearchDashboards {
    longopts=()
    for opensearch_dashboards_var in ${opensearch_dashboards_vars[*]}; do
        # 'opensearch.hosts' -> 'OPENSEARCH_URL'
        env_var=$(echo ${opensearch_dashboards_var^^} | tr . _)

        # Indirectly lookup env var values via the name of the var.
        # REF: http://tldp.org/LDP/abs/html/bashver2.html#EX78
        value=${!env_var}
        if [[ -n $value ]]; then
            longopt="--${opensearch_dashboards_var}=${value}"
            longopts+=("${longopt}")
        fi
    done

    # Files created at run-time should be group-writable, for Openshift's sake.
    umask 0002

    # TO DO:
    # Confirm with Mihir if this is necessary

    # The virtual file /proc/self/cgroup should list the current cgroup
    # membership. For each hierarchy, you can follow the cgroup path from
    # this file to the cgroup filesystem (usually /sys/fs/cgroup/) and
    # introspect the statistics for the cgroup for the given
    # hierarchy. Alas, Docker breaks this by mounting the container
    # statistics at the root while leaving the cgroup paths as the actual
    # paths. Therefore, OpenSearch-Dashboards provides a mechanism to override
    # reading the cgroup path from /proc/self/cgroup and instead uses the
    # cgroup path defined the configuration properties
    # cpu.cgroup.path.override and cpuacct.cgroup.path.override.
    # Therefore, we set this value here so that cgroup statistics are
    # available for the container this process will run in.

    exec "$@" \
        --ops.cGroupOverrides.cpuPath=/ \
        --ops.cGroupOverrides.cpuAcctPath=/ \
        "${longopts[@]}"
}

# Prepend "opensearch-dashboards" command if no argument was provided or if the
# first argument looks like a flag (i.e. starts with a dash).
if [ $# -eq 0 ] || [ "${1:0:1}" = '-' ]; then
    set -- opensearch-dashboards "$@"
fi

if [ "$1" = "opensearch-dashboards" ]; then
    runOpensearchDashboards "$@"
else
    exec "$@"
fi