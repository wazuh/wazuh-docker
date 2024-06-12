# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
# This has to be exported to make some magic below work.
export DH_OPTIONS

export NAME=wazuh-dashboard
export TARGET_DIR=${CURDIR}/debian/${NAME}
export INSTALLATION_DIR=/usr/share/${NAME}
export CONFIG_DIR=${INSTALLATION_DIR}/config

## Variables
CERT_TOOL=wazuh-certs-tool.sh
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

chmod 755 $CERT_TOOL && bash /$CERT_TOOL -A

# Create certs directory
mkdir -p ${CONFIG_DIR}/certs

# Copy Wazuh dashboard certs to install config dir
cp /wazuh-certificates/demo.dashboard.pem ${CONFIG_DIR}/certs/dashboard.pem
cp /wazuh-certificates/demo.dashboard-key.pem ${CONFIG_DIR}/certs/dashboard-key.pem
cp /wazuh-certificates/root-ca.pem ${CONFIG_DIR}/certs/root-ca.pem

chmod -R 500 ${CONFIG_DIR}/certs
chmod -R 400 ${CONFIG_DIR}/certs/*