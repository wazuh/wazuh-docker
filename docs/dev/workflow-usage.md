# Workflow usage

The `(5.x) Build and push images` workflow (`.github/workflows/5_build_and_push_images.yml`) builds and pushes multi-architecture Docker images (amd64/arm64) of Wazuh core components (Indexer, Manager, Dashboard, and Agent) to container registries.

## Input Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `image_tag` | Docker image version tag | `5.0.0` | Yes |
| `docker_reference` | Branch or tag of `wazuh-docker` to build from | - | Yes |
| `wazuh_automation_reference` | Branch or tag of `wazuh-automation` | `5.0.0` | No |
| `products` | Comma-separated list of the images to build and push | `wazuh-manager,wazuh-dashboard,wazuh-indexer,wazuh-agent` | No |
| `commit_list` | JSON array with the package revision of each product (development only) | `["latest", "latest", "latest", "latest"]` | No |
| `assistant_revision` | Revision of the installation assistant tools (development only) | `latest` | No |
| `id` | Workflow run identifier | - | No |
| `dev` | Development mode | `true` | No |

## Development vs Production Mode

**Development Mode** (`dev: true`):

- Pushes to AWS ECR (Elastic Container Registry)
- Uses pre-signed S3 URLs for packages
- Generates dynamic `artifact_urls.yaml` from S3 bucket
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
   - Leverages `docker-bake.hcl` for parallel multi-arch build configuration

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

