# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
FROM ubuntu:focal AS builder

ARG WAZUH_VERSION
ARG WAZUH_TAG_REVISION
ARG INSTALL_DIR=/usr/share/wazuh-dashboard
ARG WAZUH_UI_REVISION=1

# Update and install dependencies
RUN apt-get update && apt install curl libcap2-bin xz-utils -y

# Create Install dir
RUN mkdir -p $INSTALL_DIR

# Download and extract Wazuh dashboard base
COPY config/dl_base.sh .
RUN bash dl_base.sh

# Generate certificates
COPY config/config.sh .
COPY config/config.yml /
RUN bash config.sh

COPY config/install_wazuh_app.sh /
RUN chmod 775 /install_wazuh_app.sh
RUN bash /install_wazuh_app.sh

# Copy and set permissions to config files
COPY config/opensearch_dashboards.yml $INSTALL_DIR/config/
COPY config/wazuh.yml $INSTALL_DIR/data/wazuh/config/
RUN chown 101:101 $INSTALL_DIR/config/opensearch_dashboards.yml && chmod 664 $INSTALL_DIR/config/opensearch_dashboards.yml

# Create and set permissions to data directories
RUN mkdir -p $INSTALL_DIR/data/wazuh && chown -R 101:101 $INSTALL_DIR/data/wazuh && chmod -R 775 $INSTALL_DIR/data/wazuh
RUN mkdir -p $INSTALL_DIR/data/wazuh/config && chown -R 101:101 $INSTALL_DIR/data/wazuh/config && chmod -R 775 $INSTALL_DIR/data/wazuh/config
RUN mkdir -p $INSTALL_DIR/data/wazuh/logs && chown -R 101:101 $INSTALL_DIR/data/wazuh/logs && chmod -R 775 $INSTALL_DIR/data/wazuh/logs

################################################################################
# Build stage 1 (the current Wazuh dashboard image):
#
# Copy wazuh-dashboard from stage 0
# Add entrypoint
# Add wazuh_app_config
################################################################################
FROM ubuntu:focal

# Set environment variables
ENV USER="wazuh-dashboard" \
    GROUP="wazuh-dashboard" \
    NAME="wazuh-dashboard" \
    INSTALL_DIR="/usr/share/wazuh-dashboard"

# Set Wazuh app variables
ENV PATTERN="" \
    CHECKS_PATTERN="" \
    CHECKS_TEMPLATE="" \
    CHECKS_API="" \
    CHECKS_SETUP="" \
    EXTENSIONS_PCI="" \
    EXTENSIONS_GDPR="" \
    EXTENSIONS_HIPAA="" \
    EXTENSIONS_NIST="" \
    EXTENSIONS_TSC="" \
    EXTENSIONS_AUDIT="" \
    EXTENSIONS_OSCAP="" \
    EXTENSIONS_CISCAT="" \
    EXTENSIONS_AWS="" \
    EXTENSIONS_GCP="" \
    EXTENSIONS_VIRUSTOTAL="" \
    EXTENSIONS_OSQUERY="" \
    EXTENSIONS_DOCKER="" \
    APP_TIMEOUT="" \
    API_SELECTOR="" \
    IP_SELECTOR="" \
    IP_IGNORE="" \
    WAZUH_MONITORING_ENABLED="" \
    WAZUH_MONITORING_FREQUENCY="" \
    WAZUH_MONITORING_SHARDS="" \
    WAZUH_MONITORING_REPLICAS=""

# Install dependencies
RUN apt update && apt install -y libnss3-dev fonts-liberation libfontconfig1

# Create wazuh-dashboard user and group
RUN getent group $GROUP || groupadd -r -g 1000 $GROUP
RUN useradd --system \
            --uid 1000 \
            --no-create-home \
            --home-dir $INSTALL_DIR \
            --gid $GROUP \
            --shell /sbin/nologin \
            --comment "$USER user" \
            $USER

# Copy and set permissions to scripts
COPY config/entrypoint.sh /
COPY config/wazuh_app_config.sh /
RUN chmod 700 /entrypoint.sh
RUN chmod 700 /wazuh_app_config.sh
RUN chown 1000:1000 /*.sh

# Copy Install dir from builder to current image
COPY --from=builder --chown=1000:1000 $INSTALL_DIR $INSTALL_DIR

# Set workdir and user
WORKDIR $INSTALL_DIR
USER wazuh-dashboard

# Services ports
EXPOSE 443

ENTRYPOINT [ "/entrypoint.sh" ]
