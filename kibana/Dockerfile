FROM kibana:5.0.2

COPY ./config/kibana.yml /opt/kibana/config/kibana.yml

RUN /usr/share/kibana/bin/kibana-plugin install http://wazuh.com/resources/wazuh-app.zip
