# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG WAZUH_TAG_REVISION
ARG WAZUH_UI_REVISION
ARG INSTALL_DIR=/usr/share/wazuh-dashboard

# Update and install dependencies
RUN yum install curl-minimal libcap openssl -y

COPY config/check_repository.sh /
RUN chmod 775 /check_repository.sh && \
    source /check_repository.sh

RUN yum install wazuh-dashboard-${WAZUH_VERSION}-${WAZUH_TAG_REVISION} -y && \
    yum clean all

# Create and set permissions to data directories
RUN mkdir -p $INSTALL_DIR/data/wazuh && chmod -R 775 $INSTALL_DIR/data/wazuh
RUN mkdir -p $INSTALL_DIR/data/wazuh/config && chmod -R 775 $INSTALL_DIR/data/wazuh/config
RUN mkdir -p $INSTALL_DIR/data/wazuh/logs && chmod -R 775 $INSTALL_DIR/data/wazuh/logs
COPY config/wazuh.yml $INSTALL_DIR/data/wazuh/config/

# Generate certificates
COPY config/config.sh .
COPY config/config.yml /
RUN bash config.sh

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
    EXTENSIONS_GITHUB=""\
    EXTENSIONS_OFFICE=""\
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

# Update and install dependencies
RUN yum install shadow-utils -y

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

# Create custom directory
RUN mkdir -p /usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom
RUN chown 1000:1000 /usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom

# Set workdir and user
WORKDIR $INSTALL_DIR
USER wazuh-dashboard

# Services ports
EXPOSE 443

ENTRYPOINT [ "/entrypoint.sh" ]
