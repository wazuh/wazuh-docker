#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

# OSSEC container bootstrap. See the README for information of the environment
# variables expected by this script.

# Startup the services

source /permanent_data.env

WAZUH_INSTALL_PATH=/var/ossec
WAZUH_CONFIG_MOUNT=/wazuh-config-mount
AUTO_ENROLLMENT_ENABLED=${AUTO_ENROLLMENT_ENABLED:-true}
API_GENERATE_CERTS=${API_GENERATE_CERTS:-true}
restrict_permissions_go=(/etc/filebeat)

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
  sed -i "s/^config.$1\s=.*/config.$1 = \"$2\";/g" "${WAZUH_INSTALL_PATH}/api/configuration/config.js" || error_and_exit "sed (editing configuration)"
}

##############################################################################
# This function will attempt to mount every directory in data_dirs.env 
# into the respective path. 
# If the path is empty means permanent data volume is also empty, so a backup  
# will be copied into it. Otherwise it will not be copied because there is  
# already data inside the volume for the specified path.
##############################################################################

mount_permanent_data() {
  for permanent_dir in "${PERMANENT_DATA[@]}"; do
    # Check if the path is not empty
    if find ${permanent_dir} -mindepth 1 | read; then
      print "The path ${permanent_dir} is already mounted"
    else
      print "Installing ${permanent_dir}"
      exec_cmd "mkdir -p $(dirname ${permanent_dir})"
      exec_cmd "cp -a ${WAZUH_INSTALL_PATH}/data_tmp/permanent${permanent_dir}/. ${permanent_dir}"
    fi
  done
}

##############################################################################
# This function will replace from the permanent data volume every file 
# contained in data_files.env
# Some files as 'internal_options.conf' are saved as permanent data, but 
# they must be updated to work properly if wazuh version is changed.
##############################################################################

apply_exclusion_data() {
  for exclusion_file in "${PERMANENT_DATA_EXCP[@]}"; do
    if [  -e ${WAZUH_INSTALL_PATH}/data_tmp/exclusion/${exclusion_file}  ]
    then
      print "Updating ${exclusion_file}"
      exec_cmd "cp -p ${WAZUH_INSTALL_PATH}/data_tmp/exclusion/${exclusion_file} ${exclusion_file}"
    fi
  done
}

##############################################################################
# If AUTO_ENROLLMENT_ENABLED variable is true, this function checks if ossec 
# authd key exists. If not, ossec-authd key and cert will be created
##############################################################################

create_ossec_key_cert() {
  print "Creating ossec-authd key and cert"
  exec_cmd "openssl genrsa -out ${WAZUH_INSTALL_PATH}/etc/sslmanager.key 4096"
  exec_cmd "openssl req -new -x509 -key ${WAZUH_INSTALL_PATH}/etc/sslmanager.key -out ${WAZUH_INSTALL_PATH}/etc/sslmanager.cert -days 3650 -subj /CN=${HOSTNAME}/"
}

##############################################################################
# If API_GENERATE_CERTS variable is true, this function checks if api cert 
# exists. If not, api "http" configuration is set to yes and Wazuh API key and 
# cert will be created.
##############################################################################

create_api_key_cert() {
  print "Enabling Wazuh API HTTPS"
  edit_configuration "https" "yes"
  print "Create Wazuh API key and cert"
  exec_cmd "openssl genrsa -out ${WAZUH_INSTALL_PATH}/api/configuration/ssl/server.key 4096"
  exec_cmd "openssl req -new -x509 -key ${WAZUH_INSTALL_PATH}/api/configuration/ssl/server.key -out ${WAZUH_INSTALL_PATH}/api/configuration/ssl/server.crt -days 3650 -subj /CN=${HOSTNAME}/"
}

##############################################################################
# Copy all files from $WAZUH_CONFIG_MOUNT to $WAZUH_INSTALL_PATH and respect
# destination files permissions
#
# For example, to mount the file /var/ossec/data/etc/ossec.conf, mount it at
# $WAZUH_CONFIG_MOUNT/etc/ossec.conf in your container and this code will
# replace the ossec.conf file in /var/ossec/data/etc with yours.
##############################################################################

mount_files() {
  if [ -e "$WAZUH_CONFIG_MOUNT" ]
  then
    print "Identified Wazuh configuration files to mount..."
    exec_cmd_stdout "cp --verbose -r $WAZUH_CONFIG_MOUNT/* $WAZUH_INSTALL_PATH"
  else
    print "No Wazuh configuration files to mount..."
  fi
}

function ossec_shutdown(){
  ${WAZUH_INSTALL_PATH}/bin/ossec-control stop;
}

##############################################################################
# Interpret any passed arguments (via docker command to this entrypoint) as
# paths or commands, and execute them. 
#
# This can be useful for actions that need to be run before the services are
# started, such as "/var/ossec/bin/ossec-control enable agentless".
##############################################################################

docker_custom_args() {
  for CUSTOM_COMMAND in "$@"
  do
    echo "Executing command \`${CUSTOM_COMMAND}\`"
    exec_cmd_stdout "${CUSTOM_COMMAND}"
  done
}

##############################################################################
# Change Wazuh API user credentials.
##############################################################################

change_api_user_credentials() {
  pushd /var/ossec/api/configuration/auth/
  echo "Change Wazuh API user credentials"
  change_user="node htpasswd -b -c user $API_USER $API_PASS"
  eval $change_user
  popd
}

##############################################################################
# Customize filebeat output ip
##############################################################################

custom_filebeat_output_ip() {
  if [ "$FILEBEAT_OUTPUT" != "" ]; then
    sed -i "s/logstash:5000/$FILEBEAT_OUTPUT:5000/" /etc/filebeat/filebeat.yml
  fi
}


main() {
  # Attempt to mount permanent data paths
  mount_permanent_data

  # Update exclusion files contained in permanent data paths
  apply_exclusion_data

  if [ $AUTO_ENROLLMENT_ENABLED == true ]
  then
    if [ ! -e ${WAZUH_INSTALL_PATH}/etc/sslmanager.key ]
    then
      create_ossec_key_cert
    fi
  fi

  if [ $API_GENERATE_CERTS == true ]
  then
    if [ ! -e ${WAZUH_INSTALL_PATH}/api/configuration/ssl/server.crt ]
    then
      create_api_key_cert
    fi
  fi

  mount_files

  # Trap exit signals and do a proper shutdown
  trap "ossec_shutdown; exit" SIGINT SIGTERM
  chmod -R g+rw ${WAZUH_INSTALL_PATH}

  docker_custom_args

  change_api_user_credentials

  custom_filebeat_output_ip

  # Delete temporary data folder
  rm -rf ${WAZUH_INSTALL_PATH}/data_tmp

}

main
