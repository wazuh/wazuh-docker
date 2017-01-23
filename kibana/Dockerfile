FROM kibana:5.1.2

RUN apt-get update && apt-get install -y curl

COPY ./config/kibana.yml /opt/kibana/config/kibana.yml

RUN /usr/share/kibana/bin/kibana-plugin install http://packages.wazuh.com.s3-website-us-west-1.amazonaws.com/wazuhapp/wazuhapp-5.1.2.zip

#COPY config/wait-for-it.sh /
