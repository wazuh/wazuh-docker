FROM phusion/baseimage:latest
ARG FILEBEAT_VERSION=6.1.0

RUN apt-get update; apt-get -y dist-upgrade
RUN apt-get -y install openssl postfix bsd-mailx curl apt-transport-https lsb-release
RUN groupadd -g 1000 ossec
RUN useradd -u 1000 -g 1000 ossec
RUN curl --silent --location https://deb.nodesource.com/setup_6.x | bash - &&\
    apt-get install -y nodejs
RUN curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
RUN echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
RUN apt-get update && apt-get -y install wazuh-manager wazuh-api expect

ADD config/data_dirs.env /data_dirs.env
ADD config/init.bash /init.bash

# Sync calls are due to https://github.com/docker/docker/issues/9547
RUN chmod 755 /init.bash &&\
  sync && /init.bash &&\
  sync && rm /init.bash

RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-amd64.deb &&\
    dpkg -i filebeat-${FILEBEAT_VERSION}-amd64.deb && rm filebeat-${FILEBEAT_VERSION}-amd64.deb

COPY config/filebeat.yml /etc/filebeat/

ADD config/run.sh /tmp/run.sh
RUN chmod 755 /tmp/run.sh

VOLUME ["/var/ossec/data"]

EXPOSE 55000/tcp 1514/udp 1515/tcp 514/udp

# Run supervisord so that the container will stay alive

ENTRYPOINT ["/tmp/run.sh"]
