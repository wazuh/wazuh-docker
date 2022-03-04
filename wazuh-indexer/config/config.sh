# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)
# This has to be exported to make some magic below work.
export DH_OPTIONS

export NAME=wazuh-indexer
export TARGET_DIR=${CURDIR}/debian/${NAME}

# Package build options
export USER=${NAME}
export GROUP=${NAME}
export CONFIG_DIR=/etc/${NAME}
export LOG_DIR=/var/log/${NAME}
export LIB_DIR=/var/lib/${NAME}
export PID_DIR=/run/${NAME}
export INSTALLATION_DIR=/usr/share/${NAME}
export BASE_DIR=${NAME}-*
export INDEXER_FILE=wazuh-indexer-base.tar.xz
export BASE_FILE=wazuh-indexer-base-4.3.0-linux-x64.tar.xz
export REPO_DIR=/unattended_installer


rm -rf ${INSTALLATION_DIR}/

curl -o ${INDEXER_FILE} https://packages-dev.wazuh.com/stack/indexer/base/${BASE_FILE}
tar -xf ${INDEXER_FILE}

# Copy to target
mkdir -p ${TARGET_DIR}${INSTALLATION_DIR}
mkdir -p ${TARGET_DIR}${CONFIG_DIR}
mkdir -p ${TARGET_DIR}${LIB_DIR}
mkdir -p ${TARGET_DIR}${LOG_DIR}
mkdir -p ${TARGET_DIR}/etc/init.d
mkdir -p ${TARGET_DIR}/etc/default
mkdir -p ${TARGET_DIR}/usr/lib/tmpfiles.d
mkdir -p ${TARGET_DIR}/usr/lib/sysctl.d
mkdir -p ${TARGET_DIR}/usr/lib/systemd/system
# Move configuration files for wazuh-indexer
mv -f ${BASE_DIR}/etc/init.d/${NAME} ${TARGET_DIR}/etc/init.d/${NAME}
mv -f ${BASE_DIR}/etc/wazuh-indexer/* ${TARGET_DIR}${CONFIG_DIR}
mv -f ${BASE_DIR}/etc/sysconfig/${NAME} ${TARGET_DIR}/etc/default/
mv -f ${BASE_DIR}/usr/lib/tmpfiles.d/* ${TARGET_DIR}/usr/lib/tmpfiles.d/
mv -f ${BASE_DIR}/usr/lib/sysctl.d/* ${TARGET_DIR}/usr/lib/sysctl.d/
mv -f ${BASE_DIR}/usr/lib/systemd/system/* ${TARGET_DIR}/usr/lib/systemd/system/
rm -rf ${BASE_DIR}/etc
rm -rf ${BASE_DIR}/usr
# Copy installation files to final location
cp -pr ${BASE_DIR}/* ${TARGET_DIR}${INSTALLATION_DIR}
# Copy the security tools
cp ${REPO_DIR}/install_functions/wazuh-cert-tool.sh ${TARGET_DIR}${INSTALLATION_DIR}/plugins/opensearch-security/tools/
cp ${REPO_DIR}/install_functions/wazuh-passwords-tool.sh ${TARGET_DIR}${INSTALLATION_DIR}/plugins/opensearch-security/tools/
# Copy Wazuh's config files for the security plugin
cp -pr ${REPO_DIR}/config/indexer/roles/roles_mapping.yml ${TARGET_DIR}${INSTALLATION_DIR}/plugins/opensearch-security/securityconfig/
cp -pr ${REPO_DIR}/config/indexer/roles/roles.yml ${TARGET_DIR}${INSTALLATION_DIR}/plugins/opensearch-security/securityconfig/
cp -pr ${REPO_DIR}/config/indexer/roles/internal_users.yml ${TARGET_DIR}${INSTALLATION_DIR}/plugins/opensearch-security/securityconfig/
# Copy Wazuh indexer certificates
cp -R ${REPO_DIR}/install_functions/certs ${TARGET_DIR}${CONFIG_DIR}
