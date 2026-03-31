#!/bin/bash

# Path configuration (adjust according to your folder structure)
CERT_TOOL="./wazuh-certs-tool.sh"
CONFIG_FILE="./config.yml"
OUTPUT_DIR="./wazuh-certificates" # Folder created by the script by default

# Parse arguments
DO_CERT=false
DO_COPY=false
DO_PRIV=false

for arg in "$@"; do
  case $arg in
    --cert) DO_CERT=true ;;
    --copy) DO_COPY=true ;;
    --priv) DO_PRIV=true ;;
    *)
      echo "Unknown option: $arg"
      echo "Usage: $0 [--cert] [--copy] [--priv]"
      exit 1
      ;;
  esac
done

# If no flags provided, show usage
if ! $DO_CERT && ! $DO_COPY && ! $DO_PRIV; then
  echo "Usage: $0 [--cert] [--copy] [--priv]"
  echo "  --cert  Generate certificates using wazuh-certs-tool.sh"
  echo "  --copy  Copy certificates to the corresponding config directories"
  echo "  --priv  Set ownership and permissions on the certificate files"
  exit 1
fi

# 1. Generate certificates
if $DO_CERT; then
  echo "Generating certificates"
  bash $CERT_TOOL -A
fi

# 2. Copy certificates to config directories
if $DO_COPY; then
  echo "Setting up directories for certificates"
  mkdir -p ./config/wazuh_indexer_1/certs
  mkdir -p ./config/wazuh_indexer_2/certs
  mkdir -p ./config/wazuh_indexer_3/certs
  mkdir -p ./config/wazuh_dashboard/certs
  mkdir -p ./config/wazuh_cluster_master/certs
  mkdir -p ./config/wazuh_cluster_worker/certs

  echo "Copying certificates for Indexer 1"
  cp $OUTPUT_DIR/wazuh1.indexer* ./config/wazuh_indexer_1/certs/
  cp $OUTPUT_DIR/root-ca* ./config/wazuh_indexer_1/certs/
  cp $OUTPUT_DIR/admin* ./config/wazuh_indexer_1/certs/

  echo "Copying certificates for Indexer 2"
  cp $OUTPUT_DIR/wazuh2.indexer* ./config/wazuh_indexer_2/certs/
  cp $OUTPUT_DIR/root-ca* ./config/wazuh_indexer_2/certs/

  echo "Copying certificates for Indexer 3"
  cp $OUTPUT_DIR/wazuh3.indexer* ./config/wazuh_indexer_3/certs/
  cp $OUTPUT_DIR/root-ca* ./config/wazuh_indexer_3/certs/

  echo "Copying certificates for Dashboard"
  cp $OUTPUT_DIR/wazuh.dashboard* ./config/wazuh_dashboard/certs/
  cp $OUTPUT_DIR/root-ca* ./config/wazuh_dashboard/certs/

  echo "Copying certificates for Master Manager"
  cp $OUTPUT_DIR/wazuh.master* ./config/wazuh_cluster_master/certs/
  cp $OUTPUT_DIR/root-ca* ./config/wazuh_cluster_master/certs/

  echo "Copying certificates for Worker Manager"
  cp $OUTPUT_DIR/wazuh.worker* ./config/wazuh_cluster_worker/certs/
  cp $OUTPUT_DIR/root-ca* ./config/wazuh_cluster_worker/certs/
fi

# 3. Set ownership and permissions
if $DO_PRIV; then
  echo "Configuring permissions for Indexer 1 (1000:1000)"
  chown -R 1000:1000 ./config/wazuh_indexer_1/certs
  chmod 400 ./config/wazuh_indexer_1/certs/*

  echo "Configuring permissions for Indexer 2 (1000:1000)"
  chown -R 1000:1000 ./config/wazuh_indexer_2/certs
  chmod 400 ./config/wazuh_indexer_2/certs/*

  echo "Configuring permissions for Indexer 3 (1000:1000)"
  chown -R 1000:1000 ./config/wazuh_indexer_3/certs
  chmod 400 ./config/wazuh_indexer_3/certs/*

  echo "Setting permissions for Dashboard (1000:1000)"
  chown -R 1000:1000 ./config/wazuh_dashboard/certs
  chmod 400 ./config/wazuh_dashboard/certs/*

  echo "Configuring permissions for Master Manager (999:999)"
  chown -R 999:999 ./config/wazuh_cluster_master/certs
  chmod 400 ./config/wazuh_cluster_master/certs/*

  echo "Configuring permissions for Worker Manager (999:999)"
  chown -R 999:999 ./config/wazuh_cluster_worker/certs
  chmod 400 ./config/wazuh_cluster_worker/certs/*
fi

echo "Process completed."
