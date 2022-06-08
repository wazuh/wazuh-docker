fbout1=$(docker exec multi-node_wazuh.master_1 sh -c 'filebeat test output')
fbstatus1=$(echo "${fbout1}" | grep -c OK)
if [[ fbstatus1 -eq 7 ]]; then
 echo "No errors in master filebeat"
else
 echo "Errors in master filebeat"
 echo "${fbout1}"
 exit 1
fi
fbout2=$(docker exec multi-node_wazuh.worker_1 sh -c 'filebeat test output')
fbstatus2=$(echo "${fbout2}" | grep -c OK)
if [[ fbstatus2 -eq 7 ]]; then
 echo "No errors in worker filebeat"
else
 echo "Errors in worker filebeat"
 echo "${fbout2}"
 exit 1
fi