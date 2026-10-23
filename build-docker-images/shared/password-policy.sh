#!/bin/bash
# Wazuh Docker Copyright (C) Wazuh Inc. (License GPLv2)
#
# The password rule of the Wazuh packages. common_passwordGenerate and
# common_passwordValidate are the functions of the installation assistant
# (common_functions/credentials.sh in wazuh-installation-assistant), so every
# deployment method generates and accepts the same passwords. Sourced by
# tools/utils/deployment/credentials-conf.sh and by the password tools of the
# images. See docs/ref/credentials.md.

# Prints a 32-character password with at least one uppercase letter, one lowercase
# letter, one digit and one symbol, from the character set the packages accept.
function common_passwordGenerate() {

    local password=""

    until common_passwordValidate "${password}" 2>/dev/null; do
        password=$(LC_ALL=C tr -dc 'A-Za-z0-9.,_+:@%^=~-' < /dev/urandom 2>/dev/null | head -c 32)
    done
    printf '%s\n' "${password}"

}

# Checks the password rule of the Wazuh packages: 12 to 64 characters from
# A-Z a-z 0-9 . , _ + : @ % ^ = ~ - with at least one of each class. The reason
# goes to stderr and never includes the password.
function common_passwordValidate() {

    local password="${1}"

    if [[ "${password}" =~ [^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,_+:@%^=~-] ]]; then
        echo "password must only contain characters from A-Z a-z 0-9 . , _ + : @ % ^ = ~ -" >&2
        return 1
    fi
    if [ "${#password}" -lt 12 ] || [ "${#password}" -gt 64 ]; then
        echo "password must contain between 12 and 64 characters" >&2
        return 1
    fi
    if [[ ! "${password}" =~ [abcdefghijklmnopqrstuvwxyz] ]]; then
        echo "password must contain at least one lowercase letter" >&2
        return 1
    fi
    if [[ ! "${password}" =~ [ABCDEFGHIJKLMNOPQRSTUVWXYZ] ]]; then
        echo "password must contain at least one uppercase letter" >&2
        return 1
    fi
    if [[ ! "${password}" =~ [0123456789] ]]; then
        echo "password must contain at least one digit" >&2
        return 1
    fi
    if [[ ! "${password}" =~ [.,_+:@%^=~-] ]]; then
        echo "password must contain at least one symbol from . , _ + : @ % ^ = ~ -" >&2
        return 1
    fi

}
