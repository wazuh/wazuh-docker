# Wazuh App Copyright (C) 2018 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/kibana/kibana:6.5.4
ARG WAZUH_APP_VERSION=3.8.2_6.5.4
USER root

ADD https://packages.wazuh.com/wazuhapp/wazuhapp-${WAZUH_APP_VERSION}.zip /tmp

ADD https://raw.githubusercontent.com/wazuh/wazuh/3.8/extensions/elasticsearch/wazuh-elastic6-template-alerts.json /usr/share/kibana/config

RUN NODE_OPTIONS="--max-old-space-size=3072" /usr/share/kibana/bin/kibana-plugin install file:///tmp/wazuhapp-${WAZUH_APP_VERSION}.zip &&\
    chown -R kibana:kibana /usr/share/kibana &&\
    rm -rf /tmp/*

COPY config/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

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


COPY --chown=kibana:kibana ./config/wazuh_app_config.sh ./

RUN chmod +x ./wazuh_app_config.sh

ENTRYPOINT /entrypoint.sh

