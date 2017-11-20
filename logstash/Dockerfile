FROM docker.elastic.co/logstash/logstash:5.6.4

COPY config/logstash.conf /etc/logstash/conf.d/logstash.conf
COPY config/wazuh-elastic5-template.json /etc/logstash/wazuh-elastic5-template.json
