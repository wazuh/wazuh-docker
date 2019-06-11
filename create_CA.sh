#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

usage ()
{
	echo -e " USE: ./create_CA.sh [options]"
	echo -e "   --help or -h : usage information.\n"
    echo "   --create_CA : Create your own CA to secure communications with Elasticsearch nodes. Requires openssl installed and demoCA directory."
    echo "   --CA_name : CA name for pem certificate and key."
    echo "   --days : Days of duration of the certificate."
	echo -e " Examples:"
	echo -e "  ./create_CA.sh --create_CA --CA_name server.TEST-CA --days 18250"
}


#------------------------- Gather parameters ------------------------------#

CA_NAME=
DAYS=
ACTION=

while [ "$1" != "" ]; do
	case $1 in
		--CA_name )	shift
								CA_NAME=$1
								;;
		--days )	shift
								DAYS=$1
								;;
		--create_CA )			ACTION=create_CA
								;;                        
		-h | --help )			usage
								exit
								;;
	* )							shift
	esac
	shift
done

#------------------------- Gather parameters ------------------------------#

#------------------------- Analyze parameters ------------------------------#

if [[ ! $CA_NAME ]]
then
	usage
	exit
fi

if [[ ! $DAYS ]]
then
	usage
	exit
fi

if [[ ! $ACTION ]]
then
	usage
	exit
fi

#------------------------- Analyze parameters ------------------------------#

#------------------------- Creation functions ------------------------------#

create_own_CA ()
{
    SIGNED_CA="${CA_NAME}-signed.pem"
    KEY_CA="${CA_NAME}.key"
    echo "Creation of the self-signed CA certificate."
    echo "Generate CA private key"
    openssl genrsa -des3 -out ${KEY_CA} 2048
    echo "Self sign certificate"
    openssl req -x509 -new -nodes -key  ${KEY_CA} -sha256 -days ${DAYS} -out ${SIGNED_CA}
    echo "Self signed CA created"
    cp ${KEY_CA} elasticsearch/config/
    cp ${SIGNED_CA} elasticsearch/config/
    cp ${SIGNED_CA} kibana/config/
    cp ${SIGNED_CA} logstash/config/
    rm ${SIGNED_CA} ${KEY_CA}
    echo "Finished"
}

#------------------------- Creation functions ------------------------------#

#------------------------- Main workflow ------------------------------#

main ()
{
    create_own_CA
}


main

#------------------------- Main workflow ------------------------------#
