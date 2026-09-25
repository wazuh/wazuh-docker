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
SERVICE_USER=wazuh-dashboard

# Credentials are resolved as root, from the environment (see
# tools/utils/deployment/credentials-conf.sh), and the dashboard itself runs
# as SERVICE_USER: the entrypoint re-executes itself once they are stored.
if [ "$(id -u)" = "0" ]; then
    # The resolver and the keystore agree on this directory only if it is set.
    export OSD_PATH_CONF="$OPENSEARCH_DASHBOARDS_HOME/config"

    # Names the Compose files and Kubernetes manifests have always used.
    if [ -z "$WAZUH_INDEXER_KIBANASERVER_PASSWORD" ] && [ -n "$DASHBOARD_PASSWORD" ]; then
        export WAZUH_INDEXER_KIBANASERVER_PASSWORD="$DASHBOARD_PASSWORD"
    fi
    if [ -z "$WAZUH_MANAGER_WUI_PASSWORD" ] && [ -n "$API_PASSWORD" ]; then
        export WAZUH_MANAGER_WUI_PASSWORD="$API_PASSWORD"
    fi
    if [ -n "$DASHBOARD_USERNAME" ] && [ "$DASHBOARD_USERNAME" != "kibanaserver" ]; then
        echo "credentials: DASHBOARD_USERNAME is ignored; the dashboard authenticates to the indexer as kibanaserver" >&2
    fi
    unset DASHBOARD_PASSWORD API_PASSWORD

    setpriv --reuid="$SERVICE_USER" --regid="$SERVICE_USER" --init-groups /wazuh_dashboard_config.sh || exit 1

    if ! "$OPENSEARCH_DASHBOARDS_HOME/bin/resolve-credentials" --prestart; then
        echo "credentials: the dashboard cannot start until the keys above are set in its environment" >&2
        echo "credentials: (config/credentials/dashboard.env, created by tools/utils/deployment/credentials-conf.sh)" >&2
        exit 1
    fi
    unset WAZUH_INDEXER_KIBANASERVER_PASSWORD WAZUH_MANAGER_WUI_PASSWORD

    exec setpriv --reuid="$SERVICE_USER" --regid="$SERVICE_USER" --init-groups "$0" "$@"
fi

opensearch_dashboards_vars=(
    opensearch.hosts
    server.port
    server.host
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