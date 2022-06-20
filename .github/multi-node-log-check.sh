log1=$(docker exec multi-node_wazuh.master_1 sh -c 'cat /var/ossec/logs/ossec.log' | grep -P "ERR|WARN|CRIT")
if [[ -z "$log1" ]]; then
  echo "No errors in master ossec.log"
else
  echo "Errors in master ossec.log:"
  echo "${log1}"
  exit 1
fi
log2=$(docker exec multi-node_wazuh.worker_1 sh -c 'cat /var/ossec/logs/ossec.log' | grep -P "ERR|WARN|CRIT")
if [[ -z "${log2}" ]]; then
  echo "No errors in worker ossec.log"
else
  echo "Errors in worker ossec.log:"
  echo "${log2}"
  exit 1
fi