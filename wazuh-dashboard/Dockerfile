# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)
FROM ubuntu:20.04

ARG WAZUH_VERSION=4.3.0-1

# Update and install dependencies
RUN apt-get update && apt install curl libcap2-bin -y

#Download and install Wazuh Dashboard
RUN curl https://s3.us-west-1.amazonaws.com/packages-dev.wazuh.com/pre-release/apt/pool/main/w/wazuh-dashboard/wazuh-dashboard_${WAZUH_VERSION}_amd64.deb --output wazuh-dashboard_${WAZUH_VERSION}_amd64.deb && \
    dpkg -i wazuh-dashboard_${WAZUH_VERSION}_amd64.deb && \
    apt-get clean -y && rm -rf wazuh-dashboard_${WAZUH_VERSION}_amd64.deb

COPY config/entrypoint.sh /

COPY config/wazuh_app_config.sh /

COPY config/dashboard.yml /etc/wazuh-dashboard/

COPY config/wazuh.yml /usr/share/wazuh-dashboard/data/wazuh/config/

RUN chmod 700 /entrypoint.sh

RUN chmod 700 /wazuh_app_config.sh

RUN chown 101:101 /etc/wazuh-dashboard/dashboard.yml && chmod 664 /etc/wazuh-dashboard/dashboard.yml

RUN mkdir -p /usr/share/wazuh-dashboard/data/wazuh/config && chown -R 101:101 /usr/share/wazuh-dashboard/data/wazuh/config && chmod -R 775 /usr/share/wazuh-dashboard/data/wazuh/config

RUN mkdir -p /usr/share/wazuh-dashboard/data/wazuh/logs && chown -R 101:101 /usr/share/wazuh-dashboard/data/wazuh/logs && chmod -R 775 /usr/share/wazuh-dashboard/data/wazuh/logs

# Services ports
EXPOSE 5601

ENTRYPOINT [ "/entrypoint.sh" ]