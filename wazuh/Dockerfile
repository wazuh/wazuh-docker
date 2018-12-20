# Wazuh App Copyright (C) 2018 Wazuh Inc. (License GPLv2)
FROM phusion/baseimage:latest
ARG FILEBEAT_VERSION=6.5.3
ARG WAZUH_VERSION=3.7.2-1


# Updating image
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# Set Wazuh repository.
RUN echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
RUN curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -

# Set nodejs repository.
RUN curl --silent --location https://deb.nodesource.com/setup_8.x | bash -

# Creating ossec user as uid:gid 1000:1000
RUN groupadd -g 1000 ossec
RUN useradd -u 1000 -g 1000 -d /var/ossec ossec

# Configure postfix
RUN echo "postfix postfix/mailname string wazuh-manager" | debconf-set-selections
RUN echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

# Add universe repository
RUN add-apt-repository universe

# Install packages
RUN apt-get update && apt-get -y install openssl postfix bsd-mailx python-boto python-pip  \
    apt-transport-https vim expect nodejs python-cryptography wazuh-manager=${WAZUH_VERSION} \
    wazuh-api=${WAZUH_VERSION} mailutils libsasl2-modules

# Adding first run script.
ADD config/data_dirs.env /data_dirs.env
ADD config/init.bash /init.bash

# Sync calls are due to https://github.com/docker/docker/issues/9547
RUN chmod 755 /init.bash &&\
    sync && /init.bash &&\
    sync && rm /init.bash

# Installing and configuring fiebeat
RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-amd64.deb &&\
    dpkg -i filebeat-${FILEBEAT_VERSION}-amd64.deb && rm -f filebeat-${FILEBEAT_VERSION}-amd64.deb
COPY config/filebeat.yml /etc/filebeat/
RUN chmod go-w /etc/filebeat/filebeat.yml

# Adding entrypoint
ADD config/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Setting volumes
VOLUME ["/var/ossec/data"]
VOLUME ["/etc/filebeat"]
VOLUME ["/etc/postfix"]

# Services ports
EXPOSE 55000/tcp 1514/udp 1515/tcp 514/udp 1516/tcp

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Adding services
RUN mkdir /etc/service/wazuh
COPY config/wazuh.runit.service /etc/service/wazuh/run
RUN chmod +x /etc/service/wazuh/run

RUN mkdir /etc/service/wazuh-api
COPY config/wazuh-api.runit.service /etc/service/wazuh-api/run
RUN chmod +x /etc/service/wazuh-api/run

RUN mkdir /etc/service/postfix
COPY config/postfix.runit.service /etc/service/postfix/run
RUN chmod +x /etc/service/postfix/run

RUN mkdir /etc/service/filebeat
COPY config/filebeat.runit.service /etc/service/filebeat/run
RUN chmod +x /etc/service/filebeat/run


# Run all services
ENTRYPOINT ["/entrypoint.sh"]
