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
  mkdir -p ./config/wazuh_indexer/certs
  mkdir -p ./config/wazuh_dashboard/certs
  mkdir -p ./config/wazuh_cluster/certs

  echo "Copying certificates for Indexer"
  cp $OUTPUT_DIR/wazuh.indexer* ./config/wazuh_indexer/certs/
  cp $OUTPUT_DIR/root-ca* ./config/wazuh_indexer/certs/
  cp $OUTPUT_DIR/admin* ./config/wazuh_indexer/certs/

  echo "Copying certificates for Dashboard"
  cp $OUTPUT_DIR/wazuh.dashboard* ./config/wazuh_dashboard/certs/
  cp $OUTPUT_DIR/root-ca* ./config/wazuh_dashboard/certs/

  echo "Copying certificates for Manager"
  cp $OUTPUT_DIR/wazuh.manager* ./config/wazuh_cluster/certs/
  cp $OUTPUT_DIR/root-ca* ./config/wazuh_cluster/certs/
fi

# 3. Set ownership and permissions
if $DO_PRIV; then
  echo "Configuring permissions for Indexer (1000:1000)"
  chown -R 1000:1000 ./config/wazuh_indexer/certs
  chmod 400 ./config/wazuh_indexer/certs/*

  echo "Setting permissions for Dashboard (1000:1000)"
  chown -R 1000:1000 ./config/wazuh_dashboard/certs
  chmod 400 ./config/wazuh_dashboard/certs/*

  echo "Configuring permissions for Manager (999:999)"
  chown -R 999:999 ./config/wazuh_cluster/certs
  chmod 400 ./config/wazuh_cluster/certs/*
fi

echo "Process completed."
