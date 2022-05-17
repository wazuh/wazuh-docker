#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

if [ -s key.pem ]
then
    echo "Certificate already exists"
    exit
else
    openssl req -x509 -batch -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem
fi
