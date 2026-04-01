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

# ---------------------------------------------------------------------------
# Parse config.yml to extract node names per section (indexer, manager, dashboard)
# ---------------------------------------------------------------------------
parse_config() {
  local section=""
  INDEXER_NODES=()
  MANAGER_NODES=()
  DASHBOARD_NODES=()

  while IFS= read -r line; do
    # Detect section headers (e.g., "  indexer:", "  manager:", "  dashboard:")
    if echo "$line" | grep -qE '^\s+indexer:\s*$'; then
      section="indexer"
      continue
    elif echo "$line" | grep -qE '^\s+manager:\s*$'; then
      section="manager"
      continue
    elif echo "$line" | grep -qE '^\s+dashboard:\s*$'; then
      section="dashboard"
      continue
    fi

    # Extract node name from "- name: <value>" lines
    if echo "$line" | grep -qE '^\s+-\s+name:'; then
      local name
      name=$(echo "$line" | sed 's/.*name:\s*//' | tr -d ' "'\''')
      case $section in
        indexer)   INDEXER_NODES+=("$name") ;;
        manager)   MANAGER_NODES+=("$name") ;;
        dashboard) DASHBOARD_NODES+=("$name") ;;
      esac
    fi
  done < "$CONFIG_FILE"
}

# Convert node name to directory name (replace . with _)
node_to_dir() {
  echo "$1" | tr '.' '_'
}

# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------

# Parse config.yml
if $DO_COPY || $DO_PRIV; then
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found."
    exit 1
  fi
  parse_config
  echo "Detected indexer nodes:   ${INDEXER_NODES[*]}"
  echo "Detected manager nodes:   ${MANAGER_NODES[*]}"
  echo "Detected dashboard nodes: ${DASHBOARD_NODES[*]}"
fi

# 1. Generate certificates
if $DO_CERT; then
  echo "Generating certificates"
  bash $CERT_TOOL -A
fi

# 2. Copy certificates to config directories
if $DO_COPY; then
  FIRST_INDEXER=true
  for node in "${INDEXER_NODES[@]}"; do
    dir_name=$(node_to_dir "$node")
    echo "Copying certificates for indexer: $node -> config/$dir_name/certs/"
    mkdir -p "./config/$dir_name/certs"
    cp "$OUTPUT_DIR/${node}"* "./config/$dir_name/certs/"
    cp "$OUTPUT_DIR"/root-ca* "./config/$dir_name/certs/"
    if $FIRST_INDEXER; then
      cp "$OUTPUT_DIR"/admin* "./config/$dir_name/certs/"
      FIRST_INDEXER=false
    fi
  done

  for node in "${MANAGER_NODES[@]}"; do
    dir_name=$(node_to_dir "$node")
    echo "Copying certificates for manager: $node -> config/$dir_name/certs/"
    mkdir -p "./config/$dir_name/certs"
    cp "$OUTPUT_DIR/${node}"* "./config/$dir_name/certs/"
    cp "$OUTPUT_DIR"/root-ca* "./config/$dir_name/certs/"
  done

  for node in "${DASHBOARD_NODES[@]}"; do
    dir_name=$(node_to_dir "$node")
    echo "Copying certificates for dashboard: $node -> config/$dir_name/certs/"
    mkdir -p "./config/$dir_name/certs"
    cp "$OUTPUT_DIR/${node}"* "./config/$dir_name/certs/"
    cp "$OUTPUT_DIR"/root-ca* "./config/$dir_name/certs/"
  done
fi

# 3. Set ownership and permissions
if $DO_PRIV; then
  for node in "${INDEXER_NODES[@]}"; do
    dir_name=$(node_to_dir "$node")
    echo "Setting permissions for indexer $node (1000:1000)"
    chown -R 1000:1000 "./config/$dir_name/certs"
    chmod 400 "./config/$dir_name/certs/"*
  done

  for node in "${MANAGER_NODES[@]}"; do
    dir_name=$(node_to_dir "$node")
    echo "Setting permissions for manager $node (999:999)"
    chown -R 999:999 "./config/$dir_name/certs"
    chmod 400 "./config/$dir_name/certs/"*
  done

  for node in "${DASHBOARD_NODES[@]}"; do
    dir_name=$(node_to_dir "$node")
    echo "Setting permissions for dashboard $node (1000:1000)"
    chown -R 1000:1000 "./config/$dir_name/certs"
    chmod 400 "./config/$dir_name/certs/"*
  done
fi

echo "Process completed."
