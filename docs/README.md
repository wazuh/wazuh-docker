# Wazuh containers for Docker

[![Slack](https://img.shields.io/badge/slack-join-blue.svg)](https://wazuh.com/community/join-us-on-slack/)
[![Email](https://img.shields.io/badge/email-join-blue.svg)](https://groups.google.com/forum/#!forum/wazuh)
[![Documentation](https://img.shields.io/badge/docs-view-green.svg)](https://documentation.wazuh.com)
[![Documentation](https://img.shields.io/badge/web-view-green.svg)](https://wazuh.com)

In this repository you will find the containers to run:

* Wazuh manager: it runs the Wazuh manager, and Wazuh API
* Wazuh dashboard: provides a web user interface to browse through alert data and allows you to visualize the agents configuration and status.
* Wazuh indexer: Wazuh indexer container (working as a single-node cluster or as a multi-node cluster). **Be aware to increase the `vm.max_map_count` setting, as it's detailed in the [Wazuh documentation](https://documentation.wazuh.com/current/docker/wazuh-container.html#increase-max-map-count-on-your-host-linux).**
* Wazuh agent: This container contains the Wazuh agent services. Current functionality is limited.

The folder `build-docker-images` contains a README explaining how to build the Wazuh images and the necessary assets.
The folder `indexer-certs-creator` contains a README explaining how to create the certificates creator tool and the necessary assets.
The folder `single-node` contains a README explaining how to run a Wazuh environment with one Wazuh manager, one Wazuh indexer, and one Wazuh dashboard.
The folder `multi-node` contains a README explaining how to run a Wazuh environment with two Wazuh managers, three Wazuh indexers, and one Wazuh dashboard.
The folder `wazuh-agent` contains a README explaining how to run a container with Wazuh agent.

## Documentation

* [Wazuh full documentation](http://documentation.wazuh.com)
* [Wazuh documentation for Docker](https://documentation.wazuh.com/current/docker/index.html)
* [Docker Hub](https://hub.docker.com/u/wazuh)

## Directory structure

	├── build-docker-images
	│   ├── build-images.sh
	│   ├── docker-bake.hcl
	│   ├── README.md
	│   ├── wazuh-agent
	│   │   ├── config
	│   │   │   ├── check_repository.sh
	│   │   │   └── etc
	│   │   │       ├── cont-init.d
	│   │   │       │   ├── 0-wazuh-init
	│   │   │       │   └── 1-agent
	│   │   │       └── services.d
	│   │   │           └── ossec-logs
	│   │   │               └── run
	│   │   └── Dockerfile
	│   ├── wazuh-dashboard
	│   │   ├── config
	│   │   │   ├── entrypoint.sh
	│   │   │   ├── wazuh_dashboard_config.sh
	│   │   └── Dockerfile
	│   ├── wazuh-indexer
	│   │   ├── config
	│   │   │   ├── config.sh
	│   │   │   ├── entrypoint.sh
	│   │   │   └── securityadmin.sh
	│   │   └── Dockerfile
	│   └── wazuh-manager
	│       ├── config
	│       │   ├── create_user.py
	│       │   ├── etc
	│       │   │   ├── cont-init.d
	│       │   │   │   ├── 0-wazuh-init
	│       │   │   │   └── 2-manager
	│       │   │   └── services.d
	│       │   │       └── wazuh-manager-logs
	│       │   │           └── run
	│       │   ├── permanent_data.env
	│       │   └── permanent_data.sh
	│       └── Dockerfile
	├── CHANGELOG.md
	├── docs
	│   ├── book.toml
	│   ├── build.sh
	│   ├── dev
	│   │   ├── build-image.md
	│   │   ├── README.md
	│   │   ├── run-tests.md
	│   │   └── setup.md
	│   ├── README.md
	│   ├── ref
	│   │   ├── configuration
	│   │   │   ├── configuration-files.md
	│   │   │   ├── environment-variables.md
	│   │   │   └── README.md
	│   │   ├── getting-started
	│   │   │   ├── deployment
	│   │   │   │   ├── multi-node.md
	│   │   │   │   ├── README.md
	│   │   │   │   ├── single-node.md
	│   │   │   │   └── wazuh-agent.md
	│   │   │   ├── README.md
	│   │   │   └── requirements.md
	│   │   ├── glossary.md
	│   │   ├── introduction
	│   │   │   ├── compatibility.md
	│   │   │   ├── description.md
	│   │   │   └── README.md
	│   │   ├── README.md
	│   │   └── upgrade.md
	│   ├── server.sh
	│   └── SUMMARY.md
	├── indexer-certs-creator
	│   ├── config
	│   │   └── entrypoint.sh
	│   ├── Dockerfile
	│   └── README.md
	├── LICENSE
	├── multi-node
	│   ├── config
	│   │   ├── certs.yml
	│   │   ├── nginx
	│   │   │   └── nginx.conf
	│   │   ├── wazuh_cluster
	│   │   │   ├── wazuh_manager.conf
	│   │   │   └── wazuh_worker.conf
	│   │   ├── wazuh_dashboard
	│   │   │   ├── opensearch_dashboards.yml
	│   │   │   └── wazuh.yml
	│   │   └── wazuh_indexer
	│   │       ├── internal_users.yml
	│   │       ├── wazuh1.indexer.yml
	│   │       ├── wazuh2.indexer.yml
	│   │       └── wazuh3.indexer.yml
	│   ├── docker-compose.yml
	│   ├── generate-indexer-certs.yml
	│   ├── Migration-to-Wazuh-4.4.md
	│   ├── README.md
	│   └── volume-migrator.sh
	├── README.md
	├── SECURITY.md
	├── single-node
	│   ├── config
	│   │   ├── certs.yml
	│   │   ├── wazuh_cluster
	│   │   │   └── wazuh_manager.conf
	│   │   ├── wazuh_dashboard
	│   │   │   ├── opensearch_dashboards.yml
	│   │   │   └── wazuh.yml
	│   │   ├── wazuh_indexer
	│   │   │   ├── internal_users.yml
	│   │   │   └── wazuh.indexer.yml
	│   │   └── wazuh_indexer_ssl_certs  [error opening dir]
	│   ├── docker-compose.yml
	│   ├── generate-indexer-certs.yml
	│   └── README.md
	├── VERSION.json
	└── wazuh-agent
		├── config
		│   └── wazuh-agent-conf
		└── docker-compose.yml

## Branches

* `main` branch contains the latest code, be aware of possible bugs on this branch.

## Compatibility Matrix

| Wazuh version | ODFE    | XPACK  |
|---------------|---------|--------|
| v4.3.0+       |         |        |
| v4.2.7        | 1.13.2  | 7.11.2 |
| v4.2.6        | 1.13.2  | 7.11.2 |
| v4.2.5        | 1.13.2  | 7.11.2 |
| v4.2.4        | 1.13.2  | 7.11.2 |
| v4.2.3        | 1.13.2  | 7.11.2 |
| v4.2.2        | 1.13.2  | 7.11.2 |
| v4.2.1        | 1.13.2  | 7.11.2 |
| v4.2.0        | 1.13.2  | 7.10.2 |
| v4.1.5        | 1.13.2  | 7.10.2 |
| v4.1.4        | 1.12.0  | 7.10.2 |
| v4.1.3        | 1.12.0  | 7.10.2 |
| v4.1.2        | 1.12.0  | 7.10.2 |
| v4.1.1        | 1.12.0  | 7.10.2 |
| v4.1.0        | 1.12.0  | 7.10.2 |
| v4.0.4        | 1.11.0  |        |
| v4.0.3        | 1.11.0  |        |
| v4.0.2        | 1.11.0  |        |
| v4.0.1        | 1.11.0  |        |
| v4.0.0        | 1.10.1  |        |

## Credits and Thank you

These Docker containers are based on:

*  "deviantony" dockerfiles which can be found at [https://github.com/deviantony/docker-elk](https://github.com/deviantony/docker-elk)
*  "xetus-oss" dockerfiles, which can be found at [https://github.com/xetus-oss/docker-ossec-server](https://github.com/xetus-oss/docker-ossec-server)

We thank them and everyone else who has contributed to this project.

## License and copyright

Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

## Web references

[Wazuh website](http://wazuh.com)