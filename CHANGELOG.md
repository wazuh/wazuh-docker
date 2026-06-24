# Change Log
All notable changes to this project will be documented in this file.

## [5.0.0]

### Added

- Implement the wazuh-docker integration testing module ([#2428](https://github.com/wazuh/wazuh-docker/pull/2428))
- Add revert option into bumper workflow ([#2330](https://github.com/wazuh/wazuh-docker/pull/2330))
- Add checks for artifact_urls.yaml download ([#2315](https://github.com/wazuh/wazuh-docker/pull/2315))
- Add set_as_main option ([#2293](https://github.com/wazuh/wazuh-docker/pull/2293))

### Changed

- Change runners on repository workflows 5.x ([#2471](https://github.com/wazuh/wazuh-docker/pull/2471))
- PR revamp modifications 5.x ([#2446](https://github.com/wazuh/wazuh-docker/pull/2446))
- Forbid pr_check workflow execution in draft PRs ([#2399](https://github.com/wazuh/wazuh-docker/pull/2399))
- Unification of user UID and GID ([#2393](https://github.com/wazuh/wazuh-docker/pull/2393))
- Add Wazuh indexer engine start on entrypoint ([#2390](https://github.com/wazuh/wazuh-docker/pull/2390))
- Image build process update ([#2358](https://github.com/wazuh/wazuh-docker/pull/2358))
- Add new path on artifact_urls file ([#2344](https://github.com/wazuh/wazuh-docker/pull/2344))
- Presigned URLs generation enhancement ([#2346](https://github.com/wazuh/wazuh-docker/pull/2346))
- Adapt bumper workflows to change main branch ([#2294](https://github.com/wazuh/wazuh-docker/pull/2294))
- Delete all API user and password references and Wazuh agent references ([#2289](https://github.com/wazuh/wazuh-docker/pull/2289))
- Create certificate directory with default user and group ([#2287](https://github.com/wazuh/wazuh-docker/pull/2287))
- Standarize Artifact URL keys ([#2286](https://github.com/wazuh/wazuh-docker/pull/2286))
- Certificates configuration script. ([#2285](https://github.com/wazuh/wazuh-docker/pull/2285))
- Modify artifact URLs file name. ([#2266](https://github.com/wazuh/wazuh-docker/pull/2266))
- Use URL signing script to generate presigned internal package URLs. ([#2259](https://github.com/wazuh/wazuh-docker/pull/2259))
- Updated wazuh-docker documentation config and tooling versions to meet new standards. ([#2264](https://github.com/wazuh/wazuh-docker/pull/2264))
- Update certificate configuration to use separate IP and DNS fields ([#2253](https://github.com/wazuh/wazuh-docker/pull/2253))
- Modify Healthchecks ([#2252](https://github.com/wazuh/wazuh-docker/pull/2252))
- Add deployment healthchecks ([#2251](https://github.com/wazuh/wazuh-docker/pull/2251))
- Update artifact generation jobs to use wz-linux dedicated runner group ([#2242](https://github.com/wazuh/wazuh-docker/pull/2242))
- Fix set_correct_permOwner function ([#2238](https://github.com/wazuh/wazuh-docker/pull/2238))
- Add workflow dispatch option ([#2231](https://github.com/wazuh/wazuh-docker/pull/2231))
- Change Wazuh manager certificates names ([#2223](https://github.com/wazuh/wazuh-docker/pull/2223))
- Move index documents test ([#2221](https://github.com/wazuh/wazuh-docker/pull/2221))
- Separate Agent/Manager - Docker - Adapt image build process ([#2220](https://github.com/wazuh/wazuh-docker/pull/2220))
- Remove revision input ([#2217](https://github.com/wazuh/wazuh-docker/pull/2217))
- Improve build script and workflow component revisions handling ([#2212](https://github.com/wazuh/wazuh-docker/pull/2212))
- Add missing documentation sections in the repository ([#2215](https://github.com/wazuh/wazuh-docker/pull/2215))
- Add Wazuh version and revision into wazuh-certs-tool and config file ([#2195](https://github.com/wazuh/wazuh-docker/pull/2195))
- Improve S3 artifact URLs handling ([#2183](https://github.com/wazuh/wazuh-docker/pull/2183))
- Allow building separate targets ([#2177](https://github.com/wazuh/wazuh-docker/pull/2177))
- Add developement option when tag name is only version without stage ([#2179](https://github.com/wazuh/wazuh-docker/pull/2179))
- Add IMAGE_TAG stage reference ([#2178](https://github.com/wazuh/wazuh-docker/pull/2178))
- Delete Wazuh agent configuration files ([#2173](https://github.com/wazuh/wazuh-docker/pull/2173))
- Modify run_as parameter value - main ([#2158](https://github.com/wazuh/wazuh-docker/pull/2158))
- Change macOS and Windows deployment documentation ([#2150](https://github.com/wazuh/wazuh-docker/issues/2150))
- Modify docker build image process ([#2131](https://github.com/wazuh/wazuh-docker/issues/2131))
- Update documentation for Wazuh Docker image builder and workflow usage ([#2136](https://github.com/wazuh/wazuh-docker/issues/2136))
- Configure deployment with environment variables ([#2081](https://github.com/wazuh/wazuh-docker/pull/2081))
- Modify Wazuh components install method ([#2058](https://github.com/wazuh/wazuh-docker/pull/2058))
- Image builder Workflow Rebuild ([#2054](https://github.com/wazuh/wazuh-docker/pull/2054))
- Wazuh server clean-up ([#2030](https://github.com/wazuh/wazuh-docker/pull/2030))
- Fix OpenSearch deprecated settings ([#1899](https://github.com/wazuh/wazuh-docker/pull/1899))

### Fixed

- Fix WF docker images vulnerabilities ([#2444](https://github.com/wazuh/wazuh-docker/pull/2444))
- Adapt Wazuh manager healthcheck with local binaries ([#2422](https://github.com/wazuh/wazuh-docker/pull/2422))
- Delete setcap command on deprecated file ([#2345](https://github.com/wazuh/wazuh-docker/pull/2345))
- Modify the choice of a correct tag ([#2313](https://github.com/wazuh/wazuh-docker/pull/2313))
- Artifact URL download fix ([#2306](https://github.com/wazuh/wazuh-docker/pull/2306))
- Change API query method. ([#2275](https://github.com/wazuh/wazuh-docker/pull/2275))
- Change Wazuh manager Healthcheck. ([#2272](https://github.com/wazuh/wazuh-docker/pull/2272))
- Delete WAZUH_AGENT_GROUP variable. ([#2263](https://github.com/wazuh/wazuh-docker/pull/2263))
- Delete etc/lists references ([#2129](https://github.com/wazuh/wazuh-docker/pull/2129))

### Deleted

- None

## Prior version
- []()