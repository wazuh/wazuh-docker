# Wazuh Docker Copyright (C) Wazuh Inc. (License GPLv2)
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG INSTALL_DIR=/usr/share/wazuh-dashboard
ARG TARGETARCH
ARG wazuh_dashboard_x86_64_rpm
ARG wazuh_dashboard_aarch64_rpm
ARG wazuh_config_yml
ARG SKIP_PACKAGE_SIGNATURE_CHECK
ARG WAZUH_UID=101
ARG WAZUH_GID=101

# Set environment variables
ENV USER="wazuh-dashboard" \
    GROUP="wazuh-dashboard" \
    NAME="wazuh-dashboard" \
    INSTALL_DIR="/usr/share/wazuh-dashboard" 

COPY --from=shared verify-package-signature.sh /

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
    dnf install curl-minimal openssl -y && \
    curl --fail --proto '=https' -o /wazuh-dashboard.rpm "${dashboard_url}" && \
    bash /verify-package-signature.sh /wazuh-dashboard.rpm && \
    dnf install util-linux -y && \
    dnf install /wazuh-dashboard.rpm -y && \
    rm -rf /wazuh-dashboard.rpm && \
    dnf clean all && \
    # The package's %post resolved credentials for this build host; remove
    # them so no two containers from this image share one.
    /usr/share/wazuh-dashboard/bin/resolve-credentials --clear

# Create and set permissions to data directories
RUN mkdir -p $INSTALL_DIR/data/wazuh && chmod -R 775 $INSTALL_DIR/data/wazuh
RUN mkdir -p $INSTALL_DIR/data/wazuh/config && chmod -R 775 $INSTALL_DIR/data/wazuh/config
RUN mkdir -p $INSTALL_DIR/data/wazuh/logs && chmod -R 775 $INSTALL_DIR/data/wazuh/logs

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
COPY --from=shared credentials-env.sh /

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
    chown root:root /entrypoint.sh /credentials-env.sh /wazuh_dashboard_config.sh && \
    chmod 755 /entrypoint.sh && \
    chmod 644 /credentials-env.sh && \
    chmod 700 /wazuh_dashboard_config.sh && \
    mkdir -p /usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom

# COPY keeps the package's ownership of everything below the install
# directory, and creates the directory itself root:root 755, as the package
# installs it. The credentials resolver runs as root, so nothing it runs may
# belong to the service user.
COPY --from=builder $INSTALL_DIR $INSTALL_DIR
COPY --from=builder /etc/wazuh-dashboard $INSTALL_DIR/config/
# config/ stands in for the package's /etc/wazuh-dashboard, and takes its
# ownership: root's, read by the dashboard through its group. The credentials
# resolver trusts nothing the service user can write.
RUN chown root:${WAZUH_GID} $INSTALL_DIR/config && \
    chmod 750 $INSTALL_DIR/config && \
    mkdir -p $INSTALL_DIR/config/certs && \
    chown root:${WAZUH_GID} $INSTALL_DIR/config/certs && \
    chmod 750 $INSTALL_DIR/config/certs

# Starts as root and drops to wazuh-dashboard once the credentials are stored
WORKDIR $INSTALL_DIR

# Services ports
EXPOSE 443

ENTRYPOINT [ "/entrypoint.sh" ]
