#!/bin/bash
# Wazuh Docker Copyright (C) Wazuh Inc. (License GPLv2)
#
# The password rule of the Wazuh packages: 12 to 64 characters from
# A-Z a-z 0-9 . , _ + : @ % ^ = ~ -, with at least one lowercase letter, one
# uppercase letter, one digit and one symbol. Generated passwords are 32
# characters long. Sourced by tools/utils/deployment/credentials-conf.sh and
# by the password tools of the images. See docs/ref/credentials.md.

WAZUH_PASSWORD_SYMBOLS='.,_+:@%^=~-'
WAZUH_PASSWORD_ALPHABET="A-Za-z0-9${WAZUH_PASSWORD_SYMBOLS}"

wazuh_password_validate() {
  local password="$1"

  case "${password}" in
    *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,_+:@%^=~-]*)
      echo "password must only contain characters from A-Z a-z 0-9 . , _ + : @ % ^ = ~ -" >&2
      return 1 ;;
  esac
  if [ "${#password}" -lt 12 ] || [ "${#password}" -gt 64 ]; then
    echo "password must contain between 12 and 64 characters" >&2
    return 1
  fi
  case "${password}" in *[abcdefghijklmnopqrstuvwxyz]*) ;; *) echo "password must contain at least one lowercase letter" >&2; return 1 ;; esac
  case "${password}" in *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]*) ;; *) echo "password must contain at least one uppercase letter" >&2; return 1 ;; esac
  case "${password}" in *[0123456789]*) ;; *) echo "password must contain at least one digit" >&2; return 1 ;; esac
  case "${password}" in *[.,_+:@%^=~-]*) ;; *) echo "password must contain at least one symbol from . , _ + : @ % ^ = ~ -" >&2; return 1 ;; esac
}

wazuh_password_generate() {
  local password
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    password=$(LC_ALL=C tr -dc "${WAZUH_PASSWORD_ALPHABET}" < /dev/urandom | head -c 32)
    if wazuh_password_validate "${password}" 2>/dev/null; then
      printf '%s\n' "${password}"
      return 0
    fi
  done
  echo "could not generate a password that meets the rule" >&2
  return 1
}
