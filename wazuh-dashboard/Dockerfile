# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)
FROM ubuntu:20.04

ARG WAZUH_VERSION=4.3.0-1
ARG TEMPLATE_VERSION="master"
ARG FILEBEAT_CHANNEL=filebeat-oss
ARG FILEBEAT_VERSION=7.10.2
ARG WAZUH_FILEBEAT_MODULE="wazuh-filebeat-0.1.tar.gz"

RUN apt-get update && apt install curl libcap2-bin -y

RUN curl https://s3.amazonaws.com/warehouse.wazuh.com/stack/dashboard/stable/wazuh-dashboard_${WAZUH_VERSION}_amd64.deb --output wazuh-dashboard_${WAZUH_VERSION}_amd64.deb && \
    dpkg -i wazuh-dashboard_${WAZUH_VERSION}_amd64.deb

# Prepare permanent data
# Sync calls are due to https://github.com/docker/docker/issues/9547

COPY config/entrypoint.sh /
COPY config/wazuh_app_config.sh /

RUN chmod 700 /entrypoint.sh
RUN chmod 700 /wazuh_app_config.sh

# Services ports
EXPOSE 5601

ENTRYPOINT [ "/entrypoint.sh" ]