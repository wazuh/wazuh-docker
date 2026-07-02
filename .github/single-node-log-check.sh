log=$(docker exec single-node_wazuh.manager_1 sh -c 'cat /var/wazuh-manager/logs/wazuh-manager.log' | grep -P "ERR|WARN|CRIT")
if [[ -z "$log" ]]; then
  echo "No errors in wazuh-manager.log"
else
  echo "Errors in wazuh-manager.log:"
  echo "${log}"
  exit 1
fi
