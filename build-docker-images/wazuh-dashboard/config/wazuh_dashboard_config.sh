#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

# Environment variables with defaults
SERVER_HOST="${SERVER_HOST:-0.0.0.0}"
SERVER_PORT="${SERVER_PORT:-443}"
OPENSEARCH_HOSTS="${OPENSEARCH_HOSTS:-https://wazuh.indexer:9200}"
OPENSEARCH_SSL_VERIFICATION_MODE="${OPENSEARCH_SSL_VERIFICATION_MODE:-certificate}"
OPENSEARCH_USERNAME="${OPENSEARCH_USERNAME:-}"
OPENSEARCH_PASSWORD="${OPENSEARCH_PASSWORD:-}"
OPENSEARCH_REQUEST_HEADERS_ALLOWLIST="${OPENSEARCH_REQUEST_HEADERS_ALLOWLIST:-[\"securitytenant\",\"Authorization\"]}"
OPENSEARCH_SECURITY_MULTITENANCY_ENABLED="${OPENSEARCH_SECURITY_MULTITENANCY_ENABLED:-false}"
OPENSEARCH_SECURITY_READONLY_MODE_ROLES="${OPENSEARCH_SECURITY_READONLY_MODE_ROLES:-[\"kibana_read_only\"]}"
SERVER_SSL_ENABLED="${SERVER_SSL_ENABLED:-true}"
SERVER_SSL_KEY="${SERVER_SSL_KEY:-/etc/wazuh-dashboard/certs/dashboard-key.pem}"
SERVER_SSL_CERTIFICATE="${SERVER_SSL_CERTIFICATE:-/etc/wazuh-dashboard/certs/dashboard.pem}"
OPENSEARCH_SSL_CERTIFICATE_AUTHORITIES="${OPENSEARCH_SSL_CERTIFICATE_AUTHORITIES:-[/etc/wazuh-dashboard/certs/root-ca.pem]}"
UI_SETTINGS_OVERRIDES_DEFAULT_ROUTE="${UI_SETTINGS_OVERRIDES_DEFAULT_ROUTE:-/app/wz-home}"
OPENSEARCH_SECURITY_COOKIE_TTL="${OPENSEARCH_SECURITY_COOKIE_TTL:-900000}"
OPENSEARCH_SECURITY_SESSION_TTL="${OPENSEARCH_SECURITY_SESSION_TTL:-900000}"
OPENSEARCH_SECURITY_SESSION_KEEPALIVE="${OPENSEARCH_SECURITY_SESSION_KEEPALIVE:-true}"

# Wazuh API configuration
WAZUH_API_URL="${WAZUH_API_URL:-https://localhost}"
API_PORT="${API_PORT:-55000}"
API_USERNAME="${API_USERNAME:-wazuh-wui}"
API_PASSWORD="${API_PASSWORD:-wazuh-wui}"
RUN_AS="${RUN_AS:-false}"

# Optional Wazuh app configurations
PATTERN="${PATTERN:-}"
CHECKS_PATTERN="${CHECKS_PATTERN:-}"
CHECKS_TEMPLATE="${CHECKS_TEMPLATE:-}"
CHECKS_API="${CHECKS_API:-}"
CHECKS_SETUP="${CHECKS_SETUP:-}"
APP_TIMEOUT="${APP_TIMEOUT:-}"
API_SELECTOR="${API_SELECTOR:-}"
IP_SELECTOR="${IP_SELECTOR:-}"
IP_IGNORE="${IP_IGNORE:-}"
WAZUH_MONITORING_ENABLED="${WAZUH_MONITORING_ENABLED:-}"
WAZUH_MONITORING_FREQUENCY="${WAZUH_MONITORING_FREQUENCY:-}"
WAZUH_MONITORING_SHARDS="${WAZUH_MONITORING_SHARDS:-}"
WAZUH_MONITORING_REPLICAS="${WAZUH_MONITORING_REPLICAS:-}"

# Configuration file path
DASHBOARD_CONFIG_FILE="${DASHBOARD_CONFIG_FILE:-/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml}"

# Map of configuration keys to their values
declare -A CONFIG_MAP=(
    [server.host]="$SERVER_HOST"
    [server.port]="$SERVER_PORT"
    [opensearch.hosts]="$OPENSEARCH_HOSTS"
    [opensearch.ssl.verificationMode]="$OPENSEARCH_SSL_VERIFICATION_MODE"
    [opensearch.username]="$OPENSEARCH_USERNAME"
    [opensearch.password]="$OPENSEARCH_PASSWORD"
    [opensearch.requestHeadersAllowlist]="$OPENSEARCH_REQUEST_HEADERS_ALLOWLIST"
    [opensearch_security.multitenancy.enabled]="$OPENSEARCH_SECURITY_MULTITENANCY_ENABLED"
    [opensearch_security.readonly_mode.roles]="$OPENSEARCH_SECURITY_READONLY_MODE_ROLES"
    [server.ssl.enabled]="$SERVER_SSL_ENABLED"
    [server.ssl.key]="\"$SERVER_SSL_KEY\""
    [server.ssl.certificate]="\"$SERVER_SSL_CERTIFICATE\""
    [opensearch.ssl.certificateAuthorities]="$OPENSEARCH_SSL_CERTIFICATE_AUTHORITIES"
    [uiSettings.overrides.defaultRoute]="$UI_SETTINGS_OVERRIDES_DEFAULT_ROUTE"
    [opensearch_security.cookie.ttl]="$OPENSEARCH_SECURITY_COOKIE_TTL"
    [opensearch_security.session.ttl]="$OPENSEARCH_SECURITY_SESSION_TTL"
    [opensearch_security.session.keepalive]="$OPENSEARCH_SECURITY_SESSION_KEEPALIVE"
    [pattern]="$PATTERN"
    [checks.pattern]="$CHECKS_PATTERN"
    [checks.template]="$CHECKS_TEMPLATE"
    [checks.api]="$CHECKS_API"
    [checks.setup]="$CHECKS_SETUP"
    [timeout]="$APP_TIMEOUT"
    [api.selector]="$API_SELECTOR"
    [ip.selector]="$IP_SELECTOR"
    [ip.ignore]="$IP_IGNORE"
    [wazuh.monitoring.enabled]="$WAZUH_MONITORING_ENABLED"
    [wazuh.monitoring.frequency]="$WAZUH_MONITORING_FREQUENCY"
    [wazuh.monitoring.shards]="$WAZUH_MONITORING_SHARDS"
    [wazuh.monitoring.replicas]="$WAZUH_MONITORING_REPLICAS"
)

# Replace configuration values in the dashboard config file
for key in "${!CONFIG_MAP[@]}"; do
    value="${CONFIG_MAP[$key]}"

    # Skip empty values for optional configurations
    if [ -z "$value" ]; then
        continue
    fi

    # Escape special characters for sed
    escaped_key=$(echo "$key" | sed 's/[.[\*^$()+?{|]/\\&/g')

    # Try to replace existing line (commented or uncommented)
    if grep -q "^[#[:space:]]*${escaped_key}:" "$DASHBOARD_CONFIG_FILE"; then
        sed -i "s|^[#[:space:]]*${escaped_key}:.*|${key}: ${value}|" "$DASHBOARD_CONFIG_FILE"
    fi
done

# Handle wazuh_core.hosts section separately
if grep -q "^wazuh_core.hosts:" "$DASHBOARD_CONFIG_FILE"; then
    # Update existing wazuh_core.hosts section
    sed -i "/^wazuh_core.hosts:/,/^[^ ]/ {
        s|url:.*|url: $WAZUH_API_URL|
        s|port:.*|port: $API_PORT|
        s|username:.*|username: $API_USERNAME|
        s|password:.*|password: $API_PASSWORD|
        s|run_as:.*|run_as: $RUN_AS|
    }" "$DASHBOARD_CONFIG_FILE"
fi
