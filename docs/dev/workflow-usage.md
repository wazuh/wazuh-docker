# Workflow usage

The Procedure_push_docker_images.yml workflow builds and pushes multi-architecture Docker images (amd64/arm64) of Wazuh core components (Indexer, Manager, Dashboard, and Agent) to container registries.

## Input Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `image_tag` | Docker image version tag | `5.0.0` | Yes |
| `docker_reference` | Branch/tag to build from | - | Yes |
| `revision` | Package revision number | `1` | Yes |
| `reference` | Dev reference (for pre-release builds) | `latest` | No |
| `id` | Workflow run identifier | - | No |
| `dev` | Enable development mode (adds `-dev` suffix) | `false`/`true` | No |

## Development vs Production Mode

**Development Mode** (`dev: true`):

- Pushes to AWS ECR (Elastic Container Registry)
- Uses pre-signed S3 URLs for packages
- Generates dynamic `artifact_urls.yml` from S3 bucket
- Adds development reference to image tags
- Authenticates via AWS IAM role

**Production Mode** (`dev: false`):

- Pushes to Docker Hub
- Uses public package repositories
- Authenticates with Docker Hub credentials
- Supports version stages (rc, beta, etc.)

## Build Process

1. **Artifact Resolution**:
   - Dev mode: Creates pre-signed URLs for all Wazuh packages from S3
   - Prod mode: Uses packages from public repositories

2. **Multi-architecture Build**:
   - Uses Docker Buildx with QEMU for cross-platform builds
   - Builds for `linux/amd64` and `linux/arm64`
   - Leverages `build-images.yml` for build configuration

3. **Image Publishing**:
   - Tags images appropriately based on mode
   - Pushes to the configured registry
   - Generates .env file with build metadata

## Log Collection Feature

When tests fail, the workflows automatically collect and display relevant logs to help diagnose issues quickly.

This is implemented via two scripts, executed depending on the test setup:
Single-node: `single-node-log-check.sh`
Multi-node: `multi-node-log-check.sh`

Capabilities include:

- Collects ERROR, WARNING, and CRITICAL messages from all nodes.
- Automatically gathers logs on test failures for faster debugging.

