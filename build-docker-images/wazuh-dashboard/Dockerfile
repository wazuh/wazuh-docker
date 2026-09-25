# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG INSTALL_DIR=/usr/share/wazuh-dashboard
ARG TARGETARCH
ARG wazuh_dashboard_x86_64_rpm
ARG wazuh_dashboard_aarch64_rpm
ARG wazuh_config_yml
ARG WAZUH_UID=101
ARG WAZUH_GID=101

# Set environment variables
ENV USER="wazuh-dashboard" \
    GROUP="wazuh-dashboard" \
    NAME="wazuh-dashboard" \
    INSTALL_DIR="/usr/share/wazuh-dashboard" 

# Update and install dependencies
RUN yum install shadow-utils -y && \
    yum clean all && \
    getent group $GROUP || groupadd -r -g ${WAZUH_GID} $GROUP && \
    useradd --system \
    --uid ${WAZUH_UID} \
    --no-create-home \
    --home-dir $INSTALL_DIR \
    --gid $GROUP \
    --shell /sbin/nologin \
    --comment "$USER user" \
    $USER && \
    RPM_ARCH="x86_64" && \
    if [ "${TARGETARCH}" = "arm64" ]; then RPM_ARCH="aarch64"; fi && \
    URL_VAR="wazuh_dashboard_${RPM_ARCH}_rpm" && \
    dashboard_url="${!URL_VAR}" && \
    dnf install curl-minimal libcap openssl -y && \
    curl -o /wazuh-dashboard.rpm "${dashboard_url}" && \
    dnf install util-linux -y && \
    dnf install /wazuh-dashboard.rpm -y && \
    rm -rf /wazuh-dashboard.rpm && \
    dnf clean all && \
    # The package's %post resolved credentials for this build host; remove
    # them so no two containers from this image share one.
    /usr/share/wazuh-dashboard/bin/resolve-credentials --clear && \
    rm -rf /etc/wazuh && \
    # The dashboard walks its home directory at start and exits on EACCES;
    # lib/ stays root-owned, and so not writable by the service user.
    chmod 755 /usr/share/wazuh-dashboard/lib

# Create and set permissions to data directories
RUN mkdir -p $INSTALL_DIR/data/wazuh && chmod -R 775 $INSTALL_DIR/data/wazuh
RUN mkdir -p $INSTALL_DIR/data/wazuh/config && chmod -R 775 $INSTALL_DIR/data/wazuh/config
RUN mkdir -p $INSTALL_DIR/data/wazuh/logs && chmod -R 775 $INSTALL_DIR/data/wazuh/logs
RUN setcap 'cap_net_bind_service=-ep' /usr/share/wazuh-dashboard/node/bin/node

# Delete default keystore
RUN if [ -f /etc/wazuh-dashboard/opensearch_dashboards.keystore ]; then rm -f /etc/wazuh-dashboard/opensearch_dashboards.keystore; fi

################################################################################
# Build stage 1 (the current Wazuh dashboard image):
# Copy wazuh-dashboard from builder
# Add entrypoint
# Add wazuh_dashboard_config
################################################################################
FROM amazonlinux:2023

ARG WAZUH_UID=101
ARG WAZUH_GID=101

# Set environment variables
ENV USER="wazuh-dashboard" \
    GROUP="wazuh-dashboard" \
    NAME="wazuh-dashboard" \
    INSTALL_DIR="/usr/share/wazuh-dashboard"

# Copy and set permissions to scripts
COPY config/entrypoint.sh /
COPY config/wazuh_dashboard_config.sh /

# Update and install dependencies. The entrypoint runs as root to resolve
# the credentials, so it must not be writable by the service user.
RUN yum install shadow-utils util-linux -y && \
    yum clean all && \
    getent group $GROUP || groupadd -r -g ${WAZUH_GID} $GROUP && \
    useradd --system \
    --uid ${WAZUH_UID} \
    --no-create-home \
    --home-dir $INSTALL_DIR \
    --gid $GROUP \
    --shell /sbin/nologin \
    --comment "$USER user" \
    $USER && \
    chown root:root /entrypoint.sh && \
    chmod 755 /entrypoint.sh && \
    chown ${WAZUH_UID}:${WAZUH_GID} /wazuh_dashboard_config.sh && \
    chmod 700 /wazuh_dashboard_config.sh && \
    mkdir -p $INSTALL_DIR && \
    chown ${WAZUH_UID}:${WAZUH_GID} $INSTALL_DIR && \
    mkdir -p /usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom

# Copy Install dir from builder to current image
COPY --from=builder $INSTALL_DIR $INSTALL_DIR
COPY --from=builder /etc/wazuh-dashboard $INSTALL_DIR/config/

# Starts as root and drops to wazuh-dashboard once the credentials are stored
WORKDIR $INSTALL_DIR

# Services ports
EXPOSE 443

ENTRYPOINT [ "/entrypoint.sh" ]
