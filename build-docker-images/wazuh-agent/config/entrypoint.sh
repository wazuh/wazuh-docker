#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

# Run initialization and configuration. A failure here means the agent has no
# usable manager endpoint, so stop instead of starting an agent that can only
# retry against a placeholder.
bash /etc/cont-init.d/0-wazuh-init || exit 1

# Start Wazuh Agent
bash /etc/cont-init.d/1-agent

# Tail the main log to stdout so Docker captures it
tail -F /var/ossec/logs/ossec.log &
TAIL_PID=$!

# Graceful shutdown: stop Wazuh and exit cleanly on SIGTERM/SIGINT
_stop() {
    echo "Stopping Wazuh Agent..."
    /var/ossec/bin/wazuh-control stop 2>/dev/null || true
    kill "${TAIL_PID}" 2>/dev/null || true
}
trap _stop SIGTERM SIGINT SIGQUIT

wait "${TAIL_PID}"
