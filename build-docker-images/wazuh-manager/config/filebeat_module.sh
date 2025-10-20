## variables
WAZUH_TAG=$(curl --silent https://api.github.com/repos/wazuh/wazuh/git/refs/tags | grep '["]ref["]:' | sed -E 's/.*\"([^\"]+)\".*/\1/'  | cut -c 11- | grep ^v${WAZUH_VERSION}$)

dnf install ${REPO_ORIGIN}/yum/filebeat-${FILEBEAT_VERSION}-${FILEBEAT_REVISION}.${ARCH_NAME}.rpm -y && \
curl -s ${REPO_ORIGIN}/filebeat/${WAZUH_FILEBEAT_MODULE} | tar -xvz -C /usr/share/filebeat/module
