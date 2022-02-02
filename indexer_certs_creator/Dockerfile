# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)
FROM ubuntu:20.04

ARG WAZUH_VERSION=4.3.0-1

RUN apt-get update && apt install curl -y

RUN curl https://packages-dev.wazuh.com/pre-release/apt/pool/main/w/wazuh-indexer/wazuh-indexer_${WAZUH_VERSION}_amd64.deb --output wazuh-indexer_${WAZUH_VERSION}_amd64.deb && \
    dpkg -i wazuh-indexer_${WAZUH_VERSION}_amd64.deb

WORKDIR /usr/share/wazuh-indexer/plugins/opensearch-security/tools/

RUN rm wazuh-cert-tool.sh && \
    curl -sO https://packages-dev.wazuh.com/resources/4.3/install_functions/opendistro/wazuh-cert-tool.sh &&\
    chmod 750 wazuh-cert-tool.sh

COPY config/entrypoint.sh /

RUN chmod 700 /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]