filebeatout1=$(docker exec multi-node_wazuh.master_1 sh -c 'filebeat test output')
filebeatstatus1=$(echo "${filebeatout1}" | grep -c OK)
if [[ filebeatstatus1 -eq 7 ]]; then
  echo "No errors in master filebeat"
else
  echo "Errors in master filebeat"
  echo "${filebeatout1}"
  exit 1
fi
filebeatout2=$(docker exec multi-node_wazuh.worker_1 sh -c 'filebeat test output')
filebeatstatus2=$(echo "${filebeatout2}" | grep -c OK)
if [[ filebeatstatus2 -eq 7 ]]; then
 echo "No errors in worker filebeat"
else
 echo "Errors in worker filebeat"
 echo "${filebeatout2}"
 exit 1
fi