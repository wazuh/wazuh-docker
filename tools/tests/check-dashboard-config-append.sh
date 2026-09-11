#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Regression test for https://github.com/wazuh/wazuh-docker/issues/2629
#
# wazuh_dashboard_config.sh only replaced a CONFIG_MAP key when it already
# existed in opensearch_dashboards.yml, silently discarding OPENSEARCH_SECURITY_COOKIE_TTL
# (the only currently-supported key missing from the shipped file — the plugin no longer
# recognizes the other legacy application settings that used to live in CONFIG_MAP, so
# those were removed instead of being appended; see the issue for the schema evidence).
# This verifies the key that is genuinely supported now gets appended, without disturbing
# keys that already exist in the file.

set -euo pipefail

repo_root="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
config_script="${repo_root}/build-docker-images/wazuh-dashboard/config/wazuh_dashboard_config.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

config_file="${test_dir}/opensearch_dashboards.yml"
# No trailing newline on purpose, to exercise the append guard.
printf 'server.host: 0.0.0.0\nserver.port: 443' > "$config_file"

DASHBOARD_CONFIG_FILE="$config_file" \
SERVER_HOST="127.0.0.1" \
OPENSEARCH_SECURITY_COOKIE_TTL="123456" \
"$BASH" "$config_script"

# Existing key must still be replaced in place.
grep -Fqx "server.host: 127.0.0.1" "$config_file"

# The line preceding the append must be untouched by the newline guard.
grep -Fqx "server.port: 443" "$config_file"

# The one currently-supported absent key must now be appended, not silently dropped.
grep -Fqx "opensearch_security.cookie.ttl: 123456" "$config_file"

echo "wazuh_dashboard_config.sh appends opensearch_security.cookie.ttl when absent"
