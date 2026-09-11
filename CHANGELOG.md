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
| [#2629](https://github.com/wazuh/wazuh-docker/issues/2629) | Append `opensearch_security.cookie.ttl` when missing from `opensearch_dashboards.yml` instead of silently discarding `OPENSEARCH_SECURITY_COOKIE_TTL`; removed the `PATTERN`, `CHECKS_*`, `APP_TIMEOUT`, `API_SELECTOR`, `IP_SELECTOR`, `IP_IGNORE` and `WAZUH_MONITORING_*` environment variables, which no longer correspond to any setting the dashboard plugin accepts |

## Prior versions

- [v5.0.1](https://github.com/wazuh/wazuh-docker/blob/v5.0.1/CHANGELOG.md)
- [v5.0.0](https://github.com/wazuh/wazuh-docker/blob/v5.0.0/CHANGELOG.md)
