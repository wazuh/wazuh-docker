#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

set -euo pipefail

if ((BASH_VERSINFO[0] < 4)); then
    echo "check-dashboard-config-literals: Bash 4 or newer is required" >&2
    exit 2
fi

repo_root="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
config_script="${repo_root}/build-docker-images/wazuh-dashboard/config/wazuh_dashboard_config.sh"
entrypoint="${repo_root}/build-docker-images/wazuh-dashboard/config/entrypoint.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

config_file="${test_dir}/opensearch_dashboards.yml"
cat > "$config_file" <<'EOF'
opensearch.password: old-indexer-password
wazuh_core.hosts:
  - default:
      url: https://localhost
      port: 55000
      username: wazuh-wui
      password: "old-api-password"
      run_as: true
next.section: unchanged
EOF

literal='abc&def|ghi\jkl'
apostrophe="one'two&three|four\\five"

DASHBOARD_CONFIG_FILE="$config_file" \
OPENSEARCH_PASSWORD="$literal" \
API_PASSWORD="$apostrophe" \
"$BASH" "$config_script"

grep -Fqx "opensearch.password: $literal" "$config_file"
grep -Fqx "      password: 'one''two&three|four\five'" "$config_file"
grep -Fqx 'next.section: unchanged' "$config_file"

# The keystore input must be one literal shell word. Unquoted echo would fold
# repeated whitespace and tabs before the keystore receives the credential.
grep -Fq 'printf '\''%s\n'\'' "$DASHBOARD_USERNAME"' "$entrypoint"
grep -Fq 'printf '\''%s\n'\'' "$DASHBOARD_PASSWORD"' "$entrypoint"

echo "dashboard configuration values are preserved literally"
