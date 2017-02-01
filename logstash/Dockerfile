FROM logstash:5.1.2

RUN apt-get update
RUN groupadd -g 1000 ossec && useradd -u 1000 -g 1000 ossec &&\
    usermod -a -G ossec logstash
COPY config/logstash.conf /etc/logstash/conf.d/logstash.conf
COPY config/wazuh-elastic5-template.json /etc/logstash/wazuh-elastic5-template.json


ADD config/run.sh /tmp/run.sh
RUN chmod 755 /tmp/run.sh

ENTRYPOINT ["/tmp/run.sh"]
