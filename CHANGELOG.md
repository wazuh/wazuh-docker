# Change Log
All notable changes to this project will be documented in this file.

## v3.x.x_6.x.x

## v3.7.0_6.4.3

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

## v3.6.1_6.4.3

Wazuh-Docker starting point.
