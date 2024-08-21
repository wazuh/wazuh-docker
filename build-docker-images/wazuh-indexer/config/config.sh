# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
# This has to be exported to make some magic below work.
export DH_OPTIONS

export NAME=wazuh-indexer
export TARGET_DIR=${CURDIR}/debian/${NAME}

# Package build options
export USER=${NAME}
export GROUP=${NAME}
export VERSION=${WAZUH_VERSION}-${WAZUH_TAG_REVISION}
export LOG_DIR=/var/log/${NAME}
export LIB_DIR=/var/lib/${NAME}
export PID_DIR=/run/${NAME}
export INSTALLATION_DIR=/usr/share/${NAME}
export CONFIG_DIR=${INSTALLATION_DIR}
export BASE_DIR=${NAME}-*
export INDEXER_FILE=wazuh-indexer-base.tar.xz
export BASE_FILE=wazuh-indexer-base-${VERSION}-linux-x64.tar.xz
export REPO_DIR=/unattended_installer

## Variables
CERT_TOOL=wazuh-certs-tool.sh
PASSWORD_TOOL=wazuh-passwords-tool.sh
PACKAGES_URL=https://packages.wazuh.com/4.9/
PACKAGES_DEV_URL=https://packages-dev.wazuh.com/4.9/

## Check if the cert tool exists in S3 buckets
CERT_TOOL_PACKAGES=$(curl --silent -I $PACKAGES_URL$CERT_TOOL | grep -E "^HTTP" | awk  '{print $2}')
CERT_TOOL_PACKAGES_DEV=$(curl --silent -I $PACKAGES_DEV_URL$CERT_TOOL | grep -E "^HTTP" | awk  '{print $2}')

## If cert tool exists in some bucket, download it, if not exit 1
if [ "$CERT_TOOL_PACKAGES" = "200" ]; then
  curl -o $CERT_TOOL $PACKAGES_URL$CERT_TOOL
  echo "Cert tool exists in Packages bucket"
elif [ "$CERT_TOOL_PACKAGES_DEV" = "200" ]; then
  curl -o $CERT_TOOL $PACKAGES_DEV_URL$CERT_TOOL
  echo "Cert tool exists in Packages-dev bucket"
else
  echo "Cert tool does not exist in any bucket"
  exit 1
fi


## Check if the password tool exists in S3 buckets
PASSWORD_TOOL_PACKAGES=$(curl --silent -I $PACKAGES_URL$PASSWORD_TOOL | grep -E "^HTTP" | awk  '{print $2}')
PASSWORD_TOOL_PACKAGES_DEV=$(curl --silent -I $PACKAGES_DEV_URL$PASSWORD_TOOL | grep -E "^HTTP" | awk  '{print $2}')

## If password tool exists in some bucket, download it, if not exit 1
if [ "$PASSWORD_TOOL_PACKAGES" = "200" ]; then
  curl -o $PASSWORD_TOOL $PACKAGES_URL$PASSWORD_TOOL
  echo "Password tool exists in Packages bucket"
elif [ "$PASSWORD_TOOL_PACKAGES_DEV" = "200" ]; then
  curl -o $PASSWORD_TOOL $PACKAGES_DEV_URL$PASSWORD_TOOL
  echo "Password tool exists in Packages-dev bucket"
else
  echo "Password tool does not exist in any bucket"
  exit 1
fi

chmod 755 $CERT_TOOL && bash /$CERT_TOOL -A

# copy to target
mkdir -p ${TARGET_DIR}${INSTALLATION_DIR}
mkdir -p ${TARGET_DIR}${INSTALLATION_DIR}/opensearch-security/
mkdir -p ${TARGET_DIR}${CONFIG_DIR}
mkdir -p ${TARGET_DIR}${LIB_DIR}
mkdir -p ${TARGET_DIR}${LOG_DIR}
mkdir -p ${TARGET_DIR}/etc/init.d
mkdir -p ${TARGET_DIR}/etc/default
mkdir -p ${TARGET_DIR}/usr/lib/tmpfiles.d
mkdir -p ${TARGET_DIR}/usr/lib/sysctl.d
mkdir -p ${TARGET_DIR}/usr/lib/systemd/system
mkdir -p ${TARGET_DIR}${CONFIG_DIR}/certs
# Copy Wazuh's config files for the security plugin
cp -pr /roles_mapping.yml ${TARGET_DIR}${INSTALLATION_DIR}/opensearch-security/
cp -pr /roles.yml ${TARGET_DIR}${INSTALLATION_DIR}/opensearch-security/
cp -pr /action_groups.yml ${TARGET_DIR}${INSTALLATION_DIR}/opensearch-security/
cp -pr /internal_users.yml ${TARGET_DIR}${INSTALLATION_DIR}/opensearch-security/
cp -pr /opensearch.yml ${TARGET_DIR}${CONFIG_DIR}
# Copy Wazuh indexer's certificates
cp -pr /wazuh-certificates/demo.indexer.pem ${TARGET_DIR}${CONFIG_DIR}/certs/indexer.pem
cp -pr /wazuh-certificates/demo.indexer-key.pem ${TARGET_DIR}${CONFIG_DIR}/certs/indexer-key.pem
cp -pr /wazuh-certificates/root-ca.key ${TARGET_DIR}${CONFIG_DIR}/certs/root-ca.key
cp -pr /wazuh-certificates/root-ca.pem ${TARGET_DIR}${CONFIG_DIR}/certs/root-ca.pem
cp -pr /wazuh-certificates/admin.pem ${TARGET_DIR}${CONFIG_DIR}/certs/admin.pem
cp -pr /wazuh-certificates/admin-key.pem ${TARGET_DIR}${CONFIG_DIR}/certs/admin-key.pem

# Delete xms and xmx parameters in jvm.options
sed '/-Xms/d' -i /etc/wazuh-indexer/jvm.options
sed '/-Xmx/d' -i /etc/wazuh-indexer/jvm.options
sed -i 's/-Djava.security.policy=file:\/\/\/etc\/wazuh-indexer\/opensearch-performance-analyzer\/opensearch_security.policy/-Djava.security.policy=file:\/\/\/usr\/share\/wazuh-indexer\/opensearch-performance-analyzer\/opensearch_security.policy/g' /etc/wazuh-indexer/jvm.options


chmod -R 500 ${TARGET_DIR}${CONFIG_DIR}/certs
chmod -R 400 ${TARGET_DIR}${CONFIG_DIR}/certs/*

find ${TARGET_DIR} -type d -exec chmod 750 {} \;
find ${TARGET_DIR} -type f -perm 644 -exec chmod 640 {} \;
find ${TARGET_DIR} -type f -perm 664 -exec chmod 660 {} \;
find ${TARGET_DIR} -type f -perm 755 -exec chmod 750 {} \;
find ${TARGET_DIR} -type f -perm 744 -exec chmod 740 {} \;
