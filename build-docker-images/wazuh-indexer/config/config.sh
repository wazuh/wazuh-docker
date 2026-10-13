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


# Remove the OpenSearch demo users from the security plugin's user database.
# They are not Wazuh accounts, nothing in a Wazuh deployment authenticates as
# one of them, and readall and snapshotrestore are among the most privileged
# accounts in the file. See docs/ref/credentials.md.

INTERNAL_USERS=${CONFIG_DIR}/opensearch-security/internal_users.yml
DEMO_USERS="anomalyadmin kibanaro logstash readall snapshotrestore"

if [ ! -f "${INTERNAL_USERS}" ]; then
    echo "config.sh: ${INTERNAL_USERS} not found" >&2
    exit 1
fi

awk -v demo="${DEMO_USERS}" '
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
  { print }
' "${INTERNAL_USERS}" > "${INTERNAL_USERS}.new"

sed -i -e '/^## Demo users$/d' \
       -e 's|^  description: "Demo admin user"$|  description: "Wazuh indexer administrator: full access to every index, to the cluster settings and to the security configuration."|' \
       -e 's|^  description: "Demo OpenSearch Dashboards user"$|  description: "Service account the Wazuh dashboard authenticates to the Wazuh indexer with."|' \
       "${INTERNAL_USERS}.new"

mv "${INTERNAL_USERS}.new" "${INTERNAL_USERS}"
chown ${USER}:${GROUP} "${INTERNAL_USERS}"
chmod 640 "${INTERNAL_USERS}"

for demo_user in ${DEMO_USERS}; do
    if grep -q "^${demo_user}:" "${INTERNAL_USERS}"; then
        echo "config.sh: ${demo_user} is still present in ${INTERNAL_USERS}" >&2
        exit 1
    fi
done
