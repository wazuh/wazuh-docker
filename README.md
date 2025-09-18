# Wazuh containers for Docker

[![Slack](https://img.shields.io/badge/slack-join-blue.svg)](https://wazuh.com/community/join-us-on-slack/)
[![Email](https://img.shields.io/badge/email-join-blue.svg)](https://groups.google.com/forum/#!forum/wazuh)

## Description

The `wazuh/wazuh-docker` repository provides resources to deploy the Wazuh cybersecurity platform using Docker containers. This setup enables easy installation and orchestration of the full Wazuh stack, including the Wazuh server, dashboard (based on OpenSearch Dashboards), and OpenSearch for indexing and search.

## Capabilities

- Full deployment of the Wazuh stack using Docker.
- `docker compose` support for orchestration.
- Scalable architecture with multi-node support.
- Data persistence through configurable volumes.
- Ready-to-use configurations for production or testing environments.

## Branch Convention

- `main`: Developing and testing of new features.
- `X.Y.Z`: Version-specific branches (e.g., `4.13.1`, `4.12.0`, etc.).

## Documentation

Official documentation is available at:

[https://documentation.wazuh.com/current/deployment-options/docker/index.html](https://documentation.wazuh.com/current/deployment-options/docker/index.html)

You can also explore internal documentation in the [`docs`](https://github.com/wazuh/wazuh-docker/tree/main/docs) folder of this repository.

## Get Involved

- **Fork the repository** and create your own branches to add features or fix bugs.
- **Open issues** to report bugs or request features.
- **Submit pull requests** following the contributing guidelines.
- Participate in [discussions](https://github.com/wazuh/wazuh-docker/discussions) if available.

## Authors / Maintainers

These Docker containers are based on:

*  "deviantony" dockerfiles which can be found at [https://github.com/deviantony/docker-elk](https://github.com/deviantony/docker-elk)
*  "xetus-oss" dockerfiles, which can be found at [https://github.com/xetus-oss/docker-ossec-server](https://github.com/xetus-oss/docker-ossec-server)

This project is maintained by the [Wazuh](https://wazuh.com) team, with active contributions from the community.

See the full list of contributors at:
[https://github.com/wazuh/wazuh-docker/graphs/contributors](https://github.com/wazuh/wazuh-docker/graphs/contributors)

We thank them and everyone else who has contributed to this project.

## License and copyright

Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

## Web references

[Wazuh website](http://wazuh.com)
