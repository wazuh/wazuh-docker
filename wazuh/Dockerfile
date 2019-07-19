# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM phusion/baseimage:latest

# Arguments
ARG FILEBEAT_VERSION=6.8.1
ARG WAZUH_VERSION=3.9.3-1

# Environment variables
ENV API_USER="foo" \
    API_PASS="bar"

# Install packages
RUN set -x && \ 
    echo "deb https://packages-dev.wazuh.com/debug/apt/ unstable main" | tee /etc/apt/sources.list.d/wazuh.list && \
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - && \
    curl --silent --location https://deb.nodesource.com/setup_8.x | bash - && \
    echo "postfix postfix/mailname string wazuh-manager" | debconf-set-selections && \
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    groupadd -g 1000 ossec && \
    useradd -u 1000 -g 1000 -d /var/ossec ossec && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    apt-get --no-install-recommends --no-install-suggests -y install openssl apt-transport-https vim expect python-boto python-pip python-cryptography && \
    apt-get --no-install-recommends --no-install-suggests -y install postfix bsd-mailx mailutils libsasl2-2 ca-certificates libsasl2-modules && \
    apt-get --no-install-recommends --no-install-suggests -y install wazuh-manager=${WAZUH_VERSION} && \
    apt-get --no-install-recommends --no-install-suggests -y install nodejs wazuh-api=${WAZUH_VERSION} && \
    apt-get --no-install-recommends --no-install-suggests -y install gdb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -f /var/ossec/logs/alerts/*/*/* && \
    rm -f /var/ossec/logs/archives/*/*/* && \
    rm -f /var/ossec/logs/firewall/*/*/* && \ 
    rm -f /var/ossec/logs/api/*/*/* && \
    rm -f /var/ossec/logs/cluster/*/*/* && \
    rm -f /var/ossec/logs/ossec/*/*/* && \
    rm /var/ossec/var/run/* && \
    curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-amd64.deb && \
    dpkg -i filebeat-${FILEBEAT_VERSION}-amd64.deb && rm -f filebeat-${FILEBEAT_VERSION}-amd64.deb

# Services
RUN mkdir /etc/service/wazuh && \
    mkdir /etc/service/wazuh-api && \
    mkdir /etc/service/postfix && \
    mkdir /etc/service/filebeat

COPY config/wazuh.runit.service /etc/service/wazuh/run
COPY config/wazuh-api.runit.service /etc/service/wazuh-api/run
COPY config/postfix.runit.service /etc/service/postfix/run
COPY config/filebeat.runit.service /etc/service/filebeat/run

RUN chmod +x /etc/service/wazuh-api/run && \
    chmod +x /etc/service/wazuh/run && \
    chmod +x /etc/service/postfix/run && \
    chmod +x /etc/service/filebeat/run 

# Copy configuration files from repository
COPY config/filebeat.yml /etc/filebeat/
RUN chmod go-w /etc/filebeat/filebeat.yml 

# Prepare permanent data
# Sync calls are due to https://github.com/docker/docker/issues/9547
COPY config/permanent_data.env /permanent_data.env
COPY config/permanent_data.sh /permanent_data.sh
RUN chmod 755 /permanent_data.sh && \
    sync && \
    /permanent_data.sh && \
    sync && \
    rm /permanent_data.sh 

# Expose ports
EXPOSE 55000/tcp 1514/udp 1515/tcp 514/udp 1516/tcp

# Setting volumes
# Once we declared a volume in the Dockerfile, changes made to that path will have no effect. In other words, any changes made
# to the these paths from here to the end of the Dockerfile will not be taken into account when mounting the volume.
VOLUME ["/var/ossec/api/configuration"]
VOLUME ["/var/ossec/etc"]
VOLUME ["/var/ossec/logs"]
VOLUME ["/var/ossec/queue"]
VOLUME ["/var/ossec/var/multigroups"]
VOLUME ["/var/ossec/integrations"]
VOLUME ["/var/ossec/active-response/bin"]
VOLUME ["/etc/filebeat"]
VOLUME ["/etc/postfix"]
VOLUME ["/var/lib/filebeat"]

# Prepare entrypoint scripts
# Entrypoint scripts must be added to the entrypoint-scripts directory
RUN mkdir /entrypoint-scripts

COPY config/entrypoint.sh /entrypoint.sh
COPY config/01-wazuh.sh /entrypoint-scripts/01-wazuh.sh

RUN chmod 755 /entrypoint.sh && \
    chmod 755 /entrypoint-scripts/01-wazuh.sh

# Run all services
ENTRYPOINT ["/entrypoint.sh"]
