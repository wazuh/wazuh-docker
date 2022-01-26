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

RUN chmod 700 /entrypoint.sh

# Services ports
EXPOSE 5601

ENTRYPOINT [ "/entrypoint.sh" ]