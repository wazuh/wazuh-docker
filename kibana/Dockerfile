# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/kibana/kibana:7.3.2
ARG ELASTIC_VERSION=7.3.2
ARG WAZUH_VERSION=3.10.2
ARG WAZUH_APP_VERSION="${WAZUH_VERSION}_${ELASTIC_VERSION}"

USER root

ADD  https://packages.wazuh.com/wazuhapp/wazuhapp-${WAZUH_APP_VERSION}.zip /tmp

RUN /usr/share/kibana/bin/kibana-plugin install --allow-root file:///tmp/wazuhapp-${WAZUH_APP_VERSION}.zip 
RUN rm -rf /tmp/wazuhapp-${WAZUH_APP_VERSION}.zip

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
