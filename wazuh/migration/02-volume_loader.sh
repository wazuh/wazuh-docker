#!/bin/bash

source /data_dirs.env

### Sources (container paths where 3.9_volumes are mounted)
OSSEC_BACKUP=/migration/ossec_backup/
FILEBEAT_BACKUP=/migration/filebeat_backup/
FILEBEAT_LIB_BACKUP=/migration/filebeat-lib_backup/
POSTFIX_BACKUP=/migration/postfix_backup/

### Destinations (container paths where files and folders will be copied)
WAZUH_INSTALLATION_PATH=/var/ossec/
FILEBEAT_INSTALLATION_PATH=/etc/filebeat/
FILEBEAT_LIB_INSTALLATION_PATH=/var/lib/filebeat/
POSTFIX_INSTALLATION_PATH=/etc/postfix/

### Auxiliar methods

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

### Restoring directories in "data_dirs.env" from 3.9 volume to container

for ossecdir in "${DATA_DIRS[@]}"; do
    if [[ ! -e "${WAZUH_INSTALLATION_PATH}${ossecdir}" ]]
    then
        print "BACKUP: The folder ${WAZUH_INSTALLATION_PATH}${ossecdir} doesn't exists in the container. Creating it..."
        exec_cmd "mkdir -p ${WAZUH_INSTALLATION_PATH}${ossecdir}"
    fi
    if [[ -d "${WAZUH_INSTALLATION_PATH}${ossecdir}" ]]; then
        print "BACKUP: Copying data from folder ${OSSEC_BACKUP}${ossecdir} in 3.9 volume to ${WAZUH_INSTALLATION_PATH}${ossecdir}"
        exec_cmd "cp -pr ${OSSEC_BACKUP}${ossecdir}/* ${WAZUH_INSTALLATION_PATH}${ossecdir}"
    elif [[ -f "${WAZUH_INSTALLATION_PATH}${ossecdir}" ]]; then
        print "BACKUP: Copying file ${OSSEC_BACKUP}${ossecdir} in 3.9 volume to ${WAZUH_INSTALLATION_PATH}${ossecdir}"
        exec_cmd "cp -pr ${OSSEC_BACKUP}${ossecdir} ${WAZUH_INSTALLATION_PATH}${ossecdir}"
    fi
done

### Restoring Filebeat from backup volume to current installation path

if [[ -d "${FILEBEAT_BACKUP}" ]]; then
    print "BACKUP: Copying Filebeat configuration from ${FILEBEAT_BACKUP} to ${FILEBEAT_INSTALLATION_PATH}"
    exec_cmd "cp -pr ${FILEBEAT_BACKUP}* ${FILEBEAT_INSTALLATION_PATH}"
fi

### Restoring Filebeat lib from backup volume to current installation path

if [[ -d "${FILEBEAT_LIB_BACKUP}" ]]; then
    print "BACKUP: Copying Filebeat Library configuration from ${FILEBEAT_LIB_BACKUP} to ${FILEBEAT_LIB_INSTALLATION_PATH}"
    exec_cmd "cp -pr ${FILEBEAT_LIB_BACKUP}* ${FILEBEAT_LIB_INSTALLATION_PATH}"
fi

### Restoring Postfix from backup volume to current installation path

if [[ -d "${POSTFIX_BACKUP}" ]]; then
    print "BACKUP: Copying Postfix Library configuration from ${POSTFIX_BACKUP} to ${POSTFIX_INSTALLATION_PATH}"
    exec_cmd "cp -pr ${POSTFIX_BACKUP}* ${POSTFIX_INSTALLATION_PATH}"
fi
