# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

################################################################################
# Build stage 0 (builder):
# Install Wazuh Manager RPM, configure directories, prepare permanent data,
# and download tini (static PID-1 init shim).
################################################################################
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG TINI_VERSION="v0.19.0"
ARG TARGETARCH
ARG wazuh_manager_x86_64_rpm
ARG wazuh_manager_aarch64_rpm

# Prepare permanent data config needed by permanent_data.sh at build time
COPY config/permanent_data.env config/permanent_data.sh /

RUN RPM_ARCH="x86_64" && \
    if [ "${TARGETARCH}" = "arm64" ]; then RPM_ARCH="aarch64"; fi && \
    URL_VAR="wazuh_manager_${RPM_ARCH}_rpm" && \
    manager_url="${!URL_VAR}" && \
    dnf install curl-minimal xz gnupg tar gzip openssl findutils procps shadow-utils -y && \
    dnf clean all && \
    curl -o /wazuh-manager.rpm "${manager_url}" && \
    dnf install /wazuh-manager.rpm -y && \
    rm -rf /wazuh-manager.rpm && \
    dnf clean all && \
    # Set up required directories with correct ownership
    mkdir -p /var/wazuh-manager/var/multigroups && \
    chown root:wazuh-manager /var/wazuh-manager/var/multigroups && \
    chmod 770 /var/wazuh-manager/var/multigroups && \
    mkdir -p /var/wazuh-manager/etc/certs && \
    chown wazuh-manager:wazuh-manager /var/wazuh-manager/etc/certs && \
    chmod 500 /var/wazuh-manager/etc/certs && \
    rm -f /var/wazuh-manager/etc/sslmanager.key && \
    rm -f /var/wazuh-manager/etc/sslmanager.cert

# Prepare permanent data snapshot (sync calls: https://github.com/docker/docker/issues/9547)
RUN chmod 755 /permanent_data.sh && \
    sync && /permanent_data.sh && \
    sync && rm /permanent_data.sh

# Download tini static binary (no external library dependencies)
RUN curl --fail --silent -L \
    https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-${TARGETARCH} \
    -o /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

################################################################################
# Build stage 1 (the actual Wazuh Manager image):
# Copy Wazuh Manager and tini from builder. Install only runtime dependencies.
################################################################################
FROM amazonlinux:2023

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install only runtime dependencies (no curl, tar, gzip, xz, or full dnf stack)
RUN dnf install openssl findutils procps shadow-utils -y && \
    dnf clean all && \
    getent group wazuh-manager || groupadd -r -g 999 wazuh-manager && \
    getent passwd wazuh-manager || useradd --system \
        --uid 999 \
        --no-create-home \
        --home-dir /var/wazuh-manager \
        --gid wazuh-manager \
        --shell /sbin/nologin \
        wazuh-manager

# Copy Wazuh Manager installation (includes permanent data snapshot)
COPY --from=builder /var/wazuh-manager /var/wazuh-manager

# Copy tini static binary
COPY --from=builder /usr/local/bin/tini /usr/local/bin/tini

# Copy entrypoint, init scripts and runtime config
COPY config/entrypoint.sh /entrypoint.sh
COPY config/etc/ /etc/
COPY config/permanent_data.env /

RUN chmod 755 /entrypoint.sh

# Services ports
EXPOSE 55000/tcp 1514/tcp 1515/tcp 514/udp 1516/tcp

ENTRYPOINT ["/usr/local/bin/tini", "--", "/entrypoint.sh"]
