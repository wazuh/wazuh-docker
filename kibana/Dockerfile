# Wazuh App Copyright (C) 2018 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/kibana/kibana:6.5.3
ARG WAZUH_APP_VERSION=3.7.2_6.5.3
USER root

ADD https://packages.wazuh.com/wazuhapp/wazuhapp-${WAZUH_APP_VERSION}.zip /tmp

ADD https://raw.githubusercontent.com/wazuh/wazuh/3.7/extensions/elasticsearch/wazuh-elastic6-template-alerts.json /usr/share/kibana/config

RUN NODE_OPTIONS="--max-old-space-size=3072" /usr/share/kibana/bin/kibana-plugin install file:///tmp/wazuhapp-${WAZUH_APP_VERSION}.zip &&\
    chown -R kibana:kibana /usr/share/kibana &&\
    rm -rf /tmp/*

COPY config/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

USER kibana

ENTRYPOINT /entrypoint.sh
