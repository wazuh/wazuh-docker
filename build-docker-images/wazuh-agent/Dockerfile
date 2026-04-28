# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

################################################################################
# Build stage 0 (builder):
# Install Wazuh Agent RPM and download tini (static PID-1 init shim).
################################################################################
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG TINI_VERSION="v0.19.0"
ARG WAZUH_MANAGER='CHANGE_MANAGER_IP'
ARG WAZUH_REGISTRATION_SERVER='CHANGE_ENROLL_IP'
ARG WAZUH_AGENT_NAME='CHANGE_AGENT_NAME'
ARG TARGETARCH
ARG wazuh_agent_x86_64_rpm
ARG wazuh_agent_aarch64_rpm

RUN RPM_ARCH="x86_64" && \
    if [ "${TARGETARCH}" = "arm64" ]; then RPM_ARCH="aarch64"; fi && \
    URL_VAR="wazuh_agent_${RPM_ARCH}_rpm" && \
    agent_url="${!URL_VAR}" && \
    dnf install curl-minimal tar gzip procps shadow-utils -y && \
    curl -o /wazuh-agent.rpm "${agent_url}" && \
    dnf install /wazuh-agent.rpm -y && \
    rm -rf /wazuh-agent.rpm && \
    dnf clean all && \
    sed -i '/<authorization_pass_path>/d' /var/ossec/etc/ossec.conf

# Download tini static binary (no external library dependencies)
RUN TINI_ARCH="amd64" && \
    if [ "${TARGETARCH}" = "arm64" ]; then TINI_ARCH="arm64"; fi && \
    curl --fail --silent -L \
    https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-${TINI_ARCH} \
    -o /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

################################################################################
# Build stage 1 (the actual Wazuh Agent image):
# Copy Wazuh Agent and tini from builder. Install only runtime dependencies.
################################################################################
FROM amazonlinux:2023

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install only runtime dependencies
RUN dnf install procps shadow-utils -y && \
    dnf clean all && \
    getent group wazuh || groupadd -r -g 999 wazuh && \
    getent passwd wazuh || useradd --system \
        --uid 999 \
        --no-create-home \
        --home-dir /var/ossec \
        --gid wazuh \
        --shell /sbin/nologin \
        wazuh

# Copy Wazuh Agent installation from builder
COPY --from=builder /var/ossec /var/ossec

# Copy tini static binary
COPY --from=builder /usr/local/bin/tini /usr/local/bin/tini

# Copy entrypoint and init scripts
COPY config/entrypoint.sh /entrypoint.sh
COPY config/etc/ /etc/

RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/usr/local/bin/tini", "--", "/entrypoint.sh"]
