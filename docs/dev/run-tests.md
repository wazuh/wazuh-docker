# Pull Request Test Execution

This repository includes automated tests designed to validate the correct deployment of Wazuh using Docker. They run on a pull request when asked for with a label, to check that a change keeps the deployments working.

Check more information on the [Workflow usage](workflow-usage.md) page.

## Purpose

The main objective of the tests is to verify that the Wazuh Docker environment can be successfully deployed and that all its core components (Wazuh Manager, Indexer, Dashboard, and Agents) operate as expected after any modification in the codebase.

## When Tests Run

- Adding a label to a non-draft pull request starts them: `test/docker-single` for single-node, `test/docker-multi` for multi-node, or `test/docker` for both. To run them again, remove the label and add it again.
- They can also be run by hand (`workflow_dispatch`) from `(5.x) PR Check - Docker Integration Tests` (`.github/workflows/5_check_integration_tools.yml`). See [Docker integration tests](../ref/integration_test/docker_integration_tests.md).

## What Is Tested

The tests aim to ensure:
- Successful build and startup of all Docker containers.
- Proper communication between components (e.g., Manager ↔ Indexer, Dashboard ↔ API).
- No critical errors appear in the logs.
- Key services are healthy and accessible.

## Benefits

- Reduces the risk of breaking the deployment flow.
- Ensures system consistency during feature development and refactoring.
- Provides early feedback on integration issues before merging.

---
