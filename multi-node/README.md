# Deploy Wazuh Docker in multi node configuration

This deployment is defined in the `docker-compose.yml` file with two Wazuh manager containers, three Wazuh indexer containers, and one Wazuh dashboard container. It can be deployed by following these steps:

1) Increase max_map_count on your host (Linux). This command must be run with root permissions:
```
$ sysctl -w vm.max_map_count=262144
```

2) Download the certificate creation script and config.yml file:
```
$ curl -sO https://packages.wazuh.com/5.0/wazuh-certs-tool.sh
$ curl -sO https://packages.wazuh.com/5.0/config.yml
```

3) Edit the config.yml file with the configuration of the Wazuh components to be deployed
```
nodes:
  # Wazuh indexer server nodes
  indexer:
    - name: wazuh1.indexer
      ip: wazuh1.indexer
    - name: wazuh2.indexer
      ip: wazuh2.indexer
    - name: wazuh3.indexer
      ip: wazuh3.indexer

  # Wazuh server nodes
  # Use node_type only with more than one Wazuh manager
  server:
    - name: wazuh.master
      ip: wazuh.master
      node_type: master
    - name: wazuh.worker
      ip: wazuh.worker
      node_type: worker

  # Wazuh dashboard node
  dashboard:
    - name: wazuh.dashboard
      ip: wazuh.dashboard
```

4) Run the certificate creation script:
```
bash ./wazuh-certs-tool.sh -A
```

5) Start the environment with docker compose:

- In the foregroud:
```
$ docker compose up
```

- In the background:
```
$ docker compose up -d
```


The environment takes about 1 minute to get up (depending on your Docker host) for the first time since Wazuh Indexer must be started for the first time and the indexes and index patterns must be generated.
