#!/bin/bash
# Wazuh Docker Copyright (C) Wazuh Inc. (License GPLv2)

# Writes the settings that come from the environment into opensearch_dashboards.yml.
#
#   wazuh_dashboard_config.sh --defaults   at build time: writes every setting
#                                          below with its default, so the file
#                                          the image ships works in a container.
#   wazuh_dashboard_config.sh              at every start: writes only the
#                                          settings whose variable is set; a
#                                          mounted file keeps everything else.
#
# opensearch.ssl.verificationMode is the exception: it is written at every start,
# with its default when the variable is not set, so a configuration kept from an
# earlier version moves to full verification (see docs/ref/upgrade.md).

DASHBOARD_CONFIG_FILE="${DASHBOARD_CONFIG_FILE:-/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml}"
CERTS_DIR=/usr/share/wazuh-dashboard/config/certs

MODE=start
[ "$1" = "--defaults" ] && MODE=defaults

# setting|variable|default|quote
SETTINGS=(
    "server.host|SERVER_HOST|0.0.0.0|"
    "server.port|SERVER_PORT|443|"
    "opensearch.hosts|OPENSEARCH_HOSTS|https://wazuh.indexer:9200|"
    "opensearch.ssl.verificationMode|OPENSEARCH_SSL_VERIFICATION_MODE|full|"
    "opensearch.requestHeadersAllowlist|OPENSEARCH_REQUEST_HEADERS_ALLOWLIST|[\"securitytenant\",\"Authorization\"]|"
    "opensearch_security.multitenancy.enabled|OPENSEARCH_SECURITY_MULTITENANCY_ENABLED|false|"
    "opensearch_security.readonly_mode.roles|OPENSEARCH_SECURITY_READONLY_MODE_ROLES|[\"kibana_read_only\"]|"
    "server.ssl.enabled|SERVER_SSL_ENABLED|true|"
    "server.ssl.key|SERVER_SSL_KEY|${CERTS_DIR}/dashboard-key.pem|\""
    "server.ssl.certificate|SERVER_SSL_CERTIFICATE|${CERTS_DIR}/dashboard.pem|\""
    "opensearch.ssl.certificateAuthorities|OPENSEARCH_SSL_CERTIFICATE_AUTHORITIES|[${CERTS_DIR}/indexer-ca.pem]|"
    "uiSettings.overrides.defaultRoute|UI_SETTINGS_OVERRIDES_DEFAULT_ROUTE|/app/wz-home|"
    "opensearch_security.cookie.ttl|OPENSEARCH_SECURITY_COOKIE_TTL|900000|"
    "opensearch_security.session.ttl|OPENSEARCH_SECURITY_SESSION_TTL|900000|"
    "opensearch_security.session.keepalive|OPENSEARCH_SECURITY_SESSION_KEEPALIVE|true|"
)
ALWAYS_WRITTEN="opensearch.ssl.verificationMode"

# wazuh_core.hosts.default: field|variable|default|quote
API_HOST_SETTINGS=(
    "url|WAZUH_API_URL|https://localhost|"
    "port|API_PORT|55000|"
    "username|API_USERNAME|wazuh-internal-client|"
    "run_as|RUN_AS|true|"
    "ca|WAZUH_API_CA|${CERTS_DIR}/manager-ca.pem|'"
)

# Prints the value to write for one entry, or nothing when it must be left alone.
value_for() {
    local key="$1" var="$2" default="$3" quote="$4" value
    if [ "$MODE" = "defaults" ]; then
        value="$default"
    elif [ "$key" = "$ALWAYS_WRITTEN" ]; then
        value="${!var:-$default}"
    else
        value="${!var:-}"
    fi
    [ -n "$value" ] && printf '%s%s%s' "$quote" "$value" "$quote"
}

# Escapes &, \ and | (the sed replacement delimiter used below) so a value
# containing any of them is inserted literally.
escape_repl() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }

# Runs a filter over the configuration file and writes the result over the same
# file. sed -i would rename a new file over it, which fails when the file is a
# single-file bind mount ("Device or resource busy") and would also drop its
# owner and mode; writing through the existing file keeps all three.
filter_config() {
    local tmp
    tmp=$(mktemp) || { echo "ERROR: cannot create a temporary file to update ${DASHBOARD_CONFIG_FILE}" >&2; exit 1; }
    if ! "$@" "$DASHBOARD_CONFIG_FILE" > "$tmp" || ! cat "$tmp" > "$DASHBOARD_CONFIG_FILE"; then
        rm -f "$tmp"
        echo "ERROR: cannot update ${DASHBOARD_CONFIG_FILE}" >&2
        exit 1
    fi
    rm -f "$tmp"
}

for entry in "${SETTINGS[@]}"; do
    IFS='|' read -r key var default quote <<< "$entry"
    value=$(value_for "$key" "$var" "$default" "$quote") || continue

    escaped_key=$(printf '%s' "$key" | sed 's/[.[\*^$()+?{|]/\\&/g')

    # Replace the line (commented or not), or append the setting if it is missing.
    if grep -q "^[#[:space:]]*${escaped_key}:" "$DASHBOARD_CONFIG_FILE"; then
        filter_config sed "s|^[#[:space:]]*${escaped_key}:.*|${key}: $(escape_repl "$value")|"
    else
        if [ -s "$DASHBOARD_CONFIG_FILE" ] && [ "$(tail -c1 "$DASHBOARD_CONFIG_FILE")" != "" ]; then
            echo >> "$DASHBOARD_CONFIG_FILE"
        fi
        echo "${key}: ${value}" >> "$DASHBOARD_CONFIG_FILE"
    fi
done

# Only the fields of the "default" entry of wazuh_core.hosts are written: other
# entries and the settings that follow the block are left as they are.
api_env=()
for entry in "${API_HOST_SETTINGS[@]}"; do
    IFS='|' read -r field var default quote <<< "$entry"
    value=$(value_for "$field" "$var" "$default" "$quote") && api_env+=("WZ_API_${field}=${value}")
done

if [ ${#api_env[@]} -gt 0 ] && grep -q "^wazuh_core\.hosts:" "$DASHBOARD_CONFIG_FILE"; then
    filter_config env "${api_env[@]}" awk '
        /^wazuh_core\.hosts:/ { in_block = 1; entry = ""; entry_indent = -1; print; next }
        in_block && /^[^[:space:]#]/ { in_block = 0 }
        in_block && /^[[:space:]]+[^[:space:]#]/ {
            indent = match($0, /[^ ]/) - 1
            if (entry_indent < 0) entry_indent = indent
            if (indent == entry_indent) {
                entry = $1; sub(/:.*/, "", entry)
            } else if (entry == "default" && match($0, /^[[:space:]]+(url|port|username|run_as|ca):/)) {
                field = substr($0, indent + 1, RLENGTH - indent - 1)
                if (("WZ_API_" field) in ENVIRON) {
                    printf "%" indent "s%s: %s\n", "", field, ENVIRON["WZ_API_" field]
                    next
                }
            }
        }
        { print }
    '
fi

# The dashboard runs as wazuh-dashboard and reads these files through its group.
# The credentials resolver only checks that they are root's and not writable by
# others, so a file only root can read would get as far as Node and fail there.
SERVICE_USER="${SERVICE_USER:-wazuh-dashboard}"
SERVICE_GID="$(id -g "$SERVICE_USER")"
unreadable=0
check_readable() {
    local file
    for file in "$@"; do
        [ -e "$file" ] || continue
        if ! setpriv --reuid="$SERVICE_USER" --regid="$SERVICE_USER" --init-groups test -r "$file"; then
            echo "UNSAFE ${file}: group ${SERVICE_USER} (${SERVICE_GID}) cannot read it; run chown 0:${SERVICE_GID} and chmod 640 on the file on the Docker host" >&2
            unreadable=1
        fi
    done
}

read -r -a ca_files <<< "$(printf '%s' "$OPENSEARCH_SSL_CERTIFICATE_AUTHORITIES" | tr '[],"'"'" '     ')"
check_readable "$DASHBOARD_CONFIG_FILE" "${ca_files[@]}" "$WAZUH_API_CA"
if [ "$SERVER_SSL_ENABLED" = "true" ]; then
    check_readable "$SERVER_SSL_CERTIFICATE" "$SERVER_SSL_KEY"
fi
[ "$unreadable" = 0 ] || exit 1
