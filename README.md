# Wazuh containers for Docker

[![Slack](https://img.shields.io/badge/slack-join-blue.svg)](https://wazuh.com/community/join-us-on-slack/)
[![Email](https://img.shields.io/badge/email-join-blue.svg)](https://groups.google.com/forum/#!forum/wazuh)
[![Documentation](https://img.shields.io/badge/docs-view-green.svg)](https://documentation.wazuh.com)
[![Documentation](https://img.shields.io/badge/web-view-green.svg)](https://wazuh.com)

In this repository you will find the containers to run:

* Wazuh manager: it runs the Wazuh manager, Wazuh API and Filebeat OSS
* Wazuh dashboard: provides a web user interface to browse through alert data and allows you to visualize the agents configuration and status.
* Wazuh indexer: Wazuh indexer container (working as a single-node cluster or as a multi-node cluster). **Be aware to increase the `vm.max_map_count` setting, as it's detailed in the [Wazuh documentation](https://documentation.wazuh.com/current/docker/wazuh-container.html#increase-max-map-count-on-your-host-linux).**

The folder `build-docker-images` contains a README explaining how to build the Wazuh images and the necessary assets.
The folder `indexer-certs-creator` contains a README explaining how to create the certificates creator tool and the necessary assets.
The folder `single-node` contains a README explaining how to run a Wazuh environment with one Wazuh manager, one Wazuh indexer, and one Wazuh dashboard.
The folder `multi-node` contains a README explaining how to run a Wazuh environment with two Wazuh managers, three Wazuh indexers, and one Wazuh dashboard.

## Documentation

* [Wazuh full documentation](http://documentation.wazuh.com)
* [Wazuh documentation for Docker](https://documentation.wazuh.com/current/docker/index.html)
* [Docker Hub](https://hub.docker.com/u/wazuh)


### Setup SSL certificate

Before starting the environment it is required to provide an SSL certificate (or just generate one self-signed).

Documentation on how to provide these two can be found at [Wazuh Docker Documentation](https://documentation.wazuh.com/current/docker/wazuh-container.html#production-deployment).


## Environment Variables

Default values are included when available.

### Wazuh
```
API_USERNAME="wazuh-wui"                            # Wazuh API username
API_PASSWORD="MyS3cr37P450r.*-"                     # Wazuh API password - Must comply with requirements
                                                    # (8+ length, uppercase, lowercase, special chars)

INDEXER_URL=https://wazuh.indexer:9200              # Wazuh indexer URL
INDEXER_USERNAME=admin                              # Wazuh indexer Username
INDEXER_PASSWORD=SecretPassword                     # Wazuh indexer Password
FILEBEAT_SSL_VERIFICATION_MODE=full                 # Filebeat SSL Verification mode (full or none)
SSL_CERTIFICATE_AUTHORITIES=""                      # Path of Filebeat SSL CA
SSL_CERTIFICATE=""                                  # Path of Filebeat SSL Certificate
SSL_KEY=""                                          # Path of Filebeat SSL Key
```

### Dashboard
```
PATTERN="wazuh-alerts-*"        # Default index pattern to use

CHECKS_PATTERN=true             # Defines which checks must be considered by the healthcheck
CHECKS_TEMPLATE=true            # step once the Wazuh app starts. Values must be true or false
CHECKS_API=true
CHECKS_SETUP=true

EXTENSIONS_PCI=true             # Enable PCI Extension
EXTENSIONS_GDPR=true            # Enable GDPR Extension
EXTENSIONS_HIPAA=true           # Enable HIPAA Extension
EXTENSIONS_NIST=true            # Enable NIST Extension
EXTENSIONS_TSC=true             # Enable TSC Extension
EXTENSIONS_AUDIT=true           # Enable Audit Extension
EXTENSIONS_OSCAP=false          # Enable OpenSCAP Extension
EXTENSIONS_CISCAT=false         # Enable CISCAT Extension
EXTENSIONS_AWS=false            # Enable AWS Extension
EXTENSIONS_GCP=false            # Enable GCP Extension
EXTENSIONS_VIRUSTOTAL=false     # Enable Virustotal Extension
EXTENSIONS_OSQUERY=false        # Enable OSQuery Extension
EXTENSIONS_DOCKER=false         # Enable Docker Extension

APP_TIMEOUT=20000               # Defines maximum timeout to be used on the Wazuh app requests

API_SELECTOR=true               Defines if the user is allowed to change the selected API directly from the Wazuh app top menu
IP_SELECTOR=true                # Defines if the user is allowed to change the selected index pattern directly from the Wazuh app top menu
IP_IGNORE="[]"                  # List of index patterns to be ignored

DASHBOARD_USERNAME=kibanaserver     # Custom user saved in the dashboard keystore
DASHBOARD_PASSWORD=kibanaserver     # Custom password saved in the dashboard keystore
WAZUH_MONITORING_ENABLED=true       # Custom settings to enable/disable wazuh-monitoring indices
WAZUH_MONITORING_FREQUENCY=900      # Custom setting to set the frequency for wazuh-monitoring indices cron task
WAZUH_MONITORING_SHARDS=2           # Configure wazuh-monitoring-* indices shards and replicas
WAZUH_MONITORING_REPLICAS=0         ##
```

## Directory structure

    ├── build-docker-images
    │   ├── build-images.sh
    │   ├── build-images.yml
    │   ├── README.md
    │   ├── wazuh-dashboard
    │   │   ├── config
    │   │   │   ├── config.sh
    │   │   │   ├── config.yml
    │   │   │   ├── dl_base.sh
    │   │   │   ├── entrypoint.sh
    │   │   │   ├── install_wazuh_app.sh
    │   │   │   ├── opensearch_dashboards.yml
    │   │   │   ├── wazuh_app_config.sh
    │   │   │   └── wazuh.yml
    │   │   └── Dockerfile
    │   ├── wazuh-indexer
    │   │   ├── config
    │   │   │   ├── action_groups.yml
    │   │   │   ├── config.sh
    │   │   │   ├── config.yml
    │   │   │   ├── entrypoint.sh
    │   │   │   ├── internal_users.yml
    │   │   │   ├── opensearch.yml
    │   │   │   ├── roles_mapping.yml
    │   │   │   ├── roles.yml
    │   │   │   └── securityadmin.sh
    │   │   └── Dockerfile
    │   └── wazuh-manager
    │       ├── config
    │       │   ├── check_repository.sh
    │       │   ├── create_user.py
    │       │   ├── etc
    │       │   │   ├── cont-init.d
    │       │   │   │   ├── 0-wazuh-init
    │       │   │   │   ├── 1-config-filebeat
    │       │   │   │   └── 2-manager
    │       │   │   └── services.d
    │       │   │       ├── filebeat
    │       │   │       │   ├── finish
    │       │   │       │   └── run
    │       │   │       └── ossec-logs
    │       │   │           └── run
    │       │   ├── filebeat_module.sh
    │       │   ├── filebeat.yml
    │       │   ├── permanent_data.env
    │       │   └── permanent_data.sh
    │       └── Dockerfile
    ├── CHANGELOG.md
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
    │   │   └── wazuh_indexer
    │   │       ├── internal_users.yml
    │   │       └── wazuh.indexer.yml
    │   ├── docker-compose.yml
    │   ├── generate-indexer-certs.yml
    │   └── README.md
    └── VERSION



## Branches

* `master` branch contains the latest code, be aware of possible bugs on this branch.
* `stable` branch corresponds to the last Wazuh stable version.

## Compatibility Matrix

| Wazuh version | ODFE    | XPACK  |
|---------------|---------|--------|
| v4.9.2        |         |        |
| v4.9.1        |         |        |
| v4.9.0        |         |        |
| v4.8.2        |         |        |
| v4.8.1        |         |        |
| v4.8.0        |         |        |
| v4.7.5        |         |        |
| v4.7.4        |         |        |
| v4.7.3        |         |        |
| v4.7.2        |         |        |
| v4.7.1        |         |        |
| v4.7.0        |         |        |
| v4.6.0        |         |        |
| v4.5.4        |         |        |
| v4.5.3        |         |        |
| v4.5.2        |         |        |
| v4.5.1        |         |        |
| v4.5.0        |         |        |
| v4.4.5        |         |        |
| v4.4.4        |         |        |
| v4.4.3        |         |        |
| v4.4.2        |         |        |
| v4.4.1        |         |        |
| v4.4.0        |         |        |
| v4.3.11       |         |        |
| v4.3.10       |         |        |
| v4.3.9        |         |        |
| v4.3.8        |         |        |
| v4.3.7        |         |        |
| v4.3.6        |         |        |
| v4.3.5        |         |        |
| v4.3.4        |         |        |
| v4.3.3        |         |        |
| v4.3.2        |         |        |
| v4.3.1        |         |        |
| v4.3.0        |         |        |
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
