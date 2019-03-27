#!/bin/bash

set -e

# Check arguments
function CheckArgs()
{
    if [ $1 != 4 ] && [ $1 != 5 ];then
        echo "Use: configure_s3.sh <Elastic_Server_IP:Port> <Bucket> <Path> <RepositoryName> (By default <current_elasticsearch_major_version> is added to the path and the repository name)"
        echo "or use: configure_s3.sh <Elastic_Server_IP:Port> <Bucket> <Path> <RepositoryName> <Elasticsearch major version>" 
        exit 1

    fi
}

# Create repository from base_path <path>/<elasticsearch_major_version> (if there is no <Elasticsearch major version> argument, current version is added)
# Repository name would be <RepositoryName>-<elasticsearch_major_version> (if there is no <Elasticsearch major version> argument, current version is added)
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


function Main()
{
    CheckArgs $1

    CreateRepo $1 $2 $3 $4 $5 $6
}

Main $# $1 $2 $3 $4 $5