# Change Log
All notable changes to this project will be documented in this file.

## Wazuh Docker v3.10.2_7.3.2

### Added

- Update to Wazuh version 3.10.2_7.3.2

## Wazuh Docker v3.10.0_7.3.2

### Added

- Update to Wazuh version 3.10.0_7.3.2

## Wazuh Docker v3.9.5_7.2.1

### Added

- Update to Wazuh version 3.9.5_7.2.1

## Wazuh Docker v3.9.4_7.2.0

### Added

- Update to Wazuh version 3.9.4_7.2.0
- Implemented Wazuh Filebeat Module ([jm404](https://www.github.com/jm404)) [#2a77c6a](https://github.com/wazuh/wazuh-docker/commit/2a77c6a6e6bf78f2492adeedbade7a507d9974b2)


## Wazuh Docker v3.9.3_7.2.0

### Fixed
- Wazuh-docker reinserts cluster settings after resuming containers ([@manuasir](https://github.com/manuasir)) [#213](https://github.com/wazuh/wazuh-docker/pull/213)

## Wazuh Docker v3.9.2_7.1.1

### Added

- Update to Wazuh version 3.9.2_7.1.1

## Wazuh Docker v3.9.3_6.8.1

### Added

- Update to Wazuh version 3.9.3_6.8.1
- Option to disable additionals X-Pack applications and hide unnecesary management links ([@SitoRBJ](https://github.com/SitoRBJ)) ([#163](https://github.com/wazuh/wazuh-docker/pull/163))


## Wazuh Docker v3.9.2_6.8.0

### Added

- Update to Wazuh version 3.9.2_6.8.0


## Wazuh Docker v3.9.1_7.1.0

### Added

- Support for Elastic v7.1.0
- New environment variables for Kibana ([@manuasir](https://github.com/manuasir)) [#22ad43](https://github.com/wazuh/wazuh-docker/commit/22ad4360f548e54bb0c5e929f8c84a186ad2ab88)

## Wazuh Docker v3.9.1_6.8.0

### Added

- Update to Wazuh version 3.9.1_6.8.0 ([#181](https://github.com/wazuh/wazuh-docker/pull/181))
- Security for Elastic Stack in Docker implemented ([#186](https://github.com/wazuh/wazuh-docker/issues/186))

### Fixed

- Fixed `ELASTICSEARCH_KIBANA_IP` environment variable ([@manuasir](https://github.com/manuasir)) ([#181](https://github.com/wazuh/wazuh-docker/pull/181))


## Wazuh Docker v3.9.1_7.1.0

### Added

- Support for Elastic v7.1.0
- New environment variables for Kibana ([@manuasir](https://github.com/manuasir)) [#22ad43](https://github.com/wazuh/wazuh-docker/commit/22ad4360f548e54bb0c5e929f8c84a186ad2ab88)


## Wazuh Docker v3.9.0_6.7.2

### Changed

- Update Elastic Stack version to 6.7.2.

## Wazuh Docker v3.9.0_6.7.1


### Added

- Support for xPACK authorized requests ([@manuasir](https://github.com/manuasir)) ([#119](https://github.com/wazuh/wazuh-docker/pull/119))
- Add Elasticsearch cluster configuration ([@SitoRBJ](https://github.com/SitoRBJ)). ([#146](https://github.com/wazuh/wazuh-docker/pull/146))
- Add Elasticsearch cluster configuration ([@Phandora](https://github.com/Phandora)) ([#140](https://github.com/wazuh/wazuh-docker/pull/140))
- Setting Nginx to support several user/passwords in Kibana ([@toniMR](https://github.com/toniMR)) ([#136](https://github.com/wazuh/wazuh-docker/pull/136))


### Changed

- Use LS_JAVA_OPTS instead of old LS_HEAP_SIZE ([@ruffy91](https://github.com/ruffy91)) ([#139](https://github.com/wazuh/wazuh-docker/pull/139))
- Changing the original Wazuh docker image to allow adding code in the entrypoint ([@Phandora](https://github.com/phandora)) ([#151](https://github.com/wazuh/wazuh-docker/pull/151))

### Removed

- Removing files from Wazuh image ([@Phandora](https://github.com/phandora)) ([#153](https://github.com/wazuh/wazuh-docker/pull/153))

## Wazuh Docker v3.8.2_6.7.0

### Changed

- Update Elastic Stack version to 6.7.0. ([#144](https://github.com/wazuh/wazuh-docker/pull/144))

## Wazuh Docker v3.8.2_6.6.2

### Changed

- Update Elastic Stack version to 6.6.2. ([#130](https://github.com/wazuh/wazuh-docker/pull/130))

## Wazuh Docker v3.8.2_6.6.1

### Changed

- Update Elastic Stack version to 6.6.1. ([#129](https://github.com/wazuh/wazuh-docker/pull/129))

## Wazuh Docker v3.8.2_6.5.4

### Added

- Add Wazuh-Elasticsearch. ([#106](https://github.com/wazuh/wazuh-docker/pull/106))
- Store Filebeat _/var/lib/filebeat/registry._ ([#109](https://github.com/wazuh/wazuh-docker/pull/109))
- Adding the option to disable some xpack features. ([#111](https://github.com/wazuh/wazuh-docker/pull/111))
- Wazuh-Kibana customizable at plugin level. ([#117](https://github.com/wazuh/wazuh-docker/pull/117))
- Adding env variables for alerts data flow. ([#118](https://github.com/wazuh/wazuh-docker/pull/118))
- New Logstash entrypoint added. ([#135](https://github.com/wazuh/wazuh-docker/pull/135/files))
- Welcome screen management. ([#133](https://github.com/wazuh/wazuh-docker/pull/133))

### Changed

- Update to Wazuh version 3.8.2. ([#105](https://github.com/wazuh/wazuh-docker/pull/105))

### Removed

- Remove alerts created in build time. ([#137](https://github.com/wazuh/wazuh-docker/pull/137))


## Wazuh Docker v3.8.1_6.5.4

### Changed
- Update to Wazuh version 3.8.1. ([#102](https://github.com/wazuh/wazuh-docker/pull/102))

## Wazuh Docker v3.8.0_6.5.4

### Changed

- Upgrade version 3.8.0_6.5.4. ([#97](https://github.com/wazuh/wazuh-docker/pull/97))

### Removed

- Remove cluster.py work around. ([#99](https://github.com/wazuh/wazuh-docker/pull/99))

## Wazuh Docker v3.7.2_6.5.4

### Added

- Improvements to Kibana settings added. ([#91](https://github.com/wazuh/wazuh-docker/pull/91))
- Add Kibana environmental variables for Wazuh APP config.yml. ([#89](https://github.com/wazuh/wazuh-docker/pull/89))

### Changed

- Update Elastic Stack version to 6.5.4. ([#82](https://github.com/wazuh/wazuh-docker/pull/82))
- Add env credentials for nginx. ([#86](https://github.com/wazuh/wazuh-docker/pull/86))
- Improve filebeat configuration ([#88](https://github.com/wazuh/wazuh-docker/pull/88))

### Fixed 

- Temporary fix for Wazuh cluster master node in Kubernetes. ([#84](https://github.com/wazuh/wazuh-docker/pull/84))

## Wazuh Docker v3.7.2_6.5.3

### Changed

- Erasing temporary fix for AWS integration. ([#81](https://github.com/wazuh/wazuh-docker/pull/81))

### Fixed

- Upgrading errors due to wrong files. ([#80](https://github.com/wazuh/wazuh-docker/pull/80))


## Wazuh Docker v3.7.0_6.5.0

### Changed

- Adapt to Elastic stack 6.5.0.

## Wazuh Docker v3.7.0_6.4.3

### Added

- Allow custom scripts or commands before service start ([#58](https://github.com/wazuh/wazuh-docker/pull/58))
- Added description for wazuh-nginx ([#59](https://github.com/wazuh/wazuh-docker/pull/59))
- Added license file to match https://github.com/wazuh/wazuh LICENSE ([#60](https://github.com/wazuh/wazuh-docker/pull/60))
- Added SMTP packages ([#67](https://github.com/wazuh/wazuh-docker/pull/67))

### Changed

- Increased proxy buffer for NGINX Kibana ([#51](https://github.com/wazuh/wazuh-docker/pull/51))
- Updated logstash config to remove deprecation warnings ([#55](https://github.com/wazuh/wazuh-docker/pull/55))
- Set ossec user's home path ([#61](https://github.com/wazuh/wazuh-docker/pull/61))

### Fixed

- Fixed a bug that prevents the API from starting when the Wazuh manager was updated. Change in the files that are stored in the volume.  ([#65](https://github.com/wazuh/wazuh-docker/pull/65))
- Fixed script reference ([#62](https://github.com/wazuh/wazuh-docker/pull/62/files))

## Wazuh Docker v3.6.1_6.4.3

Wazuh-Docker starting point.
