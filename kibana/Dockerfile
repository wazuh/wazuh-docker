# Wazuh App Copyright (C) 2018 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/kibana/kibana:6.2.4
ARG WAZUH_APP_VERSION=3.2.1_6.2.4
USER root

COPY ./config/kibana.yml /usr/share/kibana/config/kibana.yml

COPY config/wait-for-it.sh /wait-for-it.sh

ADD https://packages.wazuh.com/wazuhapp/wazuhapp-${WAZUH_APP_VERSION}.zip /tmp

ADD https://raw.githubusercontent.com/wazuh/wazuh/3.2/extensions/elasticsearch/wazuh-elastic6-template-alerts.json /usr/share/kibana/config

RUN /usr/share/kibana/bin/kibana-plugin install file:///tmp/wazuhapp-${WAZUH_APP_VERSION}.zip

RUN chown -R kibana.kibana /usr/share/kibana

RUN rm -rf /tmp/*

RUN chmod 755 /wait-for-it.sh

USER kibana
