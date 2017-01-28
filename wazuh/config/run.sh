#!/bin/bash

#
# OSSEC container bootstrap. See the README for information of the environment
# variables expected by this script.
#

#

#
# Startup the services
#

source /data_dirs.env
FIRST_TIME_INSTALLATION=false
DATA_PATH=/var/ossec/data

for ossecdir in "${DATA_DIRS[@]}"; do
  if [ ! -e "${DATA_PATH}/${ossecdir}" ]
  then
    echo "Installing ${ossecdir}"
    cp -pr /var/ossec/${ossecdir}-template ${DATA_PATH}/${ossecdir}
    FIRST_TIME_INSTALLATION=true
  fi
done

touch ${DATA_PATH}/process_list
chgrp ossec ${DATA_PATH}/process_list
chmod g+rw ${DATA_PATH}/process_list

AUTO_ENROLLMENT_ENABLED=${AUTO_ENROLLMENT_ENABLED:-true}

if [ $FIRST_TIME_INSTALLATION == true ]
then

  if [ $AUTO_ENROLLMENT_ENABLED == true ]
  then
    if [ ! -e ${DATA_PATH}/etc/sslmanager.key ]
    then
      echo "Creating ossec-authd key and cert"
      openssl genrsa -out ${DATA_PATH}/etc/sslmanager.key 4096
      openssl req -new -x509 -key ${DATA_PATH}/etc/sslmanager.key\
        -out ${DATA_PATH}/etc/sslmanager.cert -days 3650\
        -subj /CN=${HOSTNAME}/
    fi
  fi
  #
  # Support SYSLOG forwarding, if configured
  #
  SYSLOG_FORWADING_ENABLED=${SYSLOG_FORWADING_ENABLED:-false}
  if [ $SYSLOG_FORWADING_ENABLED == true ]
  then
    if [ -z "$SYSLOG_FORWARDING_SERVER_IP" ]
    then
      echo "Cannot setup sylog forwarding because SYSLOG_FORWARDING_SERVER_IP is not defined"
    else
      SYSLOG_FORWARDING_SERVER_PORT=${SYSLOG_FORWARDING_SERVER_PORT:-514}
      SYSLOG_FORWARDING_FORMAT=${SYSLOG_FORWARDING_FORMAT:-default}
      SYSLOG_XML_SNIPPET="\
  <syslog_output>\n\
    <server>${SYSLOG_FORWARDING_SERVER_IP}</server>\n\
    <port>${SYSLOG_FORWARDING_SERVER_PORT}</port>\n\
    <format>${SYSLOG_FORWARDING_FORMAT}</format>\n\
  </syslog_output>";

      cat /var/ossec/etc/ossec.conf |\
        perl -pe "s,<ossec_config>,<ossec_config>\n${SYSLOG_XML_SNIPPET}\n," \
        > /var/ossec/etc/ossec.conf-new
      mv -f /var/ossec/etc/ossec.conf-new /var/ossec/etc/ossec.conf
      chgrp ossec /var/ossec/etc/ossec.conf
      /var/ossec/bin/ossec-control enable client-syslog
    fi
  fi
fi

function ossec_shutdown(){
  /var/ossec/bin/ossec-control stop;
  if [ $AUTO_ENROLLMENT_ENABLED == true ]
  then
     kill $AUTHD_PID
  fi
}

# Trap exit signals and do a proper shutdown
trap "ossec_shutdown; exit" SIGINT SIGTERM

chmod -R g+rw ${DATA_PATH}


if [ $AUTO_ENROLLMENT_ENABLED == true ]
then
  echo "Starting ossec-authd..."
  /var/ossec/bin/ossec-authd -p 1515 -g ossec $AUTHD_OPTIONS >/dev/null 2>&1 &
  AUTHD_PID=$!
fi
sleep 15 # give ossec a reasonable amount of time to start before checking status
LAST_OK_DATE=`date +%s`

## Update rules and decoders with Wazuh Ruleset
#cd /var/ossec/update/ruleset && python ossec_ruleset.py

/bin/node /var/ossec/api/app.js &
/usr/bin/filebeat.sh &
/var/ossec/bin/ossec-control restart


tail -f /var/ossec/logs/ossec.log
