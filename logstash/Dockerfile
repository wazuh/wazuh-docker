FROM logstash:5.2.0

RUN apt-get update

COPY config/logstash.conf /etc/logstash/conf.d/logstash.conf
COPY config/wazuh-elastic5-template.json /etc/logstash/wazuh-elastic5-template.json


ADD config/run.sh /tmp/run.sh
RUN chmod 755 /tmp/run.sh

ENTRYPOINT ["/tmp/run.sh"]
