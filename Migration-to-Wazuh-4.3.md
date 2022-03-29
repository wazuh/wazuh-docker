# Opendistro data migration to Wazuh indexer on docker. 
This procedure explains how to migrate Opendistro data from Opendistro to Wazuh indexer in docker production deployments.
The example is migrating from v4.2.5 to v4.3.0.

## Procedure
Assuming that you have a v4.2.5 production deployment, perform the following steps.

**1. Stop 4.2.5 environment**
`docker-compose -f production-cluster.yml stop`

**2. List Elastic volumesStop 4.2.5 environment**
`docker volume ls --filter name='wazuh-docker_elastic-data'`

**3. Inspect Elastic volume**
`docker volume inspect wazuh-docker_elastic-data-1`

**4. Run the volume create command:** create new Indexer and Wazuh Manager volumes using the `com.docker.compose.version` label value from the previous command.
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=wazuh-indexer-data-1 \
           wazuh-docker_wazuh-indexer-data-1
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=wazuh-indexer-data-2 \
           wazuh-docker_wazuh-indexer-data-2
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=wazuh-indexer-data-3 \
           wazuh-docker_wazuh-indexer-data-3
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master_wazuh_api_configuration \
           wazuh-docker_master_wazuh_api_configuration
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master_wazuh_etc \
           wazuh-master_docker_wazuh_etc
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-logs \
           wazuh-docker_master-wazuh-logs
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-queue \
           wazuh-docker_master-wazuh-queue
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-var-multigroups \
           wazuh-docker_master-wazuh-var-multigroups
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-integrations \
           wazuh-docker_master-wazuh-integrations
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-active-response \
           wazuh-docker_master-wazuh-active-response
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-agentless \
           wazuh-docker_master-wazuh-agentless
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-wodles \
           wazuh-docker_master-wazuh-wodles
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-filebeat-etc \
           wazuh-docker_master-filebeat-etc
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-filebeat-var \
           wazuh-docker_master-filebeat-var
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker_wazuh_api_configuration \
           wazuh-docker_worker_wazuh_api_configuration
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker_wazuh_etc \
           wazuh-worker_docker_wazuh_etc
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-logs \
           wazuh-docker_worker-wazuh-logs
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-queue \
           wazuh-docker_worker-wazuh-queue
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-var-multigroups \
           wazuh-docker_worker-wazuh-var-multigroups
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-integrations \
           wazuh-docker_worker-wazuh-integrations
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-active-response \
           wazuh-docker_worker-wazuh-active-response
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-agentless \
           wazuh-docker_worker-wazuh-agentless
```
```
docker volume create \
           --label com.docker.compose.project=wazuh-docker \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-wodles \
           wazuh-docker_worker-wazuh-wodles
```
**5. Copy the volume content from Elastic to Wazuh indexer volumes and old Wazuh Manager content to new volumes.**
```
docker container run --rm -it \
           -v wazuh-docker_elastic-data-1:/from \
           -v wazuh-docker_wazuh-indexer-data-1:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_elastic-data-2:/from \
           -v wazuh-docker_wazuh-indexer-data-2:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_elastic-data-3:/from \
           -v wazuh-docker_wazuh-indexer-data-3:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-api-configuration:/from \
           -v wazuh-docker_master-wazuh-api-configuration:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-etc:/from \
           -v wazuh-docker_master-wazuh-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-logs:/from \
           -v wazuh-docker_master-wazuh-logs:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-queue:/from \
           -v wazuh-docker_master-wazuh-queue:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-var-multigroups:/from \
           -v wazuh-docker_master-wazuh-var-multigroups:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-integrations:/from \
           -v wazuh-docker_master-wazuh-integrations:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-active-response:/from \
           -v wazuh-docker_master-wazuh-active-response:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-agentless:/from \
           -v wazuh-docker_master-wazuh-agentless:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-wodles:/from \
           -v wazuh-docker_master-wazuh-wodles:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_filebeat-etc:/from \
           -v wazuh-docker_master-filebeat-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_filebeat-var:/from \
           -v wazuh-docker_master-filebeat-var:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-api-configuration:/from \
           -v wazuh-docker_worker-wazuh-api-configuration:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-etc:/from \
           -v wazuh-docker_worker-wazuh-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-logs:/from \
           -v wazuh-docker_worker-wazuh-logs:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-queue:/from \
           -v wazuh-docker_worker-wazuh-queue:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-var-multigroups:/from \
           -v wazuh-docker_worker-wazuh-var-multigroups:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-integrations:/from \
           -v wazuh-docker_worker-wazuh-integrations:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-active-response:/from \
           -v wazuh-docker_worker-wazuh-active-response:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-agentless:/from \
           -v wazuh-docker_worker-wazuh-agentless:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-wodles:/from \
           -v wazuh-docker_worker-wazuh-wodles:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
**6. Delete the 4.2.5 environment.**
`docker-compose -f production-cluster.yml down`

**7. Start the 4.3 environment.**
```
git checkout 4.3
docker-compose -f production-cluster.yml up -d
```

**8. Check the access to Wazuh dashboard**: go to the Wazuh Dashboard WebUI and check if everything is working.