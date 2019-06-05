# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/kibana/kibana:6.8.0
ARG WAZUH_APP_VERSION=3.9.1_6.8.0
USER root

ADD https://packages-dev.wazuh.com/pre-release/app/kibana/wazuhapp-3.9.1_6.8.0.zip /tmp

# This CA is created for testing. Please set your own CA pem signed certificate. 
# command: $ docker build <kibana_directory> --build-arg XPACK_SECURITY_ENABLED_CA_PEM_LOCATION=<CA_PEM_LOCATION>
# ENV variables are necessary: XPACK_SECURITY_ENABLED_CA_PEM 
ARG XPACK_SECURITY_ENABLED_CA_PEM_LOCATION="https://raw.githubusercontent.com/wazuh/wazuh-docker/k8s-ssl/certs/server.TEST-CA-signed.pem"

# CA for secure communication with Elastic
ADD $XPACK_SECURITY_ENABLED_CA_PEM_LOCATION /usr/share/kibana/config

RUN NODE_OPTIONS="--max-old-space-size=3072" /usr/share/kibana/bin/kibana-plugin install file:///tmp/wazuhapp-3.9.1_6.8.0.zip &&\
    chown -R kibana:kibana /usr/share/kibana &&\
    rm -rf /tmp/*

RUN yum install openssl -y && yum install unzip -y

COPY config/entrypoint.sh ./entrypoint.sh
RUN chmod 755 ./entrypoint.sh

USER kibana

ENV PATTERN="" \
    CHECKS_PATTERN="" \
    CHECKS_TEMPLATE="" \
    CHECKS_API="" \
    CHECKS_SETUP="" \
    EXTENSIONS_PCI="" \
    EXTENSIONS_GDPR="" \
    EXTENSIONS_AUDIT="" \
    EXTENSIONS_OSCAP="" \
    EXTENSIONS_CISCAT="" \
    EXTENSIONS_AWS="" \
    EXTENSIONS_VIRUSTOTAL="" \
    EXTENSIONS_OSQUERY="" \
    APP_TIMEOUT="" \
    WAZUH_SHARDS="" \
    WAZUH_REPLICAS="" \
    WAZUH_VERSION_SHARDS="" \
    WAZUH_VERSION_REPLICAS="" \
    IP_SELECTOR="" \
    IP_IGNORE="" \
    XPACK_RBAC_ENABLED="" \
    WAZUH_MONITORING_ENABLED="" \
    WAZUH_MONITORING_FREQUENCY="" \
    WAZUH_MONITORING_SHARDS="" \
    WAZUH_MONITORING_REPLICAS="" \
    ADMIN_PRIVILEGES=""

ARG XPACK_CANVAS="true"
ARG XPACK_LOGS="true"
ARG XPACK_INFRA="true"
ARG XPACK_ML="true"
ARG XPACK_DEVTOOLS="true"
ARG XPACK_MONITORING="true"
ARG XPACK_APM="true"
ARG XPACK_MAPS="true"
ARG XPACK_UPTIME="true"

ARG CHANGE_WELCOME="false"

COPY --chown=kibana:kibana ./config/wazuh_app_config.sh ./

RUN chmod +x ./wazuh_app_config.sh

COPY --chown=kibana:kibana ./config/kibana_settings.sh ./

RUN chmod +x ./kibana_settings.sh

COPY --chown=kibana:kibana ./config/xpack_config.sh ./

RUN chmod +x ./xpack_config.sh

RUN ./xpack_config.sh

COPY --chown=kibana:kibana ./config/welcome_wazuh.sh ./

RUN chmod +x ./welcome_wazuh.sh

RUN ./welcome_wazuh.sh

RUN /usr/local/bin/kibana-docker --optimize

ENTRYPOINT ./entrypoint.sh
