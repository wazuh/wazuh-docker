#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Creates the passwords of one Wazuh deployment before its first start and
# writes them, one file per component, into the directory the Compose files
# read them from. See docs/ref/credentials.md.

set -o pipefail

CREDENTIALS_LIB="${WAZUH_CREDENTIALS_LIB:-./wazuh-credentials.sh}"
OUTPUT_DIR="./config/credentials"
FORCE=false

ALL_KEYS=(
  WAZUH_INDEXER_ADMIN_PASSWORD
  WAZUH_INDEXER_KIBANASERVER_PASSWORD
  WAZUH_INDEXER_MANAGER_PASSWORD
  WAZUH_MANAGER_API_PASSWORD
  WAZUH_MANAGER_WUI_PASSWORD
)

COMPONENTS=(indexer manager dashboard)
declare -A COMPONENT_KEYS=(
  [indexer]="WAZUH_INDEXER_ADMIN_PASSWORD WAZUH_INDEXER_KIBANASERVER_PASSWORD WAZUH_INDEXER_MANAGER_PASSWORD"
  [manager]="WAZUH_INDEXER_MANAGER_PASSWORD WAZUH_MANAGER_API_PASSWORD WAZUH_MANAGER_WUI_PASSWORD"
  [dashboard]="WAZUH_INDEXER_KIBANASERVER_PASSWORD WAZUH_MANAGER_WUI_PASSWORD"
)

error() {
  echo "credentials-conf.sh: $*" >&2
}

usage() {
  cat <<USAGE
Usage: $0 [--output <directory>] [--force]

  --output <directory>  Where to write indexer.env, manager.env and
                        dashboard.env. Default: ${OUTPUT_DIR}
  --force               Replace existing files. Only for a deployment that
                        has never been started: a started one keeps the
                        passwords it was first given.
  -h, --help            Show this help.

A key already set in the environment is validated and used instead of a
generated value, e.g.:

  WAZUH_INDEXER_ADMIN_PASSWORD='<password>' $0

Keys: ${ALL_KEYS[*]}

Needs the Wazuh credentials library as ${CREDENTIALS_LIB}
(WAZUH_CREDENTIALS_LIB overrides the path).
USAGE
}

while [ $# -gt 0 ]; do
  case $1 in
    --output)
      if [ -z "$2" ]; then
        error "--output needs a directory"
        exit 2
      fi
      OUTPUT_DIR="${2%/}"
      shift 2
      ;;
    --force) FORCE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      error "unknown option: $1"
      usage >&2
      exit 2
      ;;
  esac
done

if [ ! -r "${CREDENTIALS_LIB}" ]; then
  error "cannot read the Wazuh credentials library at ${CREDENTIALS_LIB}"
  error "download it next to wazuh-certs-tool.sh, or set WAZUH_CREDENTIALS_LIB to its path"
  exit 1
fi
# shellcheck source=/dev/null
. "${CREDENTIALS_LIB}"
for function in wazuh_password_generate wazuh_password_validate; do
  if ! declare -F "${function}" >/dev/null; then
    error "${CREDENTIALS_LIB} does not define ${function}; is it the Wazuh credentials library?"
    exit 1
  fi
done

# Every component validates what it receives; a value one of them would
# reject is refused here, so the deployment does not find out at start.
check_password() {
  local key=$1 value=$2 rest reason
  rest=$(printf '%s' "${value}" | LC_ALL=C tr -d 'A-Za-z0-9.,_+:@%^=~-')
  if [ -n "${rest}" ]; then
    error "${key} was rejected: only A-Z a-z 0-9 . , _ + : @ % ^ = ~ - are allowed"
    return 1
  fi
  if ! reason=$(wazuh_password_validate "${value}" 2>&1); then
    error "${key} was rejected: ${reason#wazuh-credentials: }"
    return 1
  fi
  if printf '%s' "${value}" | grep -Eq '^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$'; then
    error "${key} was rejected: the dashboard keystore would store it as a number"
    return 1
  fi
}

existing=()
for component in "${COMPONENTS[@]}"; do
  if [ -e "${OUTPUT_DIR}/${component}.env" ] || [ -L "${OUTPUT_DIR}/${component}.env" ]; then
    existing+=("${OUTPUT_DIR}/${component}.env")
  fi
done
if [ "${#existing[@]}" -gt 0 ] && ! ${FORCE}; then
  error "credentials already exist: ${existing[*]}"
  error "a deployment keeps the passwords it was first started with, so they are not replaced"
  error "use --force only if this deployment has never been started"
  exit 1
fi

declare -A VALUES SOURCES
failed=false
for key in "${ALL_KEYS[@]}"; do
  if [ -n "${!key}" ]; then
    check_password "${key}" "${!key}" || { failed=true; continue; }
    VALUES[${key}]="${!key}"
    SOURCES[${key}]="supplied"
  else
    if ! VALUES[${key}]=$(wazuh_password_generate); then
      error "could not generate ${key}"
      failed=true
      continue
    fi
    SOURCES[${key}]="generated"
  fi
done
if ${failed}; then
  error "nothing was written"
  exit 1
fi

umask 077
if ! mkdir -p "${OUTPUT_DIR}" 2>/dev/null || ! chmod 700 "${OUTPUT_DIR}" 2>/dev/null; then
  error "cannot create ${OUTPUT_DIR}"
  error "if certificates-conf.sh created its parent as root, run this script with sudo too;"
  error "the files are then given to the user who ran sudo"
  exit 1
fi

owner=""
if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_UID}" ]; then
  owner="${SUDO_UID}:${SUDO_GID:-${SUDO_UID}}"
fi

for component in "${COMPONENTS[@]}"; do
  target="${OUTPUT_DIR}/${component}.env"
  tmp=$(mktemp "${OUTPUT_DIR}/.${component}.env.XXXXXX") || {
    error "cannot write into ${OUTPUT_DIR}"
    exit 1
  }
  {
    echo "# Wazuh ${component} credentials, created by credentials-conf.sh on $(date -u '+%Y-%m-%dT%H:%M:%SZ')."
    echo "# Editing a value here does not change a deployment that has already started."
    for key in ${COMPONENT_KEYS[${component}]}; do
      printf '%s=%s\n' "${key}" "${VALUES[${key}]}"
    done
  } > "${tmp}"
  chmod 600 "${tmp}"
  [ -n "${owner}" ] && chown "${owner}" "${tmp}"
  mv -f "${tmp}" "${target}"
done
[ -n "${owner}" ] && chown "${owner}" "${OUTPUT_DIR}"

for key in "${ALL_KEYS[@]}"; do
  echo "${key}: ${SOURCES[${key}]}"
done
echo "Credentials written to ${OUTPUT_DIR}: indexer.env, manager.env, dashboard.env"
echo "Log in to the Wazuh dashboard as 'admin'. Read its password with:"
echo "  grep '^WAZUH_INDEXER_ADMIN_PASSWORD=' ${OUTPUT_DIR}/indexer.env | cut -d= -f2-"
