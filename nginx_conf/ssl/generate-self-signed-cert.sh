#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

if [ -s kibana-access.key ]
then
    echo "Aborting. Certificate already exists"
    exit
else
    openssl req -x509 -batch -nodes -days 365 -newkey rsa:2048 -keyout kibana-access.key -out kibana-access.pem
fi
