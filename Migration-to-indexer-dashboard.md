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

**4. Run the volume create command:** create 3 new Indexer volumes using the `com.docker.compose.version` label value from the previous command.
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

**5. Copy the volume content from Elastic to Wazuh indexer volumes.**
```
docker container run --rm -it \
           -v wazuh-docker_elastic-data-1:/from \
           -v wazuh-docker_wazuh-indexer-data-1:/to \
           alpine ash -c "cd /from ; cp -av . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_elastic-data-2:/from \
           -v wazuh-docker_wazuh-indexer-data-2:/to \
           alpine ash -c "cd /from ; cp -av . /to"
```
```
docker container run --rm -it \
           -v wazuh-docker_elastic-data-3:/from \
           -v wazuh-docker_wazuh-indexer-data-3:/to \
           alpine ash -c "cd /from ; cp -av . /to"
```

**6. Delete the 4.2.5 environment.**
`docker-compose -f production-cluster.yml down`

**7. Start the 4.3 environment.**
```
git checkout 4.3
docker-compose -f production-cluster.yml up -d
```

**8. Check the access to Wazuh dashboard**: go to the Wazuh Dashboard WebUI and check if everything is working.