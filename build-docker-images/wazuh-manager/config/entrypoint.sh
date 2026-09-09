#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

# Run initialization and configuration
bash /etc/cont-init.d/0-wazuh-init

# Start Wazuh Manager (may log warnings in environments without certs)
bash /etc/cont-init.d/1-manager

# Tail the main log to stdout so Docker captures it
tail -F /var/wazuh-manager/logs/wazuh-manager.log &
TAIL_PID=$!

# Stop Wazuh and the log tail. Used both for a graceful shutdown (SIGTERM/
# SIGINT/SIGQUIT, exit 0) and when supervision below detects a dead/broken
# daemon (exit 1, so the failure is visible in `docker inspect` and any
# restart policy other than "always" would still react correctly).
_stop() {
    exit_code="${1:-0}"
    echo "Stopping Wazuh Manager..."
    /var/wazuh-manager/bin/wazuh-manager-control stop 2>/dev/null || true
    kill "${TAIL_PID}" 2>/dev/null || true
    exit "${exit_code}"
}
trap '_stop 0' SIGTERM SIGINT SIGQUIT

# Grace period before the first supervision check: mirrors the compose
# healthcheck's own start_period (60s), so we don't kill the container while
# the manager daemons are still coming up.
STARTUP_GRACE_PERIOD=60
CHECK_INTERVAL=15

# Same default as cont-init.d/0-wazuh-init: master unless WAZUH_NODE_TYPE=worker
# is set (only multi-node/docker-compose.yml's wazuh.worker service sets it).
WAZUH_NODE_TYPE="${WAZUH_NODE_TYPE:-master}"

# Same reader the core wazuh-manager-control script itself uses to decide
# whether to start authd (start_service(), "auth.disabled: true" case).
WAZUH_MANAGER_CONF="/var/wazuh-manager/bin/wazuh-manager-conf -H /var/wazuh-manager -f /var/wazuh-manager/etc/wazuh-manager.conf"

# Supervise the manager: if a critical daemon is not running, exit non-zero so
# the container dies and `restart: always` (single-node/multi-node
# docker-compose.yml) actually gets a chance to bring it back. Without this,
# tail -F never exits on its own regardless of what happens to the daemons
# started by wazuh-manager-control (see wazuh-docker#2626), so the container
# stays "Up" forever with a dead API/daemon and no restart is ever triggered.
#
# Same failure vocabulary as the compose healthchecks (fixed in #2642):
# wazuh-manager-control status's "not running"/"failed to start"/"refused its
# configuration" lines, not a fragile grep on arbitrary text -- these are
# exactly the three cases that set that script's own non-zero RETVAL.
#
# Two lines are excluded before matching those patterns, for daemons that
# wazuh-manager-control deliberately never starts but that its own status()
# does not know to exclude:
#   - apid: only runs on the master node (same exclusion the multi-node
#     worker healthcheck already applies with its own `grep -v apid`).
#   - authd: skipped by start_service() when auth.disabled: true is set in
#     wazuh-manager.conf, but status() has no matching exclusion for it --
#     a real bug in the core script (found by Julia while reviewing this
#     fix). Without compensating here, any deployment with
#     auth.disabled: true would restart-loop forever.
_manager_unhealthy() {
    exclude_pattern='^$'
    [ "${WAZUH_NODE_TYPE}" != "master" ] && exclude_pattern="${exclude_pattern}|apid"
    if [ "$(${WAZUH_MANAGER_CONF} get auth.disabled 2>/dev/null)" = "true" ]; then
        exclude_pattern="${exclude_pattern}|authd"
    fi

    /var/wazuh-manager/bin/wazuh-manager-control status 2>/dev/null \
        | grep -vE "${exclude_pattern}" \
        | grep -qE 'not running|failed to start|refused its configuration'
}

sleep "${STARTUP_GRACE_PERIOD}"
while kill -0 "${TAIL_PID}" 2>/dev/null; do
    if _manager_unhealthy; then
        echo "Wazuh Manager is not running as expected, exiting so the container can be restarted..."
        _stop 1
    fi
    sleep "${CHECK_INTERVAL}" &
    wait $!
done

wait "${TAIL_PID}"
