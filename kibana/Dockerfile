FROM kibana:5.0.2

RUN apt-get update && apt-get install -y curl

COPY ./config/kibana.yml /opt/kibana/config/kibana.yml

RUN /usr/share/kibana/bin/kibana-plugin install http://wazuh.com/resources/wazuh-app.zip

COPY config/wait-for-it.sh /
