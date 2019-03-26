#!/bin/bash

# Check arguments
function CheckArgs()
{
    if [ $1 != 4 ] && [ $1 != 5 ];then
        echo "Use: configure_s3.sh <Elastic_Server_IP:Port> <Bucket> <Path> <RepositoryName> (By default /elasticsearch/<current_elasticsearch_major_version> is added to the path)"
        echo "or use: configure_s3.sh <Elastic_Server_IP:Port> <Bucket> <Path> <RepositoryName> <Elasticsearch major version>" 
        exit 1

    fi
}

# Create repository from base_path <path>/elasticsearch/<current_elasticsearch_major_version> (this last one is automatically added by the script itself, no arg version needed)
# Repository name would be "s3-repository-" plus the current elasticsearch_major_version
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

    repository="$repository_name-$version"
    s3_path="$path/elasticsearch/$version"

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