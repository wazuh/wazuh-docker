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

RUN chmod 700 /entrypoint.sh

RUN chmod 700 /wazuh_app_config.sh

RUN chown 101:101 /etc/wazuh-dashboard/dashboard.yml && chmod 664 /etc/wazuh-dashboard/dashboard.yml

# Services ports
EXPOSE 5601

ENTRYPOINT [ "/entrypoint.sh" ]