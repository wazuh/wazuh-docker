#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
#
# Checks that a Wazuh package downloaded during the image build is signed with
# the Wazuh key, before it is installed. dnf does not check the signature of a
# local package (localpkg_gpgcheck is off), and rpm -K passes on an unsigned
# one, so the signer key is checked first and rpm -K after it.
#
# Usage: verify-package-signature.sh <package.rpm>
# Set SKIP_PACKAGE_SIGNATURE_CHECK=true to skip it, only for unsigned
# development packages.

set -euo pipefail

package_file="${1}"

# Only a key whose fingerprint is listed here is trusted. Extending its expiry
# date keeps the fingerprint, so a renewed key still passes.
WAZUH_GPG_KEY_URL="https://packages.wazuh.com/key/GPG-KEY-WAZUH"
WAZUH_GPG_KEY_FINGERPRINTS=( "0DCFCA5547B19D2A6099506096B3EE5F29111145" )

fail() {
    echo "ERROR: ${1}" >&2
    echo "ERROR: Wazuh packages are signed. Set the SKIP_PACKAGE_SIGNATURE_CHECK build argument (build-images.sh --skip-signature-check) only for unsigned development packages." >&2
    exit 1
}

if [ "${SKIP_PACKAGE_SIGNATURE_CHECK:-}" = "true" ]; then
    echo "WARNING: Skipping the signature check of ${package_file}. Use it only with development packages." >&2
    exit 0
fi

echo "Checking the signature of ${package_file}."
verify_dir=$(mktemp -d)
trap 'rm -rf "${verify_dir}"' EXIT

curl --fail --silent --show-error --proto '=https' --retry 5 --retry-delay 5 \
    -o "${verify_dir}/wazuh.asc" "${WAZUH_GPG_KEY_URL}" || fail "Could not get the Wazuh GPG key."

# rpm --import would also take a second key appended to the file.
if [ "$(grep -c -- '-----BEGIN PGP PUBLIC KEY BLOCK-----' "${verify_dir}/wazuh.asc")" -ne 1 ]; then
    fail "The Wazuh GPG key file must hold a single key."
fi
key_info=$(GNUPGHOME="${verify_dir}" gpg --batch --show-keys --with-colons "${verify_dir}/wazuh.asc" 2>/dev/null) || \
    fail "Could not read the Wazuh GPG key."
if [ "$(grep -c '^pub:' <<< "${key_info}")" -ne 1 ]; then
    fail "The Wazuh GPG key file must hold a single key."
fi
# The first fpr record follows the pub record, the next ones belong to subkeys.
key_fingerprint=$(awk -F: '$1 == "fpr" {print $10; exit}' <<< "${key_info}")
if [ -z "${key_fingerprint}" ] || [[ " ${WAZUH_GPG_KEY_FINGERPRINTS[*]} " != *" ${key_fingerprint} "* ]]; then
    fail "The Wazuh GPG key does not have the expected fingerprint."
fi

key_id="${key_fingerprint: -16}"
rpm --import "${verify_dir}/wazuh.asc"
signature=$(rpm -qp --qf '%{RSAHEADER:pgpsig}' "${package_file}" 2>/dev/null) || true
if [[ "${signature,,}" != *"key id ${key_id,,}"* ]]; then
    fail "${package_file} is not signed with the Wazuh key."
fi
if ! rpm -K "${package_file}"; then
    fail "The signature of ${package_file} is not valid."
fi
