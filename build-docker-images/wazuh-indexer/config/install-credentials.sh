#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Installs the deployment credentials, mounted as the wazuh-credentials secret,
# as the credentials file the Wazuh packages resolve from, and removes that
# copy once they are stored. Identical in the three images.
# See docs/ref/credentials.md.
#
# Usage: install-credentials.sh install|remove

SOURCE="${WAZUH_CREDENTIALS_FILE:-/run/secrets/wazuh-credentials}"
BASE_DIR="${WAZUH_BASE_DIR:-/etc/wazuh}"
TARGET="${BASE_DIR}/credentials.env"

error() {
  echo "credentials: $*" >&2
}

install_file() {
  local tmp

  # Without the secret the keys come from the environment, or are stored.
  if [ ! -e "${SOURCE}" ]; then
    [ -z "${WAZUH_CREDENTIALS_FILE}" ] && return 0
    error "WAZUH_CREDENTIALS_FILE is ${SOURCE}, which does not exist"
    return 1
  fi
  if [ ! -f "${SOURCE}" ] || ! head -c0 "${SOURCE}" 2>/dev/null; then
    error "cannot read ${SOURCE}: it has to be a regular file that root can read"
    return 1
  fi

  if [ -L "${BASE_DIR}" ]; then
    error "${BASE_DIR} is a symbolic link"
    return 1
  fi
  if ! (umask 077; mkdir -p "${BASE_DIR}") || ! chown root:root "${BASE_DIR}" || ! chmod 700 "${BASE_DIR}"; then
    error "cannot create ${BASE_DIR}"
    return 1
  fi

  tmp=$(mktemp "${BASE_DIR}/.credentials.env.XXXXXX") || {
    error "cannot write into ${BASE_DIR}"
    return 1
  }
  if ! cat "${SOURCE}" > "${tmp}"; then
    rm -f "${tmp}"
    error "cannot read ${SOURCE}"
    return 1
  fi
  # The packages only update a file that ends with a newline.
  if [ -s "${tmp}" ] && [ -n "$(tail -c1 "${tmp}")" ]; then
    echo >> "${tmp}"
  fi
  chown root:root "${tmp}" && chmod 600 "${tmp}" && mv -f "${tmp}" "${TARGET}" || {
    rm -f "${tmp}"
    error "cannot install ${TARGET}"
    return 1
  }
}

remove_file() {
  rm -f "${TARGET}" "${BASE_DIR}/.credentials.lock"
  rmdir "${BASE_DIR}" 2>/dev/null
  return 0
}

case "$1" in
  install) install_file ;;
  remove) remove_file ;;
  *)
    echo "Usage: $0 install|remove" >&2
    exit 2
    ;;
esac
