#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

usage ()
{
	echo -e " USE: ./create_CA.sh [options]"
	echo -e "   --help or -h : usage information.\n"
    echo "   --create_CA : Create your own CA to secure communications with Elasticsearch nodes. Requires openssl installed and demoCA directory."
	echo "   --full_creation : Create your own CA to secure communications with Elasticsearch nodes and demoCA directory. Requires openssl installed."
    echo "   --CA_name : CA name for pem certificate and key."
    echo "   --days : Days of duration of the certificate."
	echo -e " Examples:"
	echo -e "  ./create_CA.sh --create_CA --CA_name server.TEST-CA --days 18250"
    echo -e "  ./create_CA.sh --full_creation --CA_name server.TEST-CA --days 18250"
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
		--full_creation )		ACTION=full_creation
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
    SIGNED_CA= "${CA_NAME}-signed.pem"
    KEY_CA="${CA_NAME}.key"
    CSR_CA="${CA_NAME}.csr"
    echo "Creation of the self-signed CA certificate."
    echo "Generate CA provate key"
    openssl genrsa -des3 -out ${KEY_CA} 2048
    echo "Create a certificate signing request. Fill in the certificate with your data"
    openssl req -verbose -new -key ${KEY_CA} -out ${CSR_CA} -sha256
    echo "Self sign certificate"
    openssl ca -extensions v3_ca -out ${SIGNED_CA} -keyfile ${KEY_CA} -verbose -selfsign -md sha256 -days ${DAYS} -infiles ${CSR_CA}
    echo "Self signed CA created"
    cp ${KEY_CA} elasticsearch/config/
    cp ${SIGNED_CA} elasticsearch/config/
    cp ${SIGNED_CA} kibana/config/
    cp ${SIGNED_CA} logstash/config/
    rm ${SIGNED_CA} ${KEY_CA} ${CSR_CA}
    sed -i 's:ARG SECURITY_CA_PEM_LOCATION="config/server.TEST-CA-signed.pem":ARG SECURITY_CA_PEM_LOCATION="config/'$SIGNED_CA'":g' elasticsearch/Dockerfile
    sed -i 's:ARG SECURITY_CA_KEY_LOCATION="config/server.TEST-CA.key":ARG ASECURITY_CA_KEY_LOCATION="config/'$KEY_CA'":g' elasticsearch/Dockerfile
    sed -i 's:ARG SECURITY_CA_PEM_LOCATION="config/server.TEST-CA-signed.pem":ARG SECURITY_CA_PEM_LOCATION="config/'$SIGNED_CA'":g' kibana/Dockerfile
    sed -i 's:ARG SECURITY_CA_PEM_LOCATION="config/server.TEST-CA-signed.pem":ARG SECURITY_CA_PEM_LOCATION="config/'$SIGNED_CA'":g' logstash/Dockerfile
    sed -i 's:ARG SECURITY_CA_PEM_ARG="server.TEST-CA-signed.pem":ARG SECURITY_CA_PEM_ARG="'$SIGNED_CA'":g' logstash/Dockerfile
    echo "Finished"
}

full_own_creation ()
{
    echo "Create directory demoCA. Press enter and fill in the first certificate with your data."
    /usr/lib/ssl/misc/CA.pl -newca
    echo "demoCA directory created."
    create_own_CA
}


creation_type ()
{
    if [[ $ACTION == "create_CA" ]]; then
        create_own_CA 
    elif [[ $ACTION == "full_creation" ]]; then
        full_own_creation 
    fi
}
#------------------------- Creation functions ------------------------------#

#------------------------- Main workflow ------------------------------#

main ()
{
    creation_type
}


main

#------------------------- Main workflow ------------------------------#
