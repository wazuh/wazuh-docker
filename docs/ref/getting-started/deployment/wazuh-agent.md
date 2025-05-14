# Wazuh Docker deployment

## Deploy Wazuh agent

1) Enter the `wazuh-agent` directory of the repository.
```
$ cd wazuh-agent
```
2) Edit the `docker-compose.yml` file, changing the current value of the `WAZUH_MANAGER_SERVER` variable to the IP or URL of the Wazuh manager:
```
    environment:
      - WAZUH_MANAGER_SERVER=<WAZUH_MANAGER_IP>
```
3) Start the environment with docker-compose:

- In the foregroud:
```
$ docker-compose up
```

- In the background:
```
$ docker-compose up -d
```