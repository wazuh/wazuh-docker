#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

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

WAZUH_INSTALL_PATH=/var/ossec
DATA_PATH=${WAZUH_INSTALL_PATH}/data

WAZUH_CONFIG_MOUNT=/wazuh-config-mount

print() {
    echo -e $1
}

error_and_exit() {
    echo "Error executing command: '$1'."
    echo 'Exiting.'
    exit 1
}

exec_cmd() {
    eval $1 > /dev/null 2>&1 || error_and_exit "$1"
}

exec_cmd_stdout() {
    eval $1 2>&1 || error_and_exit "$1"
}

edit_configuration() { # $1 -> setting,  $2 -> value
    sed -i "s/^config.$1\s=.*/config.$1 = \"$2\";/g" "${DATA_PATH}/api/configuration/config.js" || error_and_exit "sed (editing configuration)"
}

for ossecdir in "${DATA_DIRS[@]}"; do
  if [ ! -e "${DATA_PATH}/${ossecdir}" ]
  then
    print "Installing ${ossecdir}"
    exec_cmd "mkdir -p $(dirname ${DATA_PATH}/${ossecdir})"
    exec_cmd "cp -pr /var/ossec/${ossecdir}-template ${DATA_PATH}/${ossecdir}"
    FIRST_TIME_INSTALLATION=true
  fi
done

if [  -e ${WAZUH_INSTALL_PATH}/etc-template  ]
then
    cp -p /var/ossec/etc-template/internal_options.conf /var/ossec/etc/internal_options.conf
fi
rm /var/ossec/queue/db/.template.db

touch ${DATA_PATH}/process_list
chgrp ossec ${DATA_PATH}/process_list
chmod g+rw ${DATA_PATH}/process_list

AUTO_ENROLLMENT_ENABLED=${AUTO_ENROLLMENT_ENABLED:-true}
API_GENERATE_CERTS=${API_GENERATE_CERTS:-true}

if [ $FIRST_TIME_INSTALLATION == true ]
then
  if [ $AUTO_ENROLLMENT_ENABLED == true ]
  then
    if [ ! -e ${DATA_PATH}/etc/sslmanager.key ]
    then
      print "Creating ossec-authd key and cert"
      exec_cmd "openssl genrsa -out ${DATA_PATH}/etc/sslmanager.key 4096"
      exec_cmd "openssl req -new -x509 -key ${DATA_PATH}/etc/sslmanager.key -out ${DATA_PATH}/etc/sslmanager.cert -days 3650 -subj /CN=${HOSTNAME}/"
    fi
  fi
  if [ $API_GENERATE_CERTS == true ]
  then
    if [ ! -e ${DATA_PATH}/api/configuration/ssl/server.crt ]
    then
      print "Enabling Wazuh API HTTPS"
      edit_configuration "https" "yes"
      print "Create Wazuh API key and cert"
      exec_cmd "openssl genrsa -out ${DATA_PATH}/api/configuration/ssl/server.key 4096"
      exec_cmd "openssl req -new -x509 -key ${DATA_PATH}/api/configuration/ssl/server.key -out ${DATA_PATH}/api/configuration/ssl/server.crt -days 3650 -subj /CN=${HOSTNAME}/"
    fi
  fi
fi

##############################################################################
# Copy all files from $WAZUH_CONFIG_MOUNT to $DATA_PATH and respect
# destination files permissions
#
# For example, to mount the file /var/ossec/data/etc/ossec.conf, mount it at
# $WAZUH_CONFIG_MOUNT/etc/ossec.conf in your container and this code will
# replace the ossec.conf file in /var/ossec/data/etc with yours.
##############################################################################
if [ -e "$WAZUH_CONFIG_MOUNT" ]
then
  print "Identified Wazuh configuration files to mount..."

  exec_cmd_stdout "cp --verbose -r $WAZUH_CONFIG_MOUNT/* $DATA_PATH"
else
  print "No Wazuh configuration files to mount..."
fi

function ossec_shutdown(){
  ${WAZUH_INSTALL_PATH}/bin/ossec-control stop;
}

# Trap exit signals and do a proper shutdown
trap "ossec_shutdown; exit" SIGINT SIGTERM

chmod -R g+rw ${DATA_PATH}

##############################################################################
# Interpret any passed arguments (via docker command to this entrypoint) as
# paths or commands, and execute them.
#
# This can be useful for actions that need to be run before the services are
# started, such as "/var/ossec/bin/ossec-control enable agentless".
##############################################################################
for CUSTOM_COMMAND in "$@"
do
  echo "Executing command \`${CUSTOM_COMMAND}\`"
  exec_cmd_stdout "${CUSTOM_COMMAND}"
done

##############################################################################
# Change Wazuh API user credentials.
##############################################################################

pushd /var/ossec/api/configuration/auth/

echo "Change Wazuh API user credentials"
change_user="node htpasswd -b -c user $API_USER $API_PASS"
eval $change_user

popd


##############################################################################
# Customize filebeat output ip
##############################################################################
if [ "$FILEBEAT_OUTPUT" != "" ]; then
  sed -i "s/logstash:5000/$FILEBEAT_OUTPUT:5000/" /etc/filebeat/filebeat.yml
fi

