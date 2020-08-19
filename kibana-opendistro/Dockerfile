# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)
FROM amazon/opendistro-for-elasticsearch-kibana:1.9.0
USER kibana
ARG ELASTIC_VERSION=7.8.0
ARG WAZUH_VERSION=3.13.1
ARG WAZUH_APP_VERSION="${WAZUH_VERSION}_${ELASTIC_VERSION}"

WORKDIR /usr/share/kibana
RUN ./bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-${WAZUH_APP_VERSION}.zip

WORKDIR /
USER root
COPY config/entrypoint.sh ./entrypoint.sh
RUN chmod 755 ./entrypoint.sh

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
    WAZUH_MONITORING_ENABLED="" \
    WAZUH_MONITORING_FREQUENCY="" \
    WAZUH_MONITORING_SHARDS="" \
    WAZUH_MONITORING_REPLICAS="" \
    ADMIN_PRIVILEGES=""

COPY --chown=kibana:kibana ./config/wazuh_app_config.sh ./
RUN chmod +x ./wazuh_app_config.sh

COPY --chown=kibana:kibana ./config/kibana_settings.sh ./
RUN chmod +x ./kibana_settings.sh

COPY ./config/custom_welcome /tmp/custom_welcome
COPY --chown=kibana:kibana ./config/welcome_wazuh.sh ./
RUN chmod +x ./welcome_wazuh.sh
ARG CHANGE_WELCOME="false"
RUN ./welcome_wazuh.sh

USER kibana
RUN NODE_OPTIONS="--max-old-space-size=2048" /usr/local/bin/kibana-docker --optimize

ENTRYPOINT ./entrypoint.sh
