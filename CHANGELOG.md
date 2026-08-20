## [v5.0.0]

### Added


| Issue | Comment |
| - | - |
| [#2524](https://github.com/wazuh/wazuh-docker/issues/2524) | Set authd password in agents installation. |
| [#2505](https://github.com/wazuh/wazuh-docker/pull/2505) | Added bump-issue-link support for Revert Stage Bump. |
| [#2491](https://github.com/wazuh/wazuh-docker/pull/2491) | Add integration test module docs |
| [#2188](https://github.com/wazuh/wazuh-docker/issues/2188) | Implement the wazuh-docker integration testing module |
| [#2320](https://github.com/wazuh/wazuh-docker/issues/2320) | Support Revert bump functionality in wazuh-docker |
| [#35457](https://github.com/wazuh/wazuh/issues/35457) | Docker and AMI workflows failing during stage release (v5.0.0-beta1) |
| [#2276](https://github.com/wazuh/wazuh-docker/issues/2276) | Add `--set-as-main` flag support to repository bumper — `wazuh-docker` |

### Changed


| Issue | Comment |
| - | - |
| [#2564](https://github.com/wazuh/wazuh-docker/issues/2564) | Add default AI assistant encryption key in the post installation script |
| [#2581](https://github.com/wazuh/wazuh-docker/issues/2581) | Change Codebuild runners to Github runners |
| [#2537](https://github.com/wazuh/wazuh-docker/issues/2537) | Update deployment for Wazuh Indexer 5.0.0 RBAC |
| [#2539](https://github.com/wazuh/wazuh-docker/pull/2539) | Add new WF for changelog check |
| [#2502](https://github.com/wazuh/wazuh-docker/issues/2502) | Change artifact upload and download |
| [#2471](https://github.com/wazuh/wazuh-docker/issues/2471) | Change runners on repository workflows 5.x |
| [#2446](https://github.com/wazuh/wazuh-docker/issues/2446) | PR revamp modifications 5.x |
| [#2399](https://github.com/wazuh/wazuh-docker/issues/2399) | Forbid pr_check workflow execution in draft PRs |
| [#2375](https://github.com/wazuh/wazuh-docker/issues/2375) | Unification of user UID and GID |
| [#2392](https://github.com/wazuh/wazuh-docker/issues/2392) | Wazuh indexer engine requirements |
| [#2356](https://github.com/wazuh/wazuh-docker/issues/2356) | Image build process update |
| [#2344](https://github.com/wazuh/wazuh-docker/issues/2344) | Add new path on artifact_urls file |
| [#2341](https://github.com/wazuh/wazuh-docker/issues/2341) | Unable to generate single component in `Procedure_push_docker_images` |
| [#2294](https://github.com/wazuh/wazuh-docker/issues/2294) | Adapt bumper workflows to change main branch |
| [#2288](https://github.com/wazuh/wazuh-docker/issues/2288) | Ensure default values are used for variables and passwords |
| [#2283](https://github.com/wazuh/wazuh-docker/issues/2283) | Docker - Ensure correct Wazuh manager certificates ownership |
| [#2278](https://github.com/wazuh/wazuh-docker/issues/2278) | Docker - Standarize Artifact URL keys |
| [#2266](https://github.com/wazuh/wazuh-docker/issues/2266) | Modify artifact URLs file name. |
| [#2218](https://github.com/wazuh/wazuh-docker/issues/2218) | URL presigned file -  Update the Wazuh Docker image creation workflow |
| [#2264](https://github.com/wazuh/wazuh-docker/issues/2264) | Updated wazuh-docker documentation config and tooling versions to meet new standards. |
| [#2250](https://github.com/wazuh/wazuh-docker/issues/2250) | Align cert generation steps with current cert-tool ip validation |
| [#2252](https://github.com/wazuh/wazuh-docker/issues/2252) | Modify Healthchecks |
| [#2251](https://github.com/wazuh/wazuh-docker/issues/2251) | Add deployment healthchecks |
| [#2242](https://github.com/wazuh/wazuh-docker/issues/2242) | Update artifact generation jobs to use wz-linux dedicated runner group |
| [#2237](https://github.com/wazuh/wazuh-docker/issues/2237) | Error during Wazuh manager entrypoint |
| [#2230](https://github.com/wazuh/wazuh-docker/issues/2230) | Adapt PR test for workflow_dispatch option |
| [#2227](https://github.com/wazuh/wazuh-docker/issues/2227) | Wazuh Manager/agent Separation - Breaking changes summary |
| [#2222](https://github.com/wazuh/wazuh-docker/issues/2222) | Errors in wazuh-docker PR Test |
| [#2206](https://github.com/wazuh/wazuh-docker/issues/2206) | Development - Separate Agent/Manager - Docker - Adapt image build process |
| [#2217](https://github.com/wazuh/wazuh-docker/issues/2217) | Remove revision input |
| [#2196](https://github.com/wazuh/wazuh-docker/issues/2196) | Build images script improvement |
| [#2197](https://github.com/wazuh/wazuh-docker/issues/2197) | Missing documentation in the wazuh-docker repository |
| [#2195](https://github.com/wazuh/wazuh-docker/issues/2195) | Add Wazuh version and revision into wazuh-certs-tool and config file |
| [#2172](https://github.com/wazuh/wazuh-docker/issues/2172) | Improve S3 artifact URLs handling |
| [#2164](https://github.com/wazuh/wazuh-docker/issues/2164) | Allow building separate targets |
| [#2179](https://github.com/wazuh/wazuh-docker/issues/2179) | Add developement option when tag name is only version without stage |
| [#2178](https://github.com/wazuh/wazuh-docker/issues/2178) | Add IMAGE_TAG stage reference |
| [#2171](https://github.com/wazuh/wazuh-docker/issues/2171) | Remove Wazuh agent configuration template |
| [#2156](https://github.com/wazuh/wazuh-docker/issues/2156) | Docker - Ensure `run_as` set to true for every deployment alternative |
| [#2150](https://github.com/wazuh/wazuh-docker/issues/2150) | Change macOS and Windows deployment documentation |
| [#2131](https://github.com/wazuh/wazuh-docker/issues/2131) | Modify docker build image process |
| [#2136](https://github.com/wazuh/wazuh-docker/issues/2136) | Update documentation for Wazuh Docker image builder and workflow usage |
| [#2081](https://github.com/wazuh/wazuh-docker/issues/2081) | Configure deployment with environment variables |
| [#2058](https://github.com/wazuh/wazuh-docker/issues/2058) | Modify Wazuh components install method |
| [#2054](https://github.com/wazuh/wazuh-docker/issues/2054) | Image builder Workflow Rebuild |
| [#1933](https://github.com/wazuh/wazuh-docker/issues/1933) | Remove Wazuh Manager deprecated daemons and CLI tools |
| [#1891](https://github.com/wazuh/wazuh-docker/issues/1891) | DevOps - Docker - OpenSearch 3.0 deprecated settings |

### Removed

| Issue | Comment |
| - | - |

### Fixed


| Issue | Comment |
| - | - |
| [#2584](https://github.com/wazuh/wazuh-docker/issues/2584) | Adapt certificate deployment to the unified manager certificate layout (root:wazuh-manager 0640, dir 1770) |
| [#2533](https://github.com/wazuh/wazuh-docker/pull/2533) | Fix bumper workflow failure when bump produces no changes |
| [#2477](https://github.com/wazuh/wazuh-docker/issues/2477) | Bumper script issue when the tag is set to false |
| [#2443](https://github.com/wazuh/wazuh-docker/issues/2443) | Fix reported WF vulnerabilities |
| [#2422](https://github.com/wazuh/wazuh-docker/issues/2422) | Adapt Wazuh manager healthcheck with local binaries |
| [#2337](https://github.com/wazuh/wazuh-docker/issues/2337) | The Wazuh Docker image cannot be built during the Nightly |
| [#35457](https://github.com/wazuh/wazuh/issues/35457) | Docker and AMI workflows failing during stage release (v5.0.0-beta1) |
| [#2274](https://github.com/wazuh/wazuh-docker/issues/2274) | PR check issues |
| [#2271](https://github.com/wazuh/wazuh-docker/issues/2271) | Wazuh manager Healthcheck |
| [#2258](https://github.com/wazuh/wazuh-docker/issues/2258) | Delete WAZUH_AGENT_GROUPS of Wazuh 5.0.0 images build |
| [#2128](https://github.com/wazuh/wazuh-docker/issues/2128) | Development - DevOps 5.0 adaptation - Docker - Delete lists directory references |

## Prior versions
- []()
