# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)
FROM ubuntu:focal AS builder

ARG WAZUH_VERSION=4.3.0-1

# Update and install dependencies
RUN apt-get update && apt install curl libcap2-bin -y

#Download and install Wazuh Dashboard
RUN curl https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-dashboard/wazuh-dashboard_${WAZUH_VERSION}_amd64.deb --output wazuh-dashboard_${WAZUH_VERSION}_amd64.deb && \
    dpkg -i wazuh-dashboard_${WAZUH_VERSION}_amd64.deb && \
    apt-get clean -y && rm -rf wazuh-dashboard_${WAZUH_VERSION}_amd64.deb


COPY config/opensearch_dashboards.yml /etc/wazuh-dashboard/

COPY config/wazuh.yml /usr/share/wazuh-dashboard/data/wazuh/config/

RUN chown 101:101 /etc/wazuh-dashboard/opensearch_dashboards.yml && chmod 664 /etc/wazuh-dashboard/opensearch_dashboards.yml

RUN mkdir -p /usr/share/wazuh-dashboard/data/wazuh && chown -R 101:101 /usr/share/wazuh-dashboard/data/wazuh && chmod -R 775 /usr/share/wazuh-dashboard/data/wazuh

RUN mkdir -p /usr/share/wazuh-dashboard/data/wazuh/config && chown -R 101:101 /usr/share/wazuh-dashboard/data/wazuh/config && chmod -R 775 /usr/share/wazuh-dashboard/data/wazuh/config

RUN mkdir -p /usr/share/wazuh-dashboard/data/wazuh/logs && chown -R 101:101 /usr/share/wazuh-dashboard/data/wazuh/logs && chmod -R 775 /usr/share/wazuh-dashboard/data/wazuh/logs

################################################################################
# Build stage 1 (the actual Wazuh dashboard image):
#
# Copy wazuh-dashboard from stage 0
# Add entrypoint
# Add wazuh_app_config
################################################################################
FROM ubuntu:focal

ENV USER="wazuh-dashboard" \
    GROUP="wazuh-dashboard" \
    NAME="wazuh-dashboard" \
    INSTALL_DIR="/usr/share/wazuh-dashboard"

RUN getent group $GROUP || groupadd -r -g 1000 $GROUP

RUN useradd --system \
            --uid 1000 \
            --no-create-home \
            --home-dir $INSTALL_DIR \
            --gid $GROUP \
            --shell /sbin/nologin \
            --comment "$USER user" \
            $USER

COPY config/entrypoint.sh /

COPY config/wazuh_app_config.sh /

RUN chmod 700 /entrypoint.sh

RUN chmod 700 /wazuh_app_config.sh

COPY --from=builder --chown=1000:1000 /usr/share/wazuh-dashboard /usr/share/wazuh-dashboard
COPY --from=builder --chown=1000:1000 /var/log/wazuh-dashboard /var/log/wazuh-dashboard
COPY --from=builder --chown=1000:1000 /run/wazuh-dashboard /run/wazuh-dashboard
COPY --from=builder --chown=1000:1000 /etc/wazuh-dashboard /etc/wazuh-dashboard

# Services ports
EXPOSE 443

ENTRYPOINT [ "/entrypoint.sh" ]