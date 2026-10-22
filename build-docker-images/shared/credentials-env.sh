#!/bin/bash
# Wazuh Docker Copyright (C) Wazuh Inc. (License GPLv2)
#
# Exports the deployment credentials, mounted as the wazuh-credentials secret,
# into the environment the package credential resolver reads first. Sourced by
# the entrypoints of the three images, which unset the keys once the resolver
# has stored them. See docs/ref/credentials.md.
#
# Usage: . /credentials-env.sh && load_credentials

load_credentials() {
  local source="${WAZUH_CREDENTIALS_FILE:-/run/secrets/wazuh-credentials}"
  local line key value

  # Without the secret the keys come from the environment, or are stored.
  if [ ! -e "${source}" ]; then
    [ -z "${WAZUH_CREDENTIALS_FILE}" ] && return 0
    echo "credentials: WAZUH_CREDENTIALS_FILE is ${source}, which does not exist" >&2
    return 1
  fi
  if [ ! -f "${source}" ] || ! head -c0 "${source}" 2>/dev/null; then
    echo "credentials: cannot read ${source}: it has to be a regular file that root can read" >&2
    return 1
  fi

  while IFS= read -r line || [ -n "${line}" ]; do
    line="${line%$'\r'}"
    case "${line}" in
      ''|'#'*) continue ;;
      *=*) ;;
      *) echo "credentials: ${source}: ignoring a line that is not KEY=value" >&2; continue ;;
    esac
    key="${line%%=*}"
    value="${line#*=}"
    case "${key}" in
      WAZUH_*) ;;
      *) echo "credentials: ${source}: ignoring ${key}, which is not a WAZUH_ key" >&2; continue ;;
    esac
    case "${key}" in
      *[!A-Z0-9_]*) echo "credentials: ${source}: ignoring an invalid key name" >&2; continue ;;
    esac
    if [ "${#value}" -ge 2 ] && [ "${value:0:1}" = '"' ] && [ "${value: -1}" = '"' ]; then
      value="${value:1:${#value}-2}"
    fi
    # A value set in the container environment wins, as it does for the resolver.
    [ -n "${!key}" ] && continue
    export "${key}=${value}"
  done < "${source}"
}
