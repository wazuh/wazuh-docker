# Change Log
All notable changes to this project will be documented in this file.

## [v5.0.0]

### Added

- Added bump-issue-link support for Revert Stage Bump. ([#2505](https://github.com/wazuh/wazuh-docker/pull/2505))
- Add integration test module docs ([#2491](https://github.com/wazuh/wazuh-docker/pull/2491))
- Implement the wazuh-docker integration testing module ([#2188](https://github.com/wazuh/wazuh-docker/issues/2188))
- Support Revert bump functionality in wazuh-docker ([#2320](https://github.com/wazuh/wazuh-docker/issues/2320))
- Docker and AMI workflows failing during stage release (v5.0.0-beta1) ([#35457](https://github.com/wazuh/wazuh/issues/35457))
- Add `--set-as-main` flag support to repository bumper — `wazuh-docker` ([#2276](https://github.com/wazuh/wazuh-docker/issues/2276))

### Changed

- Change artifact upload and download ([#2502](https://github.com/wazuh/wazuh-docker/issues/2502))
- Change runners on repository workflows 5.x ([#2471](https://github.com/wazuh/wazuh-docker/issues/2471))
- PR revamp modifications 5.x ([#2446](https://github.com/wazuh/wazuh-docker/issues/2446))
- Forbid pr_check workflow execution in draft PRs ([#2399](https://github.com/wazuh/wazuh-docker/issues/2399))
- Unification of user UID and GID ([#2375](https://github.com/wazuh/wazuh-docker/issues/2375))
- Wazuh indexer engine requirements ([#2392](https://github.com/wazuh/wazuh-docker/issues/2392))
- Image build process update ([#2356](https://github.com/wazuh/wazuh-docker/issues/2356))
- Add new path on artifact_urls file ([#2344](https://github.com/wazuh/wazuh-docker/issues/2344))
- Unable to generate single component in `Procedure_push_docker_images` ([#2341](https://github.com/wazuh/wazuh-docker/issues/2341))
- Adapt bumper workflows to change main branch ([#2294](https://github.com/wazuh/wazuh-docker/issues/2294))
- Ensure default values are used for variables and passwords ([#2288](https://github.com/wazuh/wazuh-docker/issues/2288))
- Docker - Ensure correct Wazuh manager certificates ownership ([#2283](https://github.com/wazuh/wazuh-docker/issues/2283))
- Docker - Standarize Artifact URL keys ([#2278](https://github.com/wazuh/wazuh-docker/issues/2278))
- Modify artifact URLs file name. ([#2266](https://github.com/wazuh/wazuh-docker/issues/2266))
- URL presigned file -  Update the Wazuh Docker image creation workflow ([#2218](https://github.com/wazuh/wazuh-docker/issues/2218))
- Updated wazuh-docker documentation config and tooling versions to meet new standards. ([#2264](https://github.com/wazuh/wazuh-docker/issues/2264))
- Align cert generation steps with current cert-tool ip validation ([#2250](https://github.com/wazuh/wazuh-docker/issues/2250))
- Modify Healthchecks ([#2252](https://github.com/wazuh/wazuh-docker/issues/2252))
- Add deployment healthchecks ([#2251](https://github.com/wazuh/wazuh-docker/issues/2251))
- Update artifact generation jobs to use wz-linux dedicated runner group ([#2242](https://github.com/wazuh/wazuh-docker/issues/2242))
- Error during Wazuh manager entrypoint ([#2237](https://github.com/wazuh/wazuh-docker/issues/2237))
- Adapt PR test for workflow_dispatch option ([#2230](https://github.com/wazuh/wazuh-docker/issues/2230))
- Wazuh Manager/agent Separation - Breaking changes summary ([#2227](https://github.com/wazuh/wazuh-docker/issues/2227))
- Errors in wazuh-docker PR Test ([#2222](https://github.com/wazuh/wazuh-docker/issues/2222))
- Development - Separate Agent/Manager - Docker - Adapt image build process ([#2206](https://github.com/wazuh/wazuh-docker/issues/2206))
- Remove revision input ([#2217](https://github.com/wazuh/wazuh-docker/issues/2217))
- Build images script improvement ([#2196](https://github.com/wazuh/wazuh-docker/issues/2196))
- Missing documentation in the wazuh-docker repository ([#2197](https://github.com/wazuh/wazuh-docker/issues/2197))
- Add Wazuh version and revision into wazuh-certs-tool and config file ([#2195](https://github.com/wazuh/wazuh-docker/issues/2195))
- Improve S3 artifact URLs handling ([#2172](https://github.com/wazuh/wazuh-docker/issues/2172))
- Allow building separate targets ([#2164](https://github.com/wazuh/wazuh-docker/issues/2164))
- Add developement option when tag name is only version without stage ([#2179](https://github.com/wazuh/wazuh-docker/issues/2179))
- Add IMAGE_TAG stage reference ([#2178](https://github.com/wazuh/wazuh-docker/issues/2178))
- Remove Wazuh agent configuration template ([#2171](https://github.com/wazuh/wazuh-docker/issues/2171))
- Docker - Ensure `run_as` set to true for every deployment alternative ([#2156](https://github.com/wazuh/wazuh-docker/issues/2156))
- Change macOS and Windows deployment documentation ([#2150](https://github.com/wazuh/wazuh-docker/issues/2150))
- Modify docker build image process ([#2131](https://github.com/wazuh/wazuh-docker/issues/2131))
- Update documentation for Wazuh Docker image builder and workflow usage ([#2136](https://github.com/wazuh/wazuh-docker/issues/2136))
- Configure deployment with environment variables ([#2081](https://github.com/wazuh/wazuh-docker/issues/2081))
- Modify Wazuh components install method ([#2058](https://github.com/wazuh/wazuh-docker/issues/2058))
- Image builder Workflow Rebuild ([#2054](https://github.com/wazuh/wazuh-docker/issues/2054))
- Remove Wazuh Manager deprecated daemons and CLI tools ([#1933](https://github.com/wazuh/wazuh-docker/issues/1933))
- DevOps - Docker - OpenSearch 3.0 deprecated settings ([#1891](https://github.com/wazuh/wazuh-docker/issues/1891))

### Removed

- None

### Fixed

- Bumper script issue when the tag is set to false ([#2477](https://github.com/wazuh/wazuh-docker/issues/2477))
- Fix reported WF vulnerabilities ([#2443](https://github.com/wazuh/wazuh-docker/issues/2443))
- Adapt Wazuh manager healthcheck with local binaries ([#2422](https://github.com/wazuh/wazuh-docker/issues/2422))
- The Wazuh Docker image cannot be built during the Nightly ([#2337](https://github.com/wazuh/wazuh-docker/issues/2337))
- Docker and AMI workflows failing during stage release (v5.0.0-beta1) ([#35457](https://github.com/wazuh/wazuh/issues/35457))
- PR check issues ([#2274](https://github.com/wazuh/wazuh-docker/issues/2274))
- Wazuh manager Healthcheck ([#2271](https://github.com/wazuh/wazuh-docker/issues/2271))
- Delete WAZUH_AGENT_GROUPS of Wazuh 5.0.0 images build ([#2258](https://github.com/wazuh/wazuh-docker/issues/2258))
- Development - DevOps 5.0 adaptation - Docker - Delete lists directory references ([#2128](https://github.com/wazuh/wazuh-docker/issues/2128))

## Prior version
- []()