FROM docker.elastic.co/kibana/kibana:6.1.2

USER root

COPY ./config/kibana.yml /usr/share/kibana/config/kibana.yml

COPY config/wait-for-it.sh /wait-for-it.sh

RUN chmod 755 /wait-for-it.sh
