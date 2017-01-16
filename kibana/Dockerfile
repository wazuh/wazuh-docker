FROM kibana:5.1.2

RUN apt-get update && apt-get install -y curl

COPY ./config/kibana.yml /opt/kibana/config/kibana.yml

RUN /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp.zip

COPY config/wait-for-it.sh /
