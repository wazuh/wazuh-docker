# Wazuh containers for Docker

[![Slack](https://img.shields.io/badge/slack-join-blue.svg)](https://wazuh.com/community/join-us-on-slack/)
[![Email](https://img.shields.io/badge/email-join-blue.svg)](https://groups.google.com/forum/#!forum/wazuh)
[![Documentation](https://img.shields.io/badge/docs-view-green.svg)](https://documentation.wazuh.com)
[![Documentation](https://img.shields.io/badge/web-view-green.svg)](https://wazuh.com)

In this repository you will find the containers to run:

* Wazuh manager: it runs the Wazuh manager, Wazuh API and Filebeat OSS
* Wazuh dashboard: provides a web user interface to browse through alerts data and allows you to visualize agents configuration and status.
* Wazuh indexer: Wazuh indexer container (working as a single-node cluster). **Be aware to increase the `vm.max_map_count` setting, as it's detailed in the [Wazuh documentation](https://documentation.wazuh.com/current/docker/wazuh-container.html#increase-max-map-count-on-your-host-linux).**

In addition, a docker-compose file is provided to launch the containers mentioned above.

* Wazuh indexer cluster. In the Wazuh indexer Dockerfile we can visualize variables to configure an Wazuh indexer Cluster. These variables are used in the file *config_cluster.sh* to set them in the *opensearch.yml* configuration file. You can see the meaning of the node variables [here](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html) and other cluster settings [here](https://github.com/elastic/elasticsearch/blob/master/distribution/src/config/elasticsearch.yml).

## Documentation

* [Wazuh full documentation](http://documentation.wazuh.com)
* [Wazuh documentation for Docker](https://documentation.wazuh.com/current/docker/index.html)
* [Docker hub](https://hub.docker.com/u/wazuh)


### Setup SSL certificate

Before starting the environment it is required to provide an SSL certificate (or just generate one self-signed).

Documentation on how to provide these two can be found at [Wazuh Docker Documentation](https://documentation.wazuh.com/current/docker/wazuh-container.html#production-deployment).


## Environment Variables

Default values are included when available.

### Wazuh
```
API_USERNAME="wazuh"                                # Wazuh API username
API_PASSWORD="wazuh"                                # Wazuh API password - Must comply with requirements
                                                    # (8+ length, uppercase, lowercase, specials chars)

INDEXER_URL=https://wazuh1.indexer:9200             # Wazuh indexer URL
INDEXER_USERNAME=admin                              # Wazuh indexer Username
INDEXER_PASSWORD=admin                              # Wazuh indexer Password
FILEBEAT_SSL_VERIFICATION_MODE=full                 # Filebeat SSL Verification mode (full or none)
SSL_CERTIFICATE_AUTHORITIES=""                      # Path of Filebeat SSL CA
SSL_CERTIFICATE=""                                  # Path of Filebeat SSL Certificate
SSL_KEY=""                                          # Path of Filebeat SSL Key
```

### Kibana
```
PATTERN="wazuh-alerts-*"        # Default index pattern to use

CHECKS_PATTERN=true             # Defines which checks must to be consider by the healthcheck
CHECKS_TEMPLATE=true            # step once the Wazuh app starts. Values must to be true or false
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

WAZUH_MONITORING_ENABLED=true       # Custom settings to enable/disable wazuh-monitoring indices
WAZUH_MONITORING_CREATION=d         # Custom setting to set the wazuh-monitoring-* indices creation interval
WAZUH_MONITORING_FREQUENCY=900      # Custom setting to set the frequency for wazuh-monitoring indices cron task
WAZUH_MONITORING_SHARDS=2           # Configure wazuh-monitoring-* indices shards and replicas
WAZUH_MONITORING_REPLICAS=0         #

ADMIN_PRIVILEGES=true               # App privileges
```

## Directory structure

├── build-wazuh-images.yml
├── CHANGELOG.md
├── docker-compose.yml
├── generate-indexer-certs.yml
├── LICENSE
├── production_cluster
│   ├── nginx
│   │   ├── nginx.conf
│   │   └── ssl
│   │       └── generate-self-signed-cert.sh
│   ├── wazuh_cluster
│   │   ├── wazuh_manager.conf
│   │   └── wazuh_worker.conf
│   ├── wazuh_dashboard
│   │   └── opensearch_dashboards.yml
│   ├── wazuh-indexer
│   │   ├── internal_users.yml
│   │   ├── opensearch.yml
│   │   ├── wazuh1.indexer.yml
│   │   ├── wazuh2.indexer.yml
│   │   └── wazuh3.indexer.yml
│   └── wazuh_indexer_ssl_certs
│       └── certs.yml
├── production-cluster.yml
├── README.md
├── VERSION
├── wazuh-dashboard
│   ├── config
│   │   ├── opensearch_dashboards.yml
│   │   ├── entrypoint.sh
│   │   ├── wazuh_app_config.sh
│   │   └── wazuh.yml
│   └── Dockerfile
├── wazuh-indexer
│   ├── config
│   │   ├── config.sh
│   │   ├── config.yml
│   │   ├── entrypoint.sh
│   │   ├── opensearch.yml
│   │   ├── securityadmin.sh
│   │   └── unattended_installer.tar.gz
│   └── Dockerfile
└── wazuh-manager
    ├── config
    │   ├── create_user.py
    │   ├── etc
    │   │   ├── cont-init.d
    │   │   │   ├── 0-wazuh-init
    │   │   │   ├── 1-config-filebeat
    │   │   │   └── 2-manager
    │   │   └── services.d
    │   │       ├── filebeat
    │   │       │   ├── finish
    │   │       │   └── run
    │   │       └── ossec-logs
    │   │           └── run
    │   ├── filebeat.yml
    │   ├── permanent_data.env
    │   ├── permanent_data.sh
    │   └── wazuh.repo
    └── Dockerfile


## Branches

* `master` branch contains the latest code, be aware of possible bugs on this branch.
* `stable` branch on correspond to the last Wazuh stable version.

## Compatibility Matrix

| Wazuh version | ODFE    | XPACK  |
|---------------|---------|--------|
| v4.3.0        |         | 7.11.2 |
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

We thank you them and everyone else who has contributed to this project.

## License and copyright

Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)

## Web references

[Wazuh website](http://wazuh.com)
