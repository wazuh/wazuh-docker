# Wazuh Docker Image Builder

This stack allows you to build the Wazuh manager, indexer, and dashboard images locally by running the command:

```
$ docker-compose up -d --build
```

Once the image creation process is finished, a Wazuh single-node environment will be spinned up. It can be terminated with the following command:

```
$ docker-compose down
```
