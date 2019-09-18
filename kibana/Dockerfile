# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/kibana/kibana:7.2.1
ARG ELASTIC_VERSION=7.2.1
ARG WAZUH_VERSION=3.9.5
ARG WAZUH_APP_VERSION="${WAZUH_VERSION}_${ELASTIC_VERSION}"

USER root

ADD  https://packages.wazuh.com/wazuhapp/wazuhapp-${WAZUH_APP_VERSION}.zip /tmp

# This CA is created for testing. Please set your own CA pem signed certificate. 
# command: $ docker build <kibana_directory> --build-arg SECURITY_CA_PEM_LOCATION=<CA_PEM_LOCATION>
# ENV variables are necessary: SECURITY_CA_PEM 
# Sample:
# ARG SECURITY_CA_PEM_LOCATION="config/server.TEST-CA-signed.pem"
ARG SECURITY_CA_PEM_LOCATION=""

# CA for secure communication with Elastic
ADD $SECURITY_CA_PEM_LOCATION /usr/share/kibana/config

RUN /usr/share/kibana/bin/kibana-plugin install --allow-root file:///tmp/wazuhapp-${WAZUH_APP_VERSION}.zip 
RUN rm -rf /tmp/wazuhapp-${WAZUH_APP_VERSION}.zip

RUN yum install openssl -y

COPY config/entrypoint.sh ./entrypoint.sh
RUN chmod 755 ./entrypoint.sh
RUN mkdir /entrypoint-scripts

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

ARG XPACK_CANVAS="false"
ARG XPACK_LOGS="false"
ARG XPACK_INFRA="false"
ARG XPACK_ML="false"
ARG XPACK_DEVTOOLS="false"
ARG XPACK_MONITORING="false"
ARG XPACK_APM="false"
ARG XPACK_MAPS="false"
ARG XPACK_UPTIME="false"

ARG CHANGE_WELCOME="true"

COPY --chown=kibana:kibana ./config/10-wazuh_app_config.sh /entrypoint-scripts/10-wazuh_app_config.sh
RUN chmod +x /entrypoint-scripts/10-wazuh_app_config.sh

COPY --chown=kibana:kibana ./config/20-entrypoint.sh /entrypoint-scripts/20-entrypoint.sh
RUN chmod +x /entrypoint-scripts/20-entrypoint.sh

COPY --chown=kibana:kibana ./config/kibana_settings.sh ./

RUN chmod +x ./kibana_settings.sh

COPY --chown=kibana:kibana ./config/xpack_config.sh ./

RUN chmod +x ./xpack_config.sh

RUN ./xpack_config.sh

COPY --chown=kibana:kibana ./config/welcome_wazuh.sh ./

RUN chmod +x ./welcome_wazuh.sh

RUN ./welcome_wazuh.sh

RUN /usr/local/bin/kibana-docker --optimize

USER root

RUN chmod 777 /usr/share/kibana/plugins/wazuh/config.yml

USER kibana

ENTRYPOINT ./entrypoint.sh
