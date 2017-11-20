FROM docker.elastic.co/kibana/kibana:5.6.4

USER root

COPY ./config/kibana.yml /usr/share/kibana/config/kibana.yml

COPY config/wait-for-it.sh /wait-for-it.sh

RUN chmod 755 /wait-for-it.sh
