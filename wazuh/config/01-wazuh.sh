#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

# Variables
source /permanent_data.env

WAZUH_INSTALL_PATH=/var/ossec
WAZUH_CONFIG_MOUNT=/wazuh-config-mount
AUTO_ENROLLMENT_ENABLED=${AUTO_ENROLLMENT_ENABLED:-true}
API_GENERATE_CERTS=${API_GENERATE_CERTS:-true}


##############################################################################
# Aux functions
##############################################################################
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


##############################################################################
# Check_update
# This function considers the following cases:
# - If /var/ossec/etc/ossec-init.conf does not exist -> Action Nothing. There is no data in the EBS. First time deploying Wazuh
# - If /var/ossec/etc/VERSION does not exist -> Action: Update. The previous version was prior to 3.11.5.
# - If both files exist: different Wazuh version -> Action: Update. The previous version is older than the current one.
# - If both files exist: the same Wazuh version -> Acton: Nothing. Same Wazuh version.
##############################################################################

check_update() {
  if [ -e /var/ossec/etc/ossec-init.conf ]
  then
    if [ -e /var/ossec/etc/VERSION ]
    then
      previous_version=$(cat /var/ossec/etc/VERSION | grep -i version | cut -d'"' -f2)
      echo "Previous version: $previous_version"
      current_version=$(cat ${WAZUH_INSTALL_PATH}/data_tmp/permanent/var/ossec/etc/ossec-init.conf | grep -i version | cut -d'"' -f2)
      echo "Current version: $current_version"
      if [ $previous_version == $current_version ]
      then
        echo "Same Wazuh version in the EBS and image"
        return 0
      else
        echo "Different Wazuh version: Update"
        mayor_previous_version=$(cat /var/ossec/etc/VERSION | grep -i version | cut -d'"' -f2 | cut -d'.' -f1)
        if [[ ${mayor_previous_version} == "v3" ]]; then
          echo "Remove old global.db"
          rm "${WAZUH_INSTALL_PATH}/var/db/global.db*"
          echo "Remove Wazuh API deprecated files"
          rm -rf "${WAZUH_INSTALL_PATH}/api/configuration/auth"
          rm "${WAZUH_INSTALL_PATH}/api/configuration/config.js"
          rm "${WAZUH_INSTALL_PATH}/api/configuration/preloaded_vars.conf"
        fi
        return 1
      fi
    else
      echo "Previous version prior to 3.11.5: Update"
      return 1
    fi
  else
    echo "First time mounting EBS"
    return 0
  fi
}

##############################################################################
# Edit configuration
##############################################################################

edit_configuration() { # $1 -> setting,  $2 -> value
  sed -i "s/^config.$1\s=.*/config.$1 = \"$2\";/g" "${WAZUH_INSTALL_PATH}/api/configuration/config.js" || error_and_exit "sed (editing configuration)"
}

##############################################################################
# This function will attempt to mount every directory in PERMANENT_DATA 
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
      exec_cmd "cp -a ${WAZUH_INSTALL_PATH}/data_tmp/permanent${permanent_dir}/. ${permanent_dir}"
    fi
  done
}

##############################################################################
# This function will replace from the permanent data volume every file 
# contained in PERMANENT_DATA_EXCP
# Some files as 'internal_options.conf' are saved as permanent data, but 
# they must be updated to work properly if wazuh version is changed.
##############################################################################

apply_exclusion_data() {
  for exclusion_file in "${PERMANENT_DATA_EXCP[@]}"; do
    if [  -e ${WAZUH_INSTALL_PATH}/data_tmp/exclusion/${exclusion_file}  ]
    then
      DIR=$(dirname "${exclusion_file}")
      if [ ! -e ${DIR}  ]
      then
        mkdir -p ${DIR}
      fi
      
      print "Updating ${exclusion_file}"
      exec_cmd "cp -p ${WAZUH_INSTALL_PATH}/data_tmp/exclusion/${exclusion_file} ${exclusion_file}"
    fi
  done
}

##############################################################################
# This function will delete from the permanent data volume every file 
# contained in PERMANENT_DATA_DEL
##############################################################################

remove_data_files() {
  for del_file in "${PERMANENT_DATA_DEL[@]}"; do
    if [ $(ls ${del_file} 2> /dev/null | wc -l) -ne 0 ]
    then 
      print "Removing ${del_file}"
      exec_cmd "rm ${del_file}"
    fi
  done
}

##############################################################################
# Create certificates: Manager
##############################################################################

create_ossec_key_cert() {
  print "Creating ossec-authd key and cert"
  exec_cmd "openssl genrsa -out ${WAZUH_INSTALL_PATH}/etc/sslmanager.key 4096"
  exec_cmd "openssl req -new -x509 -key ${WAZUH_INSTALL_PATH}/etc/sslmanager.key -out ${WAZUH_INSTALL_PATH}/etc/sslmanager.cert -days 3650 -subj /CN=${HOSTNAME}/"
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

##############################################################################
# Stop OSSEC
##############################################################################

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


function_create_custom_user() {

  # get custom credentials
  if [[ "x${SECURITY_CREDENTIALS_FILE}" == "x" ]]; then
    WAZUH_API_USER=${API_USER}
    WAZUH_API_PASS=${API_PASS}
  else
    input=${SECURITY_CREDENTIALS_FILE}
    while IFS= read -r line
    do
      if [[ $line == *"WAZUH_API_USER"* ]]; then
        arrIN=(${line//:/ })
        WAZUH_API_USER=${arrIN[1]}
      elif [[ $line == *"WAZUH_API_PASS"* ]]; then
        arrIN=(${line//:/ })
        WAZUH_API_PASS=${arrIN[1]}
      elif [[ $line == *"WUI_API_PASS"* ]]; then
        arrIN=(${line//:/ })
        WUI_API_PASS=${arrIN[1]}
      fi
    done < "$input"
  fi


  if [[ ! -z $WUI_API_PASS ]]; then
  cat << EOF > "/var/ossec/api/configuration/wui-user.json"
{
  "password": "$WUI_API_PASS"
}
EOF
  fi

  if [[ ! -z $WAZUH_API_USER ]] && [[ ! -z $WAZUH_API_PASS ]]; then
  cat << EOF > /var/ossec/api/configuration/admin.json
{
  "username": "$WAZUH_API_USER",
  "password": "$WAZUH_API_PASS"
}
EOF

    # create or customize API user
    if /var/ossec/framework/python/bin/python3  /var/ossec/framework/scripts/create_user.py; then
      # remove json if exit code is 0
      echo "Wazuh API credentials changed"
      rm /var/ossec/api/configuration/admin.json
      rm /var/ossec/api/configuration/wui-user.json
    else
      cat /var/ossec/framework/python/lib/python3.8/site-packages/wazuh-4.0.0-py3.8.egg/wazuh/security.py | grep "_user_password"
      cat /var/ossec/api/configuration/admin.json
      cat /var/ossec/api/configuration/wui-user.json
      echo "There was an error configuring the API user"
      sleep 10
      cat /var/ossec/logs/api.log | grep "TESTING"
      # terminate container to avoid unpredictable behavior
      kill -s SIGINT 1
    fi
  fi
}


##############################################################################
# Main function
##############################################################################

main() {

  # Check Wazuh version in the image and EBS (It returns 1 when updating the environment)
  check_update
  update=$?

  # Mount permanent data  (i.e. ossec.conf)
  mount_permanent_data

  # Restore files stored in permanent data that are not permanent  (i.e. internal_options.conf)
  apply_exclusion_data

  # When updating the environment, remove some files in permanent_data (i.e. .template.db)
  if [ $update == 1 ]
  then
    echo "Removing databases"
    remove_data_files
  else
    echo "Keeping databases"
  fi

  # Generate ossec-authd certs if AUTO_ENROLLMENT_ENABLED is true and does not exist
  if [ $AUTO_ENROLLMENT_ENABLED == true ]
  then
    if [ ! -e ${WAZUH_INSTALL_PATH}/etc/sslmanager.key ]
    then
      create_ossec_key_cert
    fi
  fi

  # Mount selected files (WAZUH_CONFIG_MOUNT) to container
  mount_files

  # Trap exit signals and do a proper shutdown
  trap "ossec_shutdown; exit" SIGINT SIGTERM

  # Execute custom args
  docker_custom_args

  # Change API user credentials
  if [[ ${CLUSTER_NODE_TYPE} == "master" ]]; then
    function_create_custom_user
  fi

  # Delete temporary data folder
  rm -rf ${WAZUH_INSTALL_PATH}/data_tmp

}

main
