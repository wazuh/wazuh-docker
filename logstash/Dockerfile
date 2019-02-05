# Wazuh App Copyright (C) 2018 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/logstash/logstash:6.6.0

RUN rm -f /usr/share/logstash/pipeline/logstash.conf

COPY config/01-wazuh.conf /usr/share/logstash/pipeline/01-wazuh.conf
