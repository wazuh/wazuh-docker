#!/bin/bash

source /data_dirs.env

##############################################################################
# Copy will be executed from the custom mounting path (key) 
# to destination path (value) when iterating through the array  
# For example in the first custom path:
#    cp -pr "/migration/ossec_backup/ /var/ossec/" will be executed
# Please ensure the key path is correctly mounted in the container
# For more information please check:
##############################################################################

declare -A custom_paths

custom_paths+=( ["/migration/ossec_backup/"]=/var/ossec/ )
custom_paths+=( ["/migration/filebeat_backup/"]=/etc/filebeat/ )
custom_paths+=( ["/migration/filebeat-lib_backup/"]=/var/lib/filebeat/ )
custom_paths+=( ["/migration/postfix_backup/"]=/etc/postfix/ )

### Auxiliar methods

print() {
    echo -e "$1"
}

error_and_exit() {
    echo "Error executing command: '$1'."
    echo 'Exiting.'
    exit 1
}

exec_cmd() {
    eval "$1" > /dev/null 2>&1 || error_and_exit "$1"
}

exec_cmd_stdout() {
    eval "$1" 2>&1 || error_and_exit "$1"
}

### Restoring directories 

declare -A custom_paths

custom_paths+=( ["/migration/ossec_backup/"]=/var/ossec/ )
custom_paths+=( ["/migration/filebeat_backup/"]=/etc/filebeat/ )
custom_paths+=( ["/migration/filebeat-lib_backup/"]=/var/lib/filebeat/ )
custom_paths+=( ["/migration/postfix_backup/"]=/etc/postfix/ )

for sourcedir in "${!custom_paths[@]}"; do
    if [[ ! -e "${custom_paths[${sourcedir}]}" ]]
    then
        print "BACKUP: The folder ${custom_paths[${sourcedir}]} doesn't exists in the container. Creating it..."
        exec_cmd "mkdir -p ${custom_paths[${sourcedir}]}"
    fi

    if [[ -e "${sourcedir}" ]]
    then
        if [[ -d "${sourcedir}" ]]; then
            print "BACKUP: Copying data from folder ${sourcedir} in 3.9 volume to ${custom_paths[${sourcedir}]}"
            exec_cmd "cp -pr ${sourcedir}* ${custom_paths[${sourcedir}]}"
        elif [[ -f "${sourcedir}" ]]; then
            print "BACKUP: Copying file ${sourcedir} in 3.9 volume to ${custom_paths[${sourcedir}]}"
            exec_cmd "cp -pr ${sourcedir} ${custom_paths[${sourcedir}]}"
        fi
    else
        print "The folder ${sourcedir} doesn't exists in the volume. Ignoring it..."
    fi

done
