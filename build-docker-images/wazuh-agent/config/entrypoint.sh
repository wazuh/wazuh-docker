#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

# Run initialization and configuration
bash /etc/cont-init.d/0-wazuh-init

# Start Wazuh Agent (may log warnings if manager address is not configured)
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
