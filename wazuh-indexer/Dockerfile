# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)
FROM centos:7

ARG FILEBEAT_CHANNEL=filebeat-oss
ARG FILEBEAT_VERSION=7.10.2
ARG WAZUH_VERSION=4.3.0-1
ARG TEMPLATE_VERSION="master"
ARG WAZUH_FILEBEAT_MODULE="wazuh-filebeat-0.1.tar.gz"

USER root

# Set repositories.
RUN rpm --import https://packages-dev.wazuh.com/key/GPG-KEY-WAZUH

COPY config/wazuh.repo /etc/yum.repos.d/wazuh.repo

RUN yum --enablerepo=updates clean metadata && \
  yum upgrade -y && \
  yum -y install wazuh-indexer -y && \
  sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo && \
  yum clean all && rm -rf /var/cache/yum

COPY config/entrypoint.sh /

RUN chmod 700 /entrypoint.sh

# Services ports
EXPOSE 9700

ENTRYPOINT [ "/entrypoint.sh" ]