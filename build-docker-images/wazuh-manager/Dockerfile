# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
FROM ubuntu:jammy

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ARG WAZUH_VERSION=4.5.0
ARG WAZUH_TAG_REVISION=1
ARG TEMPLATE_VERSION=4.5
ARG FILEBEAT_CHANNEL=filebeat-oss
ARG FILEBEAT_VERSION=7.10.2
ARG ARCH=amd64
ARG WAZUH_FILEBEAT_MODULE="wazuh-filebeat-0.2.tar.gz"

RUN apt-get update && apt install curl apt-transport-https lsb-release gnupg -y

RUN curl -L -O https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-manager/wazuh-manager_${WAZUH_VERSION}-${WAZUH_TAG_REVISION}_${ARCH}.deb &&\
    dpkg -i wazuh-manager_${WAZUH_VERSION}-${WAZUH_TAG_REVISION}_${ARCH}.deb && rm -f wazuh-manager_${WAZUH_VERSION}-${WAZUH_TAG_REVISION}_${ARCH}.deb

RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/${FILEBEAT_CHANNEL}-${FILEBEAT_VERSION}-${ARCH}.deb &&\
    dpkg -i ${FILEBEAT_CHANNEL}-${FILEBEAT_VERSION}-${ARCH}.deb && rm -f ${FILEBEAT_CHANNEL}-${FILEBEAT_VERSION}-${ARCH}.deb && \
    curl -s https://packages.wazuh.com/4.x/filebeat/${WAZUH_FILEBEAT_MODULE} | tar -xvz -C /usr/share/filebeat/module

RUN curl -L https://github.com/aelsabbahy/goss/releases/latest/download/goss-linux-${ARCH} -o /usr/local/bin/goss && chmod +rx /usr/local/bin/goss

ARG S6_VERSION="v2.2.0.3"

# Conditionally set ARCH to 'aarch64' if it's 'arm64' 
RUN if [ "$ARCH" = "arm64" ]; then ARCH="aarch64"; fi && \
    curl --fail --silent -L "https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${ARCH}.tar.gz" \
    -o "/tmp/s6-overlay-${ARCH}.tar.gz" && \
    tar xzf "/tmp/s6-overlay-${ARCH}.tar.gz" -C / --exclude="./bin" && \
    tar xzf "/tmp/s6-overlay-${ARCH}.tar.gz" -C /usr ./bin && \
    rm "/tmp/s6-overlay-${ARCH}.tar.gz"

COPY config/etc/ /etc/
COPY --chown=root:wazuh config/create_user.py /var/ossec/framework/scripts/create_user.py

COPY config/filebeat.yml /etc/filebeat/

RUN chmod go-w /etc/filebeat/filebeat.yml

ADD https://raw.githubusercontent.com/wazuh/wazuh/$TEMPLATE_VERSION/extensions/elasticsearch/7.x/wazuh-template.json /etc/filebeat
RUN chmod go-w /etc/filebeat/wazuh-template.json

# Prepare permanent data
# Sync calls are due to https://github.com/docker/docker/issues/9547

COPY config/permanent_data.env config/permanent_data.sh /
RUN chmod 755 /permanent_data.sh && \
    sync && /permanent_data.sh && \
    sync && rm /permanent_data.sh

# Services ports
EXPOSE 55000/tcp 1514/tcp 1515/tcp 514/udp 1516/tcp

ENTRYPOINT [ "/init" ]