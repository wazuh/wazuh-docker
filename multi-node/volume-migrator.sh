docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=wazuh-indexer-data-1 \
           $2_wazuh-indexer-data-1

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=wazuh-indexer-data-2 \
           $2_wazuh-indexer-data-2

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=wazuh-indexer-data-3 \
           $2_wazuh-indexer-data-3

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master_wazuh_api_configuration \
           $2_master_wazuh_api_configuration

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master_wazuh_etc \
           $2_docker_wazuh_etc

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-wazuh-logs \
           $2_master-wazuh-logs

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-wazuh-queue \
           $2_master-wazuh-queue

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-wazuh-var-multigroups \
           $2_master-wazuh-var-multigroups

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-wazuh-active-response \
           $2_master-wazuh-active-response

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-wazuh-etc \
           $2_master-wazuh-etc

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-wazuh-var \
           $2_master-wazuh-var

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker_wazuh_api_configuration \
           $2_worker_wazuh_api_configuration

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker_wazuh_etc \
           $2_worker-wazuh-etc

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-wazuh-logs \
           $2_worker-wazuh-logs

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-wazuh-queue \
           $2_worker-wazuh-queue

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-wazuh-var-multigroups \
           $2_worker-wazuh-var-multigroups

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-wazuh-active-response \
           $2_worker-wazuh-active-response

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-wazuh-etc \
           $2_worker-wazuh-etc

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-wazuh-var \
           $2_worker-wazuh-var

docker container run --rm -it \
           -v wazuh-docker_worker-var:/from \
           -v $2_worker-wazuh-var:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_elastic-data-1:/from \
           -v $2_wazuh-indexer-data-1:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_elastic-data-2:/from \
           -v $2_wazuh-indexer-data-2:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_elastic-data-3:/from \
           -v $2_wazuh-indexer-data-3:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_ossec-api-configuration:/from \
           -v $2_master-wazuh-api-configuration:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_ossec-etc:/from \
           -v $2_master-wazuh-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_ossec-logs:/from \
           -v $2_master-wazuh-logs:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_ossec-queue:/from \
           -v $2_master-wazuh-queue:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_ossec-var-multigroups:/from \
           -v $2_master-wazuh-var-multigroups:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_ossec-active-response:/from \
           -v $2_master-wazuh-active-response:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker-etc:/from \
           -v $2_master-wazuh-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker-var:/from \
           -v $2_master-wazuh-var:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-ossec-api-configuration:/from \
           -v $2_worker-wazuh-api-configuration:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-ossec-etc:/from \
           -v $2_worker-wazuh-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-ossec-logs:/from \
           -v $2_worker-wazuh-logs:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-ossec-queue:/from \
           -v $2_worker-wazuh-queue:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-ossec-var-multigroups:/from \
           -v $2_worker-wazuh-var-multigroups:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-ossec-active-response:/from \
           -v $2_worker-wazuh-active-response:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-etc:/from \
           -v $2_worker-wazuh-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-var:/from \
           -v $2_worker-wazuh-var:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
