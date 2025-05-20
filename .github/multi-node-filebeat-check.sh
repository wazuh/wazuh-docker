COMMAND_TO_EXECUTE="filebeat test output"

MASTER_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -E 'master')

if [ -z "$MASTER_CONTAINERS" ]; then
  echo "No containers were found with 'master' in their name."
else
  for MASTER_CONTAINERS in $MASTER_CONTAINERS; do
    FILEBEAT_OUTPUT=$(docker exec "$MASTER_CONTAINERS" $COMMAND_TO_EXECUTE)
    FILEBEAT_STATUS=$(echo "${FILEBEAT_OUTPUT}" | grep -c OK)
    if [[ $FILEBEAT_STATUS -eq 7 ]]; then
      echo "No errors in filebeat"
      echo "${FILEBEAT_OUTPUT}"
    else
      echo "Errors in filebeat"
      echo "${FILEBEAT_OUTPUT}"
      exit 1
    fi
  done
fi

MASTER_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -E 'worker')

if [ -z "$MASTER_CONTAINERS" ]; then
  echo "No containers were found with 'worker' in their name."
else
  for MASTER_CONTAINERS in $MASTER_CONTAINERS; do
    FILEBEAT_OUTPUT=$(docker exec "$MASTER_CONTAINERS" $COMMAND_TO_EXECUTE)
    FILEBEAT_STATUS=$(echo "${FILEBEAT_OUTPUT}" | grep -c OK)
    if [[ $FILEBEAT_STATUS -eq 7 ]]; then
      echo "No errors in filebeat"
      echo "${FILEBEAT_OUTPUT}"
    else
      echo "Errors in filebeat"
      echo "${FILEBEAT_OUTPUT}"
      exit 1
    fi
  done
fi