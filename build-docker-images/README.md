# Wazuh Docker Image Builder

By executing this stack, the Docker images of Wazuh manager, indexer and dashboard are created.
This process can be used in case of any problem accessing the Docker images that are hosted on Docker Hub.

To execute this process, the following command must be executed:

```
$ docker-compose up -d --build
```

Once the image creation process is finished, a Wazuh test stack will also be executed, which must be terminated with the following command:

```
$ docker-compose down
```