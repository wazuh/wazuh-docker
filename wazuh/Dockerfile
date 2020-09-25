# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM phusion/baseimage:0.10.2

# Arguments
ARG FILEBEAT_VERSION=7.7.0
ARG WAZUH_VERSION=3.13.2-1

# Environment variables
ENV API_USER="foo" \
   API_PASS="bar"

ARG TEMPLATE_VERSION="v3.13.2"
ENV FILEBEAT_DESTINATION="elasticsearch"

# Install packages
RUN set -x && \
    echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list && \
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
COPY config/filebeat_to_elasticsearch.yml ./
COPY config/filebeat_to_logstash.yml ./

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
VOLUME ["/var/ossec/wodles"]
VOLUME ["/etc/filebeat"]
VOLUME ["/etc/postfix"]
VOLUME ["/var/lib/filebeat"]

# Prepare entrypoint scripts
# Entrypoint scripts must be added to the entrypoint-scripts directory
RUN mkdir /entrypoint-scripts

COPY config/entrypoint.sh /entrypoint.sh
COPY config/00-decrypt_credentials.sh /entrypoint-scripts/00-decrypt_credentials.sh
COPY config/01-wazuh.sh /entrypoint-scripts/01-wazuh.sh
COPY config/02-set_filebeat_destination.sh /entrypoint-scripts/02-set_filebeat_destination.sh
COPY config/03-config_filebeat.sh /entrypoint-scripts/03-config_filebeat.sh
COPY config/20-ossec-configuration.sh /entrypoint-scripts/20-ossec-configuration.sh
COPY config/25-backups.sh /entrypoint-scripts/25-backups.sh
COPY config/35-remove_credentials_file.sh /entrypoint-scripts/35-remove_credentials_file.sh
COPY config/85-save_wazuh_version.sh /entrypoint-scripts/85-save_wazuh_version.sh
RUN chmod 755 /entrypoint.sh && \
    chmod 755 /entrypoint-scripts/00-decrypt_credentials.sh && \
    chmod 755 /entrypoint-scripts/01-wazuh.sh && \
    chmod 755 /entrypoint-scripts/02-set_filebeat_destination.sh && \
    chmod 755 /entrypoint-scripts/03-config_filebeat.sh && \
    chmod 755 /entrypoint-scripts/20-ossec-configuration.sh && \
    chmod 755 /entrypoint-scripts/25-backups.sh && \
    chmod 755 /entrypoint-scripts/35-remove_credentials_file.sh && \
    chmod 755 /entrypoint-scripts/85-save_wazuh_version.sh

# Load wazuh alerts template.
ADD https://raw.githubusercontent.com/wazuh/wazuh/$TEMPLATE_VERSION/extensions/elasticsearch/7.x/wazuh-template.json /etc/filebeat
RUN chmod go-w /etc/filebeat/wazuh-template.json 

# Run all services
ENTRYPOINT ["/entrypoint.sh"]

