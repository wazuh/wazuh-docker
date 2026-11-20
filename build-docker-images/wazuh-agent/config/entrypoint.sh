#!/bin/bash
# Wazuh Docker Copyright (C) Wazuh Inc. (License GPLv2)

# Run initialization and configuration. A failure here means the agent has no
# usable manager endpoint, so stop instead of starting an agent that can only
# retry against a placeholder.
bash /etc/cont-init.d/0-wazuh-init || exit 1

# Tail the main log to stdout so Docker captures it. Started before the agent,
# so the reason a daemon gives for not starting reaches the container log too.
tail -F /var/ossec/logs/ossec.log &
TAIL_PID=$!

# Start Wazuh Agent. wazuh-control start fails when a daemon does not come up
# (wazuh-agentd refusing an enrollment token the manager rejected, say) and
# stops what it started, so there is nothing left to run.
if ! bash /etc/cont-init.d/1-agent; then
    sleep 1
    kill "${TAIL_PID}" 2>/dev/null
    exit 1
fi

# Stop Wazuh and the log tail. Used both for a graceful shutdown (SIGTERM/
# SIGINT/SIGQUIT, exit 0) and when supervision below finds a dead daemon
# (exit 1, so the failure shows in `docker inspect` and the restart policy
# brings the container back).
_stop() {
    exit_code="${1:-0}"
    echo "Stopping Wazuh Agent..."
    /var/ossec/bin/wazuh-control stop 2>/dev/null || true
    kill "${TAIL_PID}" 2>/dev/null || true
    exit "${exit_code}"
}
trap '_stop 0' SIGTERM SIGINT SIGQUIT

# A daemon can still die after the start returned: wazuh-agentd keeps retrying
# an enrollment token the manager does not accept yet for up to 60 s before it
# gives up, past the start's own deadline, and any daemon can be killed later.
# tail -F never exits on its own, so without this the container would stay
# "Up" with no agent running and the restart policy would never fire (#2796,
# the same problem #2626 fixed for the manager image).
CHECK_INTERVAL=15

# Timeout for each status check: wazuh-control status waits for the control
# lock and has no upper bound of its own, and a hang here would otherwise block
# both failure detection and the SIGTERM trap above.
STATUS_TIMEOUT=10

# The agent restarts and reloads itself (a centralized configuration change, a
# restart requested by the manager) with wazuh-control, which holds its lock
# from the stop until the daemons are started again. Those checks are skipped
# while the process that holds the lock is alive, for at most BUSY_MAX_CHECKS
# in a row (the start alone may take 40 s), so a restart that hangs still ends
# in a restart of the container. A lock left by a dead process is reclaimed by
# status itself.
CONTROL_LOCK_PID="/var/ossec/var/start-script-lock/pid"
BUSY_MAX_CHECKS=8
busy_checks=0

_agent_busy() {
    local pid
    pid=$(cat "${CONTROL_LOCK_PID}" 2>/dev/null) && [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null
}

# Every agent daemon is always started, so any "not running" line of
# wazuh-control status is a failure. A status that times out is one too.
_agent_unhealthy() {
    local status_output
    status_output="$(timeout "${STATUS_TIMEOUT}" /var/ossec/bin/wazuh-control status 2>/dev/null)"
    [ $? -eq 124 ] && return 0
    echo "${status_output}" | grep -q 'not running'
}

while kill -0 "${TAIL_PID}" 2>/dev/null; do
    sleep "${CHECK_INTERVAL}" &
    wait $!
    # Busy is checked again after a failed status: the restart may have taken
    # the lock while status was already waiting for it.
    if _agent_busy || _agent_unhealthy; then
        if _agent_busy && [ "${busy_checks}" -lt "${BUSY_MAX_CHECKS}" ]; then
            busy_checks=$((busy_checks + 1))
        elif _agent_busy || _agent_unhealthy; then
            echo "Wazuh Agent is not running as expected, exiting so the container can be restarted..."
            timeout "${STATUS_TIMEOUT}" /var/ossec/bin/wazuh-control status 2>/dev/null
            _stop 1
        fi
    else
        busy_checks=0
    fi
done

wait "${TAIL_PID}"
