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
           --label com.docker.compose.volume=master-wazuh-integrations \
           $2_master-wazuh-integrations

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-wazuh-active-response \
           $2_master-wazuh-active-response

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-wazuh-agentless \
           $2_master-wazuh-agentless

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-wazuh-wodles \
           $2_master-wazuh-wodles

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-filebeat-etc \
           $2_master-filebeat-etc

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=master-filebeat-var \
           $2_master-filebeat-var

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
           --label com.docker.compose.volume=worker-wazuh-integrations \
           $2_worker-wazuh-integrations

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-wazuh-active-response \
           $2_worker-wazuh-active-response

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-wazuh-agentless \
           $2_worker-wazuh-agentless

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-wazuh-wodles \
           $2_worker-wazuh-wodles

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-filebeat-etc \
           $2_worker-filebeat-etc

docker volume create \
           --label com.docker.compose.project=$2 \
           --label com.docker.compose.version=$1 \
           --label com.docker.compose.volume=worker-filebeat-var \
           $2_worker-filebeat-var

docker container run --rm -it \
           -v wazuh-docker_worker-filebeat-var:/from \
           -v $2_worker-filebeat-var:/to \
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
           -v wazuh-docker_ossec-integrations:/from \
           -v $2_master-wazuh-integrations:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_ossec-active-response:/from \
           -v $2_master-wazuh-active-response:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_ossec-agentless:/from \
           -v $2_master-wazuh-agentless:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_ossec-wodles:/from \
           -v $2_master-wazuh-wodles:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_filebeat-etc:/from \
           -v $2_master-filebeat-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_filebeat-var:/from \
           -v $2_master-filebeat-var:/to \
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
           -v wazuh-docker_worker-ossec-integrations:/from \
           -v $2_worker-wazuh-integrations:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-ossec-active-response:/from \
           -v $2_worker-wazuh-active-response:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-ossec-agentless:/from \
           -v $2_worker-wazuh-agentless:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-ossec-wodles:/from \
           -v $2_worker-wazuh-wodles:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-filebeat-etc:/from \
           -v $2_worker-filebeat-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"

docker container run --rm -it \
           -v wazuh-docker_worker-filebeat-var:/from \
           -v $2_worker-filebeat-var:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
