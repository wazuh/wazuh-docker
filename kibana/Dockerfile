FROM kibana:5.2.2

RUN apt-get update && apt-get install -y curl

COPY ./config/kibana.yml /opt/kibana/config/kibana.yml

COPY config/wait-for-it.sh /
