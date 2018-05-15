FROM docker.elastic.co/logstash/logstash-oss:6.2.4

RUN rm -f /usr/share/logstash/pipeline/logstash.conf

COPY config/01-wazuh.conf /usr/share/logstash/pipeline/01-wazuh.conf
