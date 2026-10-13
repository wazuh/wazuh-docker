# Wazuh containers for Docker

[![Slack](https://img.shields.io/badge/slack-join-blue.svg)](https://wazuh.com/community/join-us-on-slack/)
[![Email](https://img.shields.io/badge/email-join-blue.svg)](https://groups.google.com/forum/#!forum/wazuh)
[![Documentation](https://img.shields.io/badge/docs-view-green.svg)](https://documentation.wazuh.com)
[![Documentation](https://img.shields.io/badge/web-view-green.svg)](https://wazuh.com)

In this repository you will find the containers to run:

* Wazuh manager: it runs the Wazuh manager and the Wazuh API.
* Wazuh dashboard: provides a web user interface to browse through alert data and allows you to visualize the agents configuration and status.
* Wazuh indexer: Wazuh indexer container, working as a single-node cluster or as a multi-node cluster. The Docker host needs `vm.max_map_count` set to at least `262144`, as the [deployment guides](ref/getting-started/deployment/deployment.md) describe.
* Wazuh agent: a containerized Wazuh agent, enrolled with a token minted by the manager.

## Documentation

* [Deployment](ref/getting-started/deployment/deployment.md): single-node, multi-node and the agent.
* [Credentials](ref/credentials.md): how each deployment gets its own passwords, and how to change them.
* [Wazuh full documentation](https://documentation.wazuh.com)
* [Docker Hub](https://hub.docker.com/u/wazuh)

## Directory structure

```text
wazuh-docker/
├── build-docker-images/          # Dockerfiles, configuration and entrypoints of the images
│   ├── build-images.sh           # Builds the images from the package URLs in artifact_urls.yaml
│   ├── docker-bake.hcl
│   ├── wazuh-agent/
│   ├── wazuh-dashboard/
│   ├── wazuh-indexer/
│   └── wazuh-manager/
├── docs/                         # This documentation
├── multi-node/                   # Two managers, three indexers, one dashboard and nginx
│   ├── config/nginx/
│   └── docker-compose.yml
├── single-node/                  # One manager, one indexer and one dashboard
│   └── docker-compose.yml
├── tools/
│   ├── tests/check-default-credentials.sh
│   └── utils/deployment/         # certificates-conf.sh and credentials-conf.sh
└── wazuh-agent/                  # A containerized agent
    └── docker-compose.yml
```

## Branches

* `main` branch contains the latest code, be aware of possible bugs on this branch.

## Credits and Thank you

These Docker containers are based on:

*  "deviantony" dockerfiles which can be found at [https://github.com/deviantony/docker-elk](https://github.com/deviantony/docker-elk)
*  "xetus-oss" dockerfiles, which can be found at [https://github.com/xetus-oss/docker-ossec-server](https://github.com/xetus-oss/docker-ossec-server)

We thank them and everyone else who has contributed to this project.

## License and copyright

Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

## Web references

[Wazuh website](http://wazuh.com)