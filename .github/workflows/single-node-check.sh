log=$(docker exec single-node_wazuh.manager_1 sh -c 'cat /var/ossec/logs/ossec.log' | grep -P "ERR|WARN|CRIT")
if [[ -z "$log" ]]; then
 echo "No errors in master ossec.log"
else
 echo "Errors in master ossec.log:"
 echo "${log}"
 exit 1
fi