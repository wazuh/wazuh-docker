# Opendistro data migration to Wazuh indexer on docker.
This procedure explains how to migrate Opendistro data from Opendistro to Wazuh indexer in docker production deployments.
The example is migrating from v4.2 to v4.4.

## Procedure
Assuming that you have a v4.2 production deployment, perform the following steps.

**1. Stop 4.2 environment**
`docker-compose -f production-cluster.yml stop`

**2. List elasticsearch volumes**
`docker volume ls --filter name='wazuh-docker_elastic-data'`

**3. Inspect elasticsearch volume**
`docker volume inspect wazuh-docker_elastic-data-1`

**4. Spin down the 4.2 environment.**
`docker-compose -f production-cluster.yml down`

**Steps 5 and 6 can be done with the volume-migrator.sh script, specifying Docker compose version and project name as parameters.**

Ex: $ multi-node/volume-migrator.sh 1.25.0 multi-node

**5. Run the volume create command:** create new indexer and Wazuh manager volumes using the `com.docker.compose.version` label value from the previous command.

```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=wazuh-indexer-data-1 \
           multi-node_wazuh-indexer-data-1
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=wazuh-indexer-data-2 \
           multi-node_wazuh-indexer-data-2
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=wazuh-indexer-data-3 \
           multi-node_wazuh-indexer-data-3
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master_wazuh_api_configuration \
           multi-node_master_wazuh_api_configuration
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master_wazuh_etc \
           multi-node_docker_wazuh_etc
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-logs \
           multi-node_master-wazuh-logs
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-queue \
           multi-node_master-wazuh-queue
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-var-multigroups \
           multi-node_master-wazuh-var-multigroups
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-integrations \
           multi-node_master-wazuh-integrations
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-active-response \
           multi-node_master-wazuh-active-response
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-agentless \
           multi-node_master-wazuh-agentless
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-wazuh-wodles \
           multi-node_master-wazuh-wodles
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-filebeat-etc \
           multi-node_master-filebeat-etc
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=master-filebeat-var \
           multi-node_master-filebeat-var
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker_wazuh_api_configuration \
           multi-node_worker_wazuh_api_configuration
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker_wazuh_etc \
           multi-node_worker-wazuh-etc
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-logs \
           multi-node_worker-wazuh-logs
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-queue \
           multi-node_worker-wazuh-queue
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-var-multigroups \
           multi-node_worker-wazuh-var-multigroups
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-integrations \
           multi-node_worker-wazuh-integrations
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-active-response \
           multi-node_worker-wazuh-active-response
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-agentless \
           multi-node_worker-wazuh-agentless
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-wazuh-wodles \
           multi-node_worker-wazuh-wodles
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-filebeat-etc \
           multi-node_worker-filebeat-etc
```
```
docker volume create \
           --label com.docker.compose.project=multi-node \
           --label com.docker.compose.version=1.25.0 \
           --label com.docker.compose.volume=worker-filebeat-var \
           multi-node_worker-filebeat-var
```
**6. Copy the volume content from elasticsearch to Wazuh indexer volumes and old Wazuh manager content to new volumes.**
```
docker container run --rm -it \
           -v wazuh-docker_elastic-data-1:/from \
           -v multi-node_wazuh-indexer-data-1:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_elastic-data-2:/from \
           -v multi-node_wazuh-indexer-data-2:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_elastic-data-3:/from \
           -v multi-node_wazuh-indexer-data-3:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-api-configuration:/from \
           -v multi-node_master-wazuh-api-configuration:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-etc:/from \
           -v multi-node_master-wazuh-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-logs:/from \
           -v multi-node_master-wazuh-logs:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-queue:/from \
           -v multi-node_master-wazuh-queue:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-var-multigroups:/from \
           -v multi-node_master-wazuh-var-multigroups:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-integrations:/from \
           -v multi-node_master-wazuh-integrations:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-active-response:/from \
           -v multi-node_master-wazuh-active-response:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-agentless:/from \
           -v multi-node_master-wazuh-agentless:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_ossec-wodles:/from \
           -v multi-node_master-wazuh-wodles:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_filebeat-etc:/from \
           -v multi-node_master-filebeat-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_filebeat-var:/from \
           -v multi-node_master-filebeat-var:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-api-configuration:/from \
           -v multi-node_worker-wazuh-api-configuration:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-etc:/from \
           -v multi-node_worker-wazuh-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-logs:/from \
           -v multi-node_worker-wazuh-logs:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-queue:/from \
           -v multi-node_worker-wazuh-queue:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-var-multigroups:/from \
           -v multi-node_worker-wazuh-var-multigroups:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-integrations:/from \
           -v multi-node_worker-wazuh-integrations:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-active-response:/from \
           -v multi-node_worker-wazuh-active-response:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-agentless:/from \
           -v multi-node_worker-wazuh-agentless:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-ossec-wodles:/from \
           -v multi-node_worker-wazuh-wodles:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-filebeat-etc:/from \
           -v multi-node_worker-filebeat-etc:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_worker-filebeat-var:/from \
           -v multi-node_worker-filebeat-var:/to \
           alpine ash -c "cd /from ; cp -avp . /to"
```

**7. Start the 4.4 environment.**
```
git checkout 4.4
cd multi-node
docker-compose -f generate-indexer-certs.yml run --rm generator
docker-compose up -d
```

**8. Check the access to Wazuh dashboard**: go to the Wazuh dashboard using the web browser and check the data.
