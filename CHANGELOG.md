## [5.1.0]

### Added

| Issue | Comment |
| - | - |

### Changed

| Issue | Comment |
| - | - |
| [#6124](https://github.com/wazuh/internal-devel-requests/issues/6124) | Bind multi-node indexer nodes to their DNS hostname |
| [#2676](https://github.com/wazuh/wazuh-docker/issues/2676) | Replace manual `authd.pass`/`<endpoint>` writing in the agent's `0-wazuh-init` with `WAZUH_ENROLLMENT_TOKEN` support, following wazuh/wazuh#39063 |
| [#2652](https://github.com/wazuh/wazuh-docker/issues/2652) | Mount the Wazuh manager agent listener certificate, and forward `--agent-san` to the certificate creation tool |
| [#2635](https://github.com/wazuh/wazuh-docker/issues/2635) | Honour the scheme given in `WAZUH_INDEXER_HOSTS`, and drop the `<ssl>` block from the indexer configuration when it resolves to `http` |
| [#2621](https://github.com/wazuh/wazuh-docker/pull/2621) | Change cluster key assigment |
| [#2622](https://github.com/wazuh/wazuh-docker/issues/2622) | Check the Wazuh API accounts of every manager node in `check-default-credentials.sh`, and document the worker step of the multi-node password change |
| [#6058](https://github.com/wazuh/internal-devel-requests/issues/6058) | Remove the OpenSearch demo users from the indexer image, add `password-tool.sh` to change the indexer and API passwords of a running deployment, and stop publishing the indexer port `9200` |
| [#2461](https://github.com/wazuh/wazuh-docker/issues/2461) | Added explicit `permissions` blocks to the 4.x workflows to restrict the `GITHUB_TOKEN` scope |
| [#2601](https://github.com/wazuh/wazuh-docker/issues/2601) | Regenerate the manager self-signed server certificate per container at first boot |

### Removed

| Issue | Comment |
| - | - |

### Fixed

| Issue | Comment |
| - | - |

## Prior versions

- [v5.0.1](https://github.com/wazuh/wazuh-docker/blob/v5.0.1/CHANGELOG.md)
- [v5.0.0](https://github.com/wazuh/wazuh-docker/blob/v5.0.0/CHANGELOG.md)
