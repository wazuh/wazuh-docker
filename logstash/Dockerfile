# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/logstash/logstash:6.6.1

RUN rm -f /usr/share/logstash/pipeline/logstash.conf

COPY config/01-wazuh.conf /usr/share/logstash/pipeline/01-wazuh.conf

USER root
COPY config/run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
