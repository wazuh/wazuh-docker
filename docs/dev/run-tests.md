# Pull Request Test Execution

This repository includes automated tests designed to validate the correct deployment of Wazuh using Docker. These tests are executed on every pull request (PR) to ensure the integrity and stability of the system when changes are introduced.

## Purpose

The main objective of the tests is to verify that the Wazuh Docker environment can be successfully deployed and that all its core components (Wazuh Manager, Indexer, Dashboard, and Agents) operate as expected after any modification in the codebase.

## When Tests Run

- Tests are automatically triggered on every pull request (PR) opened against the repository.
- They also run when changes are pushed to an existing PR.

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
