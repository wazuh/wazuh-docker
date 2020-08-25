# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)
FROM centos:7

ARG FILEBEAT_VERSION=7.8.0
ARG WAZUH_VERSION=4.0.0-braulio.test
ARG TEMPLATE_VERSION="develop"
ARG WAZUH_FILEBEAT_MODULE="wazuh-filebeat-0.2.tar.gz"

ENV API_USER="foo" \
   API_PASS="bar"


# Set repositories.
RUN rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH

# COPY config/wazuh.repo /etc/yum.repos.d/wazuh.repo

RUN yum --enablerepo=updates clean metadata && \
  curl --fail --silent https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/warehouse/test/4.0/rpm/var/wazuh-manager-${WAZUH_VERSION}.x86_64.rpm \
  -o wazuh-manager.rpm && \
  yum -y install openssl which && yum -y install wazuh-manager.rpm -y && \
  yum clean all && rm -rf /var/cache/yum
  # sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo && \


RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-oss-${FILEBEAT_VERSION}-x86_64.rpm &&\
  rpm -i filebeat-oss-${FILEBEAT_VERSION}-x86_64.rpm && rm -f filebeat-oss-${FILEBEAT_VERSION}-x86_64.rpm

RUN curl -s https://packages-dev.wazuh.com/utils/${WAZUH_FILEBEAT_MODULE} | tar -xvz -C /usr/share/filebeat/module

ARG S6_VERSION="v2.0.0.1"
RUN curl --fail --silent -L https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz \
    -o /tmp/s6-overlay-amd64.tar.gz && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C / --exclude="./bin" && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C /usr ./bin && \
    rm  /tmp/s6-overlay-amd64.tar.gz

COPY config/filebeat.yml /etc/filebeat/

RUN chmod go-w /etc/filebeat/filebeat.yml

ADD https://raw.githubusercontent.com/wazuh/wazuh/$TEMPLATE_VERSION/extensions/elasticsearch/7.x/wazuh-template.json /etc/filebeat
RUN chmod go-w /etc/filebeat/wazuh-template.json

COPY config/etc/ /etc/

# Prepare permanent data
# Sync calls are due to https://github.com/docker/docker/issues/9547
COPY config/permanent_data.env config/permanent_data.sh /
RUN chmod 755 /permanent_data.sh && \
    sync && /permanent_data.sh && \
    sync && rm /permanent_data.sh

# Services ports
EXPOSE 55000/tcp 1514/udp 1515/tcp 514/udp 1516/tcp

ENTRYPOINT [ "/init" ]
