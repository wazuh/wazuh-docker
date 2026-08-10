#!/bin/bash
# Apply ISM policies to Wazuh Indexer
# Usage: ./apply-ism-policy.sh <policy-file.json> [indexer-host] [indexer-port] [username] [password]
#
# Environment variables (can be set in .env file):
#   ISM_POLICY_DIR   - Directory containing ISM policy JSON files (default: script directory)
#   INDEXER_HOST     - Wazuh indexer hostname (default: wazuh1.indexer)
#   INDEXER_PORT     - Wazuh indexer port (default: 9200)
#   INDEXER_USERNAME - Indexer username (default: admin)
#   INDEXER_PASSWORD - Indexer password (required)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Look for .env file in script dir, then parent directories
find_env_file() {
    local dir="$SCRIPT_DIR"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/.env" ]; then
            echo "$dir/.env"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Load .env file if found
ENV_FILE=$(find_env_file)
if [ -n "$ENV_FILE" ]; then
    echo "Loading environment from: $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
fi

# Command line args override environment variables
POLICY_FILE="${1:-wazuh-alerts-lifecycle.json}"
INDEXER_HOST="${2:-${INDEXER_HOST:-wazuh1.indexer}}"
INDEXER_PORT="${3:-${INDEXER_PORT:-9200}}"
USERNAME="${4:-${INDEXER_USERNAME:-admin}}"
PASSWORD="${5:-${INDEXER_PASSWORD}}"

# Set policy directory (default to script directory)
ISM_POLICY_DIR="${ISM_POLICY_DIR:-$SCRIPT_DIR}"

# Validate policy directory exists
if [ ! -d "$ISM_POLICY_DIR" ]; then
    echo "Error: ISM policy directory '$ISM_POLICY_DIR' not found"
    exit 1
fi

# Resolve policy file path (relative to ISM_POLICY_DIR if not absolute)
if [[ "$POLICY_FILE" != /* ]]; then
    POLICY_FILE="$ISM_POLICY_DIR/$POLICY_FILE"
fi

# Validate policy file exists
if [ ! -f "$POLICY_FILE" ]; then
    echo "Error: Policy file '$POLICY_FILE' not found"
    echo ""
    echo "Available policies in $ISM_POLICY_DIR:"
    for f in "$ISM_POLICY_DIR"/*.json; do
        [ -f "$f" ] && echo "  - $(basename "$f")"
    done
    exit 1
fi

# Validate required variables
if [ -z "$PASSWORD" ]; then
    echo "Error: INDEXER_PASSWORD is required"
    echo ""
    echo "Set it via:"
    echo "  1. Environment variable: export INDEXER_PASSWORD=your_password"
    echo "  2. .env file: Add INDEXER_PASSWORD=your_password"
    echo "  3. Command line: $0 <policy-file> <host> <port> <username> <password>"
    exit 1
fi

# Extract policy_id from the JSON file
POLICY_ID=$(grep -o '"policy_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$POLICY_FILE" | cut -d'"' -f4)

if [ -z "$POLICY_ID" ]; then
    echo "Error: Could not extract policy_id from $POLICY_FILE"
    exit 1
fi

echo "Applying ISM policy: $POLICY_ID"
echo "Target: https://$INDEXER_HOST:$INDEXER_PORT"

# Create or update the ISM policy
curl -k -X PUT "https://$INDEXER_HOST:$INDEXER_PORT/_plugins/_ism/policies/$POLICY_ID" \
    -H "Content-Type: application/json" \
    -u "$USERNAME:$PASSWORD" \
    -d @"$POLICY_FILE"

echo ""
echo "---"
echo "Policy applied. To verify, run:"
echo "curl -k -u $USERNAME:<password> https://$INDEXER_HOST:$INDEXER_PORT/_plugins/_ism/policies/$POLICY_ID"
echo ""
echo "To check node attributes (hot/warm):"
echo "curl -k -u $USERNAME:<password> https://$INDEXER_HOST:$INDEXER_PORT/_cat/nodeattrs?v&h=node,attr,value"
echo ""
echo "To see policy status on indices:"
echo "curl -k -u $USERNAME:<password> https://$INDEXER_HOST:$INDEXER_PORT/_plugins/_ism/explain/wazuh-alerts-*"
