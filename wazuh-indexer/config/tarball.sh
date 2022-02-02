export NAME=wazuh-indexer
export VERSION=4.3.0
export RELEASE=1
export USER=$NAME
export GROUP=$NAME
export CONFIG_DIR=/etc/$NAME
export LOG_DIR=/var/log/$NAME
export LIB_DIR=/var/lib/$NAME
export SYS_DIR=/usr/lib
export INSTALL_DIR=/usr/share/$NAME
export REPO_DIR=/root/unattended_installer

mkdir -p ${INSTALL_DIR}
mkdir -p /etc
mkdir -p ${LOG_DIR}
mkdir -p ${LIB_DIR}
mkdir -p ${SYS_DIR}

curl -kOL https://artifacts.opensearch.org/releases/bundle/opensearch/1.2.4/opensearch-${1}-linux-x64.tar.gz
tar zxf opensearch-${1}-linux-x64.tar.gz && rm -f opensearch-${1}.tar.gz
chown -R ${USER}:${GROUP} opensearch-${1}/*
mkdir -p /etc/wazuh-indexer && chown -R ${USER}:${GROUP} /etc/wazuh-indexer && cp opensearch-${1}/config/* /etc/wazuh-indexer/
#etc/init.d directory not found
#etc/sysconfig directory not found
#usr directory not found
cp -pr opensearch-*/LICENSE.txt ${RPM_BUILD_ROOT}${INSTALL_DIR}/
cp -pr opensearch-*/NOTICE.txt ${RPM_BUILD_ROOT}${INSTALL_DIR}/
cp -pr opensearch-*/jdk ${RPM_BUILD_ROOT}${INSTALL_DIR}/
cp -pr opensearch-*/plugins ${RPM_BUILD_ROOT}${INSTALL_DIR}/
cp -pr opensearch-*/performance-analyzer-rca ${RPM_BUILD_ROOT}${INSTALL_DIR}/
cp -pr opensearch-*/modules ${RPM_BUILD_ROOT}${INSTALL_DIR}/
cp -pr opensearch-*/lib ${RPM_BUILD_ROOT}${INSTALL_DIR}/
cp -pr opensearch-*/bin ${RPM_BUILD_ROOT}${INSTALL_DIR}/
