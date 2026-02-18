log1=$(docker exec multi-node_wazuh.master_1 sh -c 'cat /var/wazuh-manager/logs/wazuh-manager.log' | grep -P "ERR|WARN|CRIT")
if [[ -z "$log1" ]]; then
  echo "No errors in master wazuh-manager.log"
else
  echo "Errors in master wazuh-manager.log:"
  echo "${log1}"
  exit 1
fi
log2=$(docker exec multi-node_wazuh.worker_1 sh -c 'cat /var/wazuh-manager/logs/wazuh-manager.log' | grep -P "ERR|WARN|CRIT")
if [[ -z "${log2}" ]]; then
  echo "No errors in worker wazuh-manager.log"
else
  echo "Errors in worker wazuh-manager.log:"
  echo "${log2}"
  exit 1
fi