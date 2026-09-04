# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
# This has to be exported to make some magic below work.
export DH_OPTIONS

export NAME=wazuh-indexer

# Package build options
export USER=${NAME}
export GROUP=${NAME}
export INSTALLATION_DIR=/usr/share/${NAME}
export CONFIG_DIR=${INSTALLATION_DIR}/config

# Modify opensearch.yml config paths
if [ -d "/etc/wazuh-indexer" ]; then
    mkdir -p ${CONFIG_DIR}
    chown ${USER}:${GROUP} ${CONFIG_DIR}
    mkdir -p ${CONFIG_DIR}/certs
    chown ${USER}:${GROUP} ${CONFIG_DIR}/certs
    mv /etc/wazuh-indexer/* ${CONFIG_DIR}/
    rmdir /etc/wazuh-indexer
fi
sed -i "s|/etc/wazuh-indexer|${CONFIG_DIR}|g" ${CONFIG_DIR}/opensearch.yml

sed -i 's/-Djava.security.policy=file:\/\/\/etc\/wazuh-indexer\/opensearch-performance-analyzer\/opensearch_security.policy/-Djava.security.policy=file:\/\/\/usr\/share\/wazuh-indexer\/opensearch-performance-analyzer\/opensearch_security.policy/g' ${CONFIG_DIR}/jvm.options


# Strip the OpenSearch demo users and every shipped password hash from the
# security plugin's user database: the accounts stay, none of them can be
# authenticated until a container sets a password of the deployment.
# See docs/ref/credentials.md.

SECURITY_DIR=${CONFIG_DIR}/opensearch-security
INTERNAL_USERS=${SECURITY_DIR}/internal_users.yml
DEMO_USERS="anomalyadmin kibanaro logstash readall snapshotrestore"
HASH_PLACEHOLDER="__WAZUH_UNSET_PASSWORD_HASH__"

if [ ! -f "${INTERNAL_USERS}" ]; then
    echo "config.sh: ${INTERNAL_USERS} not found" >&2
    exit 1
fi

awk -v demo="${DEMO_USERS}" -v placeholder="${HASH_PLACEHOLDER}" '
  BEGIN {
    n = split(demo, list, " ")
    for (i = 1; i <= n; i++) drop[list[i]] = 1
  }
  /^[A-Za-z0-9_.-]+:[[:space:]]*$/ {
    current = $0
    sub(/:.*$/, "", current)
    skipping = (current in drop)
    if (skipping) next
  }
  skipping && /^[[:space:]]/ { next }
  skipping && /^[[:space:]]*$/ { next }
  skipping { skipping = 0 }
  # Each of these comments states the password of the account below it.
  /^[[:space:]]+#[[:space:]]*The hash is the hash of the password/ { next }
  /^[[:space:]]+hash:/ {
    match($0, /^[[:space:]]+/)
    printf "%shash: \"%s\"\n", substr($0, 1, RLENGTH), placeholder
    next
  }
  { print }
' "${INTERNAL_USERS}" > "${INTERNAL_USERS}.new"

sed -i -e '/^## Demo users$/d' \
       -e '/^# WARNING: Change these default passwords immediately after installation\.$/d' \
       -e 's|^  description: "Demo admin user"$|  description: "Wazuh indexer administrator: full access to every index, to the cluster settings and to the security configuration."|' \
       -e 's|^  description: "Demo OpenSearch Dashboards user"$|  description: "Service account the Wazuh dashboard authenticates to the Wazuh indexer with."|' \
       -e 's|^# Define your internal users here$|# Define your internal users here.\n#\n# The passwords of these accounts are set on the first start of the deployment,\n# not here: the image ships no usable hash. See docs/ref/credentials.md in the\n# wazuh-docker repository for how they are set and how to change them.|' \
       "${INTERNAL_USERS}.new"

mv "${INTERNAL_USERS}.new" "${INTERNAL_USERS}"
chown ${USER}:${GROUP} "${INTERNAL_USERS}"
chmod 640 "${INTERNAL_USERS}"

# A surviving demo account or hash is a credential published inside the image.
for demo_user in ${DEMO_USERS}; do
    if grep -q "^${demo_user}:" "${INTERNAL_USERS}"; then
        echo "config.sh: ${demo_user} is still present in ${INTERNAL_USERS}" >&2
        exit 1
    fi
done
if grep -qE '^[[:space:]]+hash:[[:space:]]*"\$2' "${INTERNAL_USERS}"; then
    echo "config.sh: ${INTERNAL_USERS} still holds a password hash" >&2
    exit 1
fi
