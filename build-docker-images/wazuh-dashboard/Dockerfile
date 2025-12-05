# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG WAZUH_TAG_REVISION
ARG WAZUH_UI_REVISION
ARG INSTALL_DIR=/usr/share/wazuh-dashboard
ARG CONFIG_DIR=/etc/wazuh-dashboard
ARG TARGETARCH
ARG wazuh_dashboard_url_amd64_rpm
ARG wazuh_dashboard_url_arm64_rpm
ARG wazuh_config_yml

# Update and install dependencies
RUN URL_VAR="wazuh_dashboard_url_${TARGETARCH}_rpm" && \
    dashboard_url="${!URL_VAR}" && \
    dnf install curl-minimal libcap openssl -y && \
    curl -o /wazuh-dashboard.rpm "${dashboard_url}" && \
    dnf install /wazuh-dashboard.rpm -y && \
    rm -rf /wazuh-dashboard.rpm && \
    dnf clean all

# Create and set permissions to data directories
RUN mkdir -p $INSTALL_DIR/data/wazuh && chmod -R 775 $INSTALL_DIR/data/wazuh
RUN mkdir -p $INSTALL_DIR/data/wazuh/config && chmod -R 775 $INSTALL_DIR/data/wazuh/config
RUN mkdir -p $INSTALL_DIR/data/wazuh/logs && chmod -R 775 $INSTALL_DIR/data/wazuh/logs
RUN setcap 'cap_net_bind_service=-ep' /usr/share/wazuh-dashboard/node/bin/node
RUN setcap 'cap_net_bind_service=-ep' /usr/share/wazuh-dashboard/node/fallback/bin/node

################################################################################
# Build stage 1 (the current Wazuh dashboard image):
#
# Copy wazuh-dashboard from stage 0
# Add entrypoint
# Add wazuh_app_config
################################################################################
FROM amazonlinux:2023

# Set environment variables
ENV USER="wazuh-dashboard" \
    GROUP="wazuh-dashboard" \
    NAME="wazuh-dashboard" \
    INSTALL_DIR="/usr/share/wazuh-dashboard" \
    PATTERN="" \
    CHECKS_PATTERN="" \
    CHECKS_TEMPLATE="" \
    CHECKS_API="" \
    CHECKS_SETUP="" \
    APP_TIMEOUT="" \
    API_SELECTOR="" \
    IP_SELECTOR="" \
    IP_IGNORE="" \
    WAZUH_MONITORING_ENABLED="" \
    WAZUH_MONITORING_FREQUENCY="" \
    WAZUH_MONITORING_SHARDS="" \
    WAZUH_MONITORING_REPLICAS=""

# Copy and set permissions to scripts
COPY config/entrypoint.sh /
COPY config/wazuh_app_config.sh /

# Update and install dependencies
RUN yum install shadow-utils -y && \
    yum clean all && \
    getent group $GROUP || groupadd -r -g 1000 $GROUP && \
    useradd --system \
            --uid 1000 \
            --no-create-home \
            --home-dir $INSTALL_DIR \
            --gid $GROUP \
            --shell /sbin/nologin \
            --comment "$USER user" \
            $USER && \
    chmod 700 /entrypoint.sh && \
    chmod 700 /wazuh_app_config.sh && \
    mkdir -p $INSTALL_DIR && \
    chown 1000:1000 $INSTALL_DIR && \
    chown 1000:1000 /*.sh && \
    mkdir -p /usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom

# Copy Install dir from builder to current image
COPY --from=builder --chown=1000:1000 $INSTALL_DIR $INSTALL_DIR
COPY --from=builder --chown=1000:1000 $CONFIG_DIR $INSTALL_DIR/config/

# Set workdir and user
WORKDIR $INSTALL_DIR
USER wazuh-dashboard

# Services ports
EXPOSE 443

ENTRYPOINT [ "/entrypoint.sh" ]
