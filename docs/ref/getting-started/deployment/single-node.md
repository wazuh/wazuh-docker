# Wazuh Docker deployment

## Deploy Wazuh Docker in single node configuration

This deployment is defined in the `single-node/docker-compose.yml` file with one Wazuh manager containers, one Wazuh indexer containers, and one Wazuh dashboard container. It can be deployed by following these steps:

1) Enter the single-node directory of the repository:
```
$ cd single-node
```
2) Increase max_map_count on your host (Linux). This command must be run with root permissions:
```
$ sysctl -w vm.max_map_count=262144
```
3) Run the certificate creation script:
```
$ docker-compose -f generate-indexer-certs.yml run --rm generator
```
4) Start the environment with docker-compose:

- In the foregroud:
```
$ docker-compose up
```
- In the background:
```
$ docker-compose up -d
```

The environment takes about 1 minute to get up (depending on your Docker host) for the first time since Wazuh Indexer must be started for the first time and the indexes and index patterns must be generated.

