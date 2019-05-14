#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

# Check number of arguments passed to configure_s3.sh. If it is different from 4 or 5, the process will finish with error.
# param 1: number of arguments passed to configure_s3.sh

function CheckArgs()
{
    if [ $1 != 4 ] && [ $1 != 5 ];then
        echo "Use: configure_s3.sh <Elastic_Server_IP:Port> <Bucket> <Path> <RepositoryName> (By default <current_elasticsearch_major_version> is added to the path and the repository name)"
        echo "or use: configure_s3.sh <Elastic_Server_IP:Port> <Bucket> <Path> <RepositoryName> <Elasticsearch major version>" 
        exit 1

    fi
}

# Create S3 repository from base_path <path>/<elasticsearch_major_version> (if there is no <Elasticsearch major version> argument, current version is added)
# Repository name would be <RepositoryName>-<elasticsearch_major_version> (if there is no <Elasticsearch major version> argument, current version is added)
# param 1: <Elastic_Server_IP:Port>
# param 2: <Bucket>
# param 3: <Path>
# param 4: <RepositoryName>
# param 5: Optional <Elasticsearch major version>
# output: It will show "acknowledged" if the repository has been successfully created

function CreateRepo()
{

    elastic_ip_port="$2"
    bucket_name="$3"
    path="$4"
    repository_name="$5"

    if [ $1 == 5 ];then
        version="$6"
    else
        version=`curl -s $elastic_ip_port | grep number | cut -d"\"" -f4 | cut -c1`
    fi

    if ! [[ "$version" =~ ^[0-9]+$ ]];then
        echo "Elasticsearch major version must be an integer"
        exit 1
    fi

    repository="$repository_name-$version"
    s3_path="$path/$version"

    curl -X PUT "$elastic_ip_port/_snapshot/$repository" -H 'Content-Type: application/json' -d'
        {
            "type": "s3",
            "settings": {
            "bucket": "'$bucket_name'",
            "base_path": "'$s3_path'"
        }
    }
    '

}

# Run functions CheckArgs and CreateRepo
# param 1: number of arguments passed to configure_s3.sh
# param 2: <Elastic_Server_IP:Port>
# param 3: <Bucket>
# param 4: <Path>
# param 5: <RepositoryName>
# param 6: Optional <Elasticsearch major version>

function Main()
{
    CheckArgs $1

    CreateRepo $1 $2 $3 $4 $5 $6
}

Main $# $1 $2 $3 $4 $5