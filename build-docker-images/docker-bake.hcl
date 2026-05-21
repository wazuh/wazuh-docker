# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Docker Buildx Bake file.
# Builds all Wazuh component images in parallel.
#
# Usage:
#   docker buildx bake                          # build all (local, single-arch)
#   docker buildx bake wazuh-manager            # build one component
#   docker buildx bake --push                   # push to registry after build
#
# Variables are read automatically from the environment (see build-images.sh).

# ── Global variables ──────────────────────────────────────────────────────────

variable "WAZUH_VERSION"  { default = "5.0.0" }
variable "WAZUH_REGISTRY" { default = "docker.io" }

# Set IMAGE_TAG externally to override; defaults to WAZUH_VERSION.
variable "IMAGE_TAG" { default = WAZUH_VERSION }

# MULTIARCH: set to a non-empty value to build linux/amd64 + linux/arm64.
variable "MULTIARCH" { default = "" }

# Per-component tags — all default to IMAGE_TAG.
# In dev builds the shell script sets each one independently to append the
# per-component commit ref (e.g. MANAGER_TAG=5.0.0-beta1-abc1234).
variable "INDEXER_TAG"   { default = IMAGE_TAG }
variable "MANAGER_TAG"   { default = IMAGE_TAG }
variable "DASHBOARD_TAG" { default = IMAGE_TAG }
variable "AGENT_TAG"     { default = IMAGE_TAG }

# ── Artifact URL variables ────────────────────────────────────────────────────
# Populated by build-images.sh from artifacts_env.txt (sourced into env).

variable "wazuh_indexer_x86_64_rpm"    { default = "" }
variable "wazuh_indexer_aarch64_rpm"   { default = "" }
variable "wazuh_manager_x86_64_rpm"    { default = "" }
variable "wazuh_manager_aarch64_rpm"   { default = "" }
variable "wazuh_dashboard_x86_64_rpm"  { default = "" }
variable "wazuh_dashboard_aarch64_rpm" { default = "" }
variable "wazuh_agent_x86_64_rpm"      { default = "" }
variable "wazuh_agent_aarch64_rpm"     { default = "" }
variable "wazuh_certs_tool"            { default = "" }
variable "wazuh_config_yml"            { default = "" }

# ── Default group: builds all components ─────────────────────────────────────

group "default" {
  targets = ["wazuh-indexer", "wazuh-manager", "wazuh-dashboard", "wazuh-agent"]
}

# ── Shared base target ────────────────────────────────────────────────────────
# All component targets inherit from here. Not built directly.

target "_common" {
  # MULTIARCH=true  → build linux/amd64 + linux/arm64 (requires --push, no --load for multi-platform)
  # MULTIARCH unset → null means "native platform of the build host" (amd64 on x86, arm64 on ARM)
  platforms = MULTIARCH != "" ? ["linux/amd64", "linux/arm64"] : null
  args = {
    WAZUH_VERSION = WAZUH_VERSION
  }
}

# ── Component targets ─────────────────────────────────────────────────────────

target "wazuh-indexer" {
  inherits = ["_common"]
  context  = "wazuh-indexer/"
  tags     = ["${WAZUH_REGISTRY}/wazuh/wazuh-indexer:${INDEXER_TAG}"]
  args = {
    wazuh_indexer_x86_64_rpm  = wazuh_indexer_x86_64_rpm
    wazuh_indexer_aarch64_rpm = wazuh_indexer_aarch64_rpm
    wazuh_certs_tool          = wazuh_certs_tool
    wazuh_config_yml          = wazuh_config_yml
  }
}

target "wazuh-manager" {
  inherits = ["_common"]
  context  = "wazuh-manager/"
  tags     = ["${WAZUH_REGISTRY}/wazuh/wazuh-manager:${MANAGER_TAG}"]
  args = {
    wazuh_manager_x86_64_rpm  = wazuh_manager_x86_64_rpm
    wazuh_manager_aarch64_rpm = wazuh_manager_aarch64_rpm
    wazuh_certs_tool          = wazuh_certs_tool
    wazuh_config_yml          = wazuh_config_yml
  }
}

target "wazuh-dashboard" {
  inherits = ["_common"]
  context  = "wazuh-dashboard/"
  tags     = ["${WAZUH_REGISTRY}/wazuh/wazuh-dashboard:${DASHBOARD_TAG}"]
  args = {
    wazuh_dashboard_x86_64_rpm  = wazuh_dashboard_x86_64_rpm
    wazuh_dashboard_aarch64_rpm = wazuh_dashboard_aarch64_rpm
    wazuh_certs_tool            = wazuh_certs_tool
    wazuh_config_yml            = wazuh_config_yml
  }
}

target "wazuh-agent" {
  inherits = ["_common"]
  context  = "wazuh-agent/"
  tags     = ["${WAZUH_REGISTRY}/wazuh/wazuh-agent:${AGENT_TAG}"]
  args = {
    wazuh_agent_x86_64_rpm  = wazuh_agent_x86_64_rpm
    wazuh_agent_aarch64_rpm = wazuh_agent_aarch64_rpm
  }
}
