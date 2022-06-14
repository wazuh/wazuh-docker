filebeatout=$(docker exec single-node_wazuh.manager_1 sh -c 'filebeat test output')
filebeatstatus=$(echo "${filebeatout}" | grep -c OK)
if [[ filebeatstatus -eq 7 ]]; then
  echo "No errors in filebeat"
else
  echo "Errors in filebeat"
  echo "${filebeatout}"
  exit 1
fi