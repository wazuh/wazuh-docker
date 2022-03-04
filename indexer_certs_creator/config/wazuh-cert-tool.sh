#!/bin/bash

# Program to generate the certificates necessary for Wazuh installation
# Copyright (C) 2015, Wazuh Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

if [ -z "${base_path}" ]; then
    readonly base_path="$(dirname "$(readlink -f "$0")")"
    readonly config_file="${base_path}/config.yml"
fi

if [[ -z "${logfile}" ]]; then
    readonly logfile="/var/log/wazuh-cert-tool.log"
fi

debug_cert=">> ${logfile} 2>&1"

function cleanFiles() {

    eval "rm -f ${base_path}/certs/*.csr ${debug_cert}"
    eval "rm -f ${base_path}/certs/*.srl ${debug_cert}"
    eval "rm -f ${base_path}/certs/*.conf ${debug_cert}"
    eval "rm -f ${base_path}/certs/admin-key-temp.pem ${debug_cert}"

}

function checkOpenSSL() {
    if [ -z "$(command -v openssl)" ]; then
        logger_cert -e "OpenSSL not installed."
        exit 1
    fi
}

function logger_cert() {
    now=$(date +'%d/%m/%Y %H:%M:%S')
    mtype="INFO:"
    debugLogger=
    disableHeader=
    if [ -n "${1}" ]; then
        while [ -n "${1}" ]; do
            case ${1} in
                "-e")
                    mtype="ERROR:"
                    shift 1
                    ;;
                "-w")
                    mtype="WARNING:"
                    shift 1
                    ;;
                "-dh")
                    disableHeader=1
                    shift 1
                    ;;
                "-d")
                    debugLogger=1
                    shift 1
                    ;;
                *)
                    message="${1}"
                    shift 1
                    ;;
            esac
        done
    fi

    if [ -z "${debugLogger}" ] || ( [ -n "${debugLogger}" ] && [ -n "${debugEnabled}" ] ); then
        if [ -n "${disableHeader}" ]; then
            echo "${message}" | tee -a ${logfile}
        else
            echo "${now} ${mtype} ${message}" | tee -a ${logfile}
        fi
    fi
}

function generateAdmincertificate() {

    eval "openssl genrsa -out ${base_path}/certs/admin-key-temp.pem 2048 ${debug_cert}"
    eval "openssl pkcs8 -inform PEM -outform PEM -in ${base_path}/certs/admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out ${base_path}/certs/admin-key.pem ${debug_cert}"
    eval "openssl req -new -key ${base_path}/certs/admin-key.pem -out ${base_path}/certs/admin.csr -batch -subj '/C=US/L=California/O=Wazuh/OU=Wazuh/CN=admin' ${debug_cert}"
    eval "openssl x509 -days 3650 -req -in ${base_path}/certs/admin.csr -CA ${base_path}/certs/root-ca.pem -CAkey ${base_path}/certs/root-ca.key -CAcreateserial -sha256 -out ${base_path}/certs/admin.pem ${debug_cert}"
    eval "chmod 444 ${base_path}/certs/admin*.pem ${debug_cert}"

}

function generateCertificateconfiguration() {

    cat > "${base_path}/certs/${1}.conf" <<- EOF
        [ req ]
        prompt = no
        default_bits = 2048
        default_md = sha256
        distinguished_name = req_distinguished_name
        x509_extensions = v3_req

        [req_distinguished_name]
        C = US
        L = California
        O = Wazuh
        OU = Wazuh
        CN = cname

        [ v3_req ]
        authorityKeyIdentifier=keyid,issuer
        basicConstraints = CA:FALSE
        keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
        subjectAltName = @alt_names

        [alt_names]
        IP.1 = cip
	EOF

    conf="$(awk '{sub("CN = cname", "CN = '${1}'")}1' "${base_path}/certs/${1}.conf")"
    echo "${conf}" > "${base_path}/certs/${1}.conf"

    isIP=$(echo "${2}" | grep -P "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")
    isDNS=$(echo "${2}" | grep -P "^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$" )

    if [[ -n "${isIP}" ]]; then
        conf="$(awk '{sub("IP.1 = cip", "IP.1 = '${2}'")}1' "${base_path}/certs/${1}.conf")"
        echo "${conf}" > "${base_path}/certs/${1}.conf"
    elif [[ -n "${isDNS}" ]]; then
        conf="$(awk '{sub("CN = cname", "CN =  '${2}'")}1' "${base_path}/certs/${1}.conf")"
        echo "${conf}" > "${base_path}/certs/${1}.conf"
        conf="$(awk '{sub("IP.1 = cip", "DNS.1 = '${2}'")}1' "${base_path}/certs/${1}.conf")"
        echo "${conf}" > "${base_path}/certs/${1}.conf"
    else
        logger_cert -e "The given information does not match with an IP address or a DNS."
        exit 1
    fi

}

function generateIndexercertificates() {

    if [ ${#indexer_node_names[@]} -gt 0 ]; then
        logger_cert -d "Creating the Wazuh indexer certificates."

        for i in "${!indexer_node_names[@]}"; do
            generateCertificateconfiguration "${indexer_node_names[i]}" "${indexer_node_ips[i]}"
            eval "openssl req -new -nodes -newkey rsa:2048 -keyout ${base_path}/certs/${indexer_node_names[i]}-key.pem -out ${base_path}/certs/${indexer_node_names[i]}.csr -config ${base_path}/certs/${indexer_node_names[i]}.conf -days 3650 ${debug_cert}"
            eval "openssl x509 -req -in ${base_path}/certs/${indexer_node_names[i]}.csr -CA ${base_path}/certs/root-ca.pem -CAkey ${base_path}/certs/root-ca.key -CAcreateserial -out ${base_path}/certs/${indexer_node_names[i]}.pem -extfile ${base_path}/certs/${indexer_node_names[i]}.conf -extensions v3_req -days 3650 ${debug_cert}"
            eval "chmod 444 ${base_path}/certs/${indexer_node_names[i]}-key.pem ${debug_cert}"
        done
    fi

}

function generateFilebeatcertificates() {

    if [ ${#wazuh_servers_node_names[@]} -gt 0 ]; then
        logger_cert -d "Creating the Wazuh server certificates."

        for i in "${!wazuh_servers_node_names[@]}"; do
            generateCertificateconfiguration "${wazuh_servers_node_names[i]}" "${wazuh_servers_node_ips[i]}"
            eval "openssl req -new -nodes -newkey rsa:2048 -keyout ${base_path}/certs/${wazuh_servers_node_names[i]}-key.pem -out ${base_path}/certs/${wazuh_servers_node_names[i]}.csr -config ${base_path}/certs/${wazuh_servers_node_names[i]}.conf -days 3650 ${debug_cert}"
            eval "openssl x509 -req -in ${base_path}/certs/${wazuh_servers_node_names[i]}.csr -CA ${base_path}/certs/root-ca.pem -CAkey ${base_path}/certs/root-ca.key -CAcreateserial -out ${base_path}/certs/${wazuh_servers_node_names[i]}.pem -extfile ${base_path}/certs/${wazuh_servers_node_names[i]}.conf -extensions v3_req -days 3650 ${debug_cert}"
        done
    fi

}

function generateDashboardcertificates() {

    if [ ${#dashboard_node_names[@]} -gt 0 ]; then
        logger_cert -d "Creating the Wazuh dashboard certificates."

        for i in "${!dashboard_node_names[@]}"; do
            generateCertificateconfiguration "${dashboard_node_names[i]}" "${dashboard_node_ips[i]}"
            eval "openssl req -new -nodes -newkey rsa:2048 -keyout ${base_path}/certs/${dashboard_node_names[i]}-key.pem -out ${base_path}/certs/${dashboard_node_names[i]}.csr -config ${base_path}/certs/${dashboard_node_names[i]}.conf -days 3650 ${debug_cert}"
            eval "openssl x509 -req -in ${base_path}/certs/${dashboard_node_names[i]}.csr -CA ${base_path}/certs/root-ca.pem -CAkey ${base_path}/certs/root-ca.key -CAcreateserial -out ${base_path}/certs/${dashboard_node_names[i]}.pem -extfile ${base_path}/certs/${dashboard_node_names[i]}.conf -extensions v3_req -days 3650 ${debug_cert}"
            eval "chmod 444 ${base_path}/certs/${dashboard_node_names[i]}-key.pem ${debug_cert}"
        done
    fi

}

function generateRootCAcertificate() {

    logger_cert -d "Creating the root certificate."

    eval "openssl req -x509 -new -nodes -newkey rsa:2048 -keyout ${base_path}/certs/root-ca.key -out ${base_path}/certs/root-ca.pem -batch -subj '/OU=Wazuh/O=Wazuh/L=California/' -days 3650 ${debug_cert}"

}

function getHelp() {

    echo -e ""
    echo -e "NAME"
    echo -e "        wazuh-cert-tool.sh - Manages the creation of certificates of the Wazuh components."
    echo -e ""
    echo -e "SYNOPSIS"
    echo -e "        wazuh-cert-tool.sh [OPTIONS]"
    echo -e ""
    echo -e "DESCRIPTION"
    echo -e "        -a,  --admin-certificates"
    echo -e "                Creates the admin certificates."
    echo -e ""
    echo -e "        -ca, --root-ca-certificates"
    echo -e "                Creates the root-ca certificates."
    echo -e ""
    echo -e "        -v,  --verbose"
    echo -e "                Enables verbose mode."
    echo -e ""
    echo -e "        -wd,  --wazuh-dashboard-certificates"
    echo -e "                Creates the Wazuh dashboard certificates."
    echo -e ""
    echo -e "        -wi,  --wazuh-indexer-certificates"
    echo -e "                Creates the Wazuh indexer certificates."
    echo -e ""
    echo -e "        -ws,  --wazuh-server-certificates"
    echo -e "                Creates the Wazuh server certificates."

    exit 1

}

function main() {

    if [ "$EUID" -ne 0 ]; then
        logger_cert -e "This script must be run as root."
        exit 1
    fi

    checkOpenSSL

    if [[ -d ${base_path}/certs ]]; then
        logger_cert -e "Folder ${base_path}/certs already exists. Please, remove the /certs folder to create new certificates."
        exit 1
    else
        mkdir "${base_path}/certs"
    fi

    if [ -n "${1}" ]; then
        while [ -n "${1}" ]
        do
            case "${1}" in
            "-a"|"--admin-certificates")
                cadmin=1
                shift 1
                ;;
            "-ca"|"--root-ca-certificate")
                ca=1
                shift 1
                ;;
            "-h"|"--help")
                getHelp
                ;;
            "-v"|"--verbose")
                debugEnabled=1
                shift 1
                ;;
            "-wd"|"--wazuh-dashboard-certificates")
                cdashboard=1
                shift 1
                ;;
            "-wi"|"--wazuh-indexer-certificates")
                cindexer=1
                shift 1
                ;;
            "-ws"|"--wazuh-server-certificates")
                cserver=1
                shift 1
                ;;
            *)
                getHelp
            esac
        done

        readConfig

        if [ -n "${debugEnabled}" ]; then
            debug_cert="2>&1 | tee -a ${logfile}"
        fi

        if [[ -n "${cadmin}" ]]; then
            generateAdmincertificate
            logger_cert "Admin certificates created."
        fi

        if [[ -n "${ca}" ]]; then
            generateRootCAcertificate
            logger_cert "Authority certificates created."
        fi

        if [[ -n "${cindexer}" ]]; then
            generateIndexercertificates
            logger_cert "Wazuh indexer certificates created."
        fi

        if [[ -n "${cserver}" ]]; then
            generateFilebeatcertificates
            logger_cert "Wazuh server certificates created."
        fi

        if [[ -n "${cdashboard}" ]]; then
            generateDashboardcertificates
            logger_cert "Wazuh dashboard certificates created."
        fi

    else
        readConfig
        generateRootCAcertificate
        generateAdmincertificate
        generateIndexercertificates
        generateFilebeatcertificates
        generateDashboardcertificates
        cleanFiles
    fi

}

function parse_yaml() {

    local prefix=${2}
    local s='[[:space:]]*'
    local w='[a-zA-Z0-9_]*'
    local fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
            -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  ${1} |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
        }
    }'

}

function readConfig() {

    if [ -f "${config_file}" ]; then
        if [ ! -s "${config_file}" ]; then
            logger_cert -e "File ${config_file} is empty"
            exit 1
        fi
        eval "$(parse_yaml "${config_file}")"
        eval "indexer_node_names=( $(parse_yaml "${config_file}" | grep nodes_indexer_name | sed 's/nodes_indexer_name=//') )"
        eval "wazuh_servers_node_names=( $(parse_yaml "${config_file}" | grep nodes_wazuh_servers_name | sed 's/nodes_wazuh_servers_name=//') )"
        eval "dashboard_node_names=( $(parse_yaml "${config_file}" | grep nodes_dashboard_name | sed 's/nodes_dashboard_name=//') )"

        eval "indexer_node_ips=( $(parse_yaml "${config_file}" | grep nodes_indexer_ip | sed 's/nodes_indexer_ip=//') )"
        eval "wazuh_servers_node_ips=( $(parse_yaml "${config_file}" | grep nodes_wazuh_servers_ip | sed 's/nodes_wazuh_servers_ip=//') )"
        eval "dashboard_node_ips=( $(parse_yaml "${config_file}" | grep nodes_dashboard_ip | sed 's/nodes_dashboard_ip=//') )"

        eval "wazuh_servers_node_types=( $(parse_yaml "${config_file}" | grep nodes_wazuh_servers_node_type | sed 's/nodes_wazuh_servers_node_type=//') )"

        unique_names=($(echo "${indexer_node_names[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        if [ "${#unique_names[@]}" -ne "${#indexer_node_names[@]}" ]; then 
            logger_cert -e "Duplicated indexer node names."
            exit 1
        fi

        unique_ips=($(echo "${indexer_node_ips[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        if [ "${#unique_ips[@]}" -ne "${#indexer_node_ips[@]}" ]; then 
            logger_cert -e "Duplicated indexer node ips."
            exit 1
        fi

        unique_names=($(echo "${wazuh_servers_node_names[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        if [ "${#unique_names[@]}" -ne "${#wazuh_servers_node_names[@]}" ]; then 
            logger_cert -e "Duplicated Wazuh server node names."
            exit 1
        fi

        unique_ips=($(echo "${wazuh_servers_node_ips[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        if [ "${#unique_ips[@]}" -ne "${#wazuh_servers_node_ips[@]}" ]; then 
            logger_cert -e "Duplicated Wazuh server node ips."
            exit 1
        fi

        unique_names=($(echo "${dashboard_node_names[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        if [ "${#unique_names[@]}" -ne "${#dashboard_node_names[@]}" ]; then 
            logger_cert -e "Duplicated dashboard node names."
            exit 1
        fi

        unique_ips=($(echo "${dashboard_node_ips[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        if [ "${#unique_ips[@]}" -ne "${#dashboard_node_ips[@]}" ]; then 
            logger_cert -e "Duplicated dashboard node ips."
            exit 1
        fi

        if [ "${#wazuh_servers_node_names[@]}" -ne "${#wazuh_servers_node_ips[@]}" ]; then 
            logger_cert -e "Different number of Wazuh server node names and IPs."
            exit 1
        fi

        for i in "${wazuh_servers_node_types[@]}"; do
            if ! echo "$i" | grep -ioq master && ! echo "$i" | grep -ioq worker; then
                logger_cert -e "Incorrect node_type $i must be master or worker"
                exit 1
            fi
        done

        if [ "${#wazuh_servers_node_names[@]}" -le 1 ]; then
            if [ "${#wazuh_servers_node_types[@]}" -ne 0 ]; then
                logger_cert -e "The tag node_type can only be used with more than one Wazuh server."
                exit 1
            fi
        elif [ "${#wazuh_servers_node_names[@]}" -gt "${#wazuh_servers_node_types[@]}" ]; then
            logger_cert -e "The tag node_type needs to be specified for all Wazuh server nodes."
            exit 1
        elif [ "${#wazuh_servers_node_names[@]}" -lt "${#wazuh_servers_node_types[@]}" ]; then
            logger_cert -e "Found extra node_type tags."
            exit 1
        elif [ $(grep -io master <<< ${wazuh_servers_node_types[*]} | wc -l) -ne 1 ]; then
            logger_cert -e "Wazuh cluster needs a single master node."
            exit 1
        elif [ $(grep -io worker <<< ${wazuh_servers_node_types[*]} | wc -l) -ne $(( ${#wazuh_servers_node_types[@]} - 1 )) ]; then
            logger_cert -e "Incorrect number of workers."
            exit 1
        fi

        if [ "${#dashboard_node_names[@]}" -ne "${#dashboard_node_ips[@]}" ]; then 
            logger_cert -e "Different number of dashboard node names and IPs."
            exit 1
        fi

    else
        logger_cert -e "No configuration file found. ${config_file}."
        exit 1
    fi

}

main $@
