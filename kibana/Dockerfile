# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/kibana/kibana:7.10.2
USER kibana
ARG ELASTIC_VERSION=7.10.2
ARG WAZUH_VERSION=4.1.2
ARG WAZUH_APP_VERSION="${WAZUH_VERSION}_${ELASTIC_VERSION}"

WORKDIR /usr/share/kibana
RUN ./bin/kibana-plugin install https://packages.wazuh.com/4.x/ui/kibana/wazuh_kibana-${WAZUH_APP_VERSION}-1.zip

ENV PATTERN="" \
    CHECKS_PATTERN="" \
    CHECKS_TEMPLATE="" \
    CHECKS_API="" \
    CHECKS_SETUP="" \
    EXTENSIONS_PCI="" \
    EXTENSIONS_GDPR="" \
    EXTENSIONS_HIPAA="" \
    EXTENSIONS_NIST="" \
    EXTENSIONS_TSC="" \
    EXTENSIONS_AUDIT="" \
    EXTENSIONS_OSCAP="" \
    EXTENSIONS_CISCAT="" \
    EXTENSIONS_AWS="" \
    EXTENSIONS_GCP="" \
    EXTENSIONS_VIRUSTOTAL="" \
    EXTENSIONS_OSQUERY="" \
    EXTENSIONS_DOCKER="" \
    APP_TIMEOUT="" \
    API_SELECTOR="" \
    IP_SELECTOR="" \
    IP_IGNORE="" \
    WAZUH_MONITORING_ENABLED="" \
    WAZUH_MONITORING_FREQUENCY="" \
    WAZUH_MONITORING_SHARDS="" \
    WAZUH_MONITORING_REPLICAS="" \
    ADMIN_PRIVILEGES="" \
    XPACK_CANVAS="true" \
    XPACK_LOGS="true"   \
    XPACK_INFRA="true"  \
    XPACK_ML="true" \
    XPACK_DEVTOOLS="true"   \
    XPACK_MONITORING="true" \
    XPACK_APM="true"

WORKDIR /
USER kibana

COPY --chown=kibana:kibana config/entrypoint.sh ./entrypoint.sh
RUN chmod 755 ./entrypoint.sh

RUN printf "\nserver.defaultRoute: /app/wazuh\n" >> /usr/share/kibana/config/kibana.yml

COPY --chown=kibana:kibana ./config/wazuh.yml /usr/share/kibana/data/wazuh/config/wazuh.yml
COPY --chown=kibana:kibana ./config/wazuh_app_config.sh ./
RUN chmod +x ./wazuh_app_config.sh

COPY --chown=kibana:kibana ./config/kibana_settings.sh ./
RUN chmod +x ./kibana_settings.sh

COPY --chown=kibana:kibana ./config/xpack_config.sh ./
RUN chmod +x ./xpack_config.sh

ENTRYPOINT ./entrypoint.sh
