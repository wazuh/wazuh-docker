# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM centos:7

ARG FILEBEAT_VERSION=7.5.1
ARG WAZUH_VERSION=3.11.1-1
ARG TEMPLATE_VERSION="v3.11.1"
ARG WAZUH_FILEBEAT_MODULE="wazuh-filebeat-0.1.tar.gz"

ENV API_USER="foo" \
   API_PASS="bar"


# Set repositories.
RUN rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH

COPY config/wazuh.repo /etc/yum.repos.d/wazuh.repo

RUN yum --enablerepo=updates clean metadata && \
  yum -y install openssl && yum -y install wazuh-manager-${WAZUH_VERSION} -y && \
  curl --silent --location https://rpm.nodesource.com/setup_8.x | bash - && \
  yum -y install nodejs && yum -y install wazuh-api-${WAZUH_VERSION} && \
  sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo && \
  yum clean all && rm -rf /var/cache/yum

RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-oss-${FILEBEAT_VERSION}-x86_64.rpm &&\
  rpm -i filebeat-oss-${FILEBEAT_VERSION}-x86_64.rpm && rm -f filebeat-oss-${FILEBEAT_VERSION}-x86_64.rpm

RUN curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/${TEMPLATE_VERSION}/extensions/elasticsearch/7.x/wazuh-template.json &&\
  chmod go+r /etc/filebeat/wazuh-template.json

RUN curl -s https://packages.wazuh.com/3.x/filebeat/${WAZUH_FILEBEAT_MODULE} | tar -xvz -C /usr/share/filebeat/module

ARG S6_VERSION="v1.22.1.0"
RUN curl --fail --silent -L https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz \
    -o /tmp/s6-overlay-amd64.tar.gz && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C / --exclude="./bin" && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C /usr ./bin && \
    rm  /tmp/s6-overlay-amd64.tar.gz

# Adding first run script and entrypoint
COPY config/data_dirs.env config/init.bash /

# Sync calls are due to https://github.com/docker/docker/issues/9547
RUN chmod 755 /init.bash && \
   sync && /init.bash && \
   sync && rm /init.bash

COPY config/filebeat.yml /etc/filebeat/

RUN chmod go-w /etc/filebeat/filebeat.yml

COPY config/etc/ /etc/

# Setting volumes
VOLUME ["/var/ossec/data"]
VOLUME ["/etc/filebeat"]
VOLUME ["/var/lib/filebeat"]

# Services ports
EXPOSE 55000/tcp 1514/udp 1515/tcp 514/udp 1516/tcp


ADD https://raw.githubusercontent.com/wazuh/wazuh/$TEMPLATE_VERSION/extensions/elasticsearch/7.x/wazuh-template.json /etc/filebeat
RUN chmod go-w /etc/filebeat/wazuh-template.json 

ENTRYPOINT [ "/init" ]
