## [5.1.0]

### Added

| Issue | Comment |
| - | - |

### Changed

| Issue | Comment |
| - | - |
| [#2461](https://github.com/wazuh/wazuh-docker/issues/2461) | Added explicit `permissions` blocks to the 4.x workflows to restrict the `GITHUB_TOKEN` scope |
| [#2601](https://github.com/wazuh/wazuh-docker/issues/2601) | Regenerate the manager self-signed server certificate per container at first boot |

### Removed

| Issue | Comment |
| - | - |

### Fixed

| Issue | Comment |
| - | - |
| [#2627](https://github.com/wazuh/wazuh-docker/issues/2627) | Manager healthcheck now catches all failure states, not just 'not running': single-node and the cluster master use the command's own exit code, and the worker checks for all known failure strings instead of just one |

## Prior versions

- [v5.0.1](https://github.com/wazuh/wazuh-docker/blob/v5.0.1/CHANGELOG.md)
- [v5.0.0](https://github.com/wazuh/wazuh-docker/blob/v5.0.0/CHANGELOG.md)
