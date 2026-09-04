# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

################################################################################
# Build stage 0 (builder):
# Install Wazuh Agent RPM and download tini (static PID-1 init shim).
################################################################################
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG TINI_VERSION="v0.19.0"
# These reach the package post-install as environment variables, and their values
# are what it writes into the packaged ossec.conf. They are therefore the
# placeholders the runtime init script substitutes, not real configuration.
#
# The package accepts either WAZUH_MANAGER_ENDPOINT or the WAZUH_MANAGER and
# WAZUH_MANAGER_PORT pair, and only the endpoint is set here: one placeholder for
# one <endpoint> tag, whichever pair the deployment then uses to fill it in. The
# image therefore needs a package that understands WAZUH_MANAGER_ENDPOINT
# (wazuh/wazuh#38624); against an older one the placeholder check below fails.
ARG WAZUH_MANAGER_ENDPOINT='CHANGE_MANAGER_ENDPOINT'
ARG WAZUH_AGENT_NAME='CHANGE_AGENT_NAME'
ARG TARGETARCH
ARG wazuh_agent_x86_64_rpm
ARG wazuh_agent_aarch64_rpm
ARG WAZUH_UID=101
ARG WAZUH_GID=101

# Install only runtime dependencies
RUN dnf install procps shadow-utils -y && \
    dnf clean all && \
    getent group wazuh || groupadd -r -g ${WAZUH_GID} wazuh && \
    getent passwd wazuh || useradd --system \
        --no-create-home \
        --home-dir /var/ossec \
        --uid ${WAZUH_UID} \
        --gid ${WAZUH_GID} \
        --shell /sbin/nologin \
        wazuh && \
    RPM_ARCH="x86_64" && \
    if [ "${TARGETARCH}" = "arm64" ]; then RPM_ARCH="aarch64"; fi && \
    URL_VAR="wazuh_agent_${RPM_ARCH}_rpm" && \
    agent_url="${!URL_VAR}" && \
    dnf install curl-minimal tar gzip procps shadow-utils -y && \
    curl -o /wazuh-agent.rpm "${agent_url}" && \
    dnf install /wazuh-agent.rpm -y && \
    rm -rf /wazuh-agent.rpm && \
    dnf clean all

# Fail the build if the package installer stops writing the placeholders that the
# runtime init script substitutes: without them the manager endpoint and the agent
# name are silently ignored at container start, which is how the port support was
# lost once already (#2590).
#
# CHANGE_MANAGER_ENDPOINT is the only manager placeholder the init substitutes,
# since <endpoint> is the only tag it configures.
RUN conf=/var/ossec/etc/ossec.conf; \
    grep -q 'CHANGE_MANAGER_ENDPOINT' "$conf" || \
        { echo "ERROR: CHANGE_MANAGER_ENDPOINT is missing from the packaged ossec.conf"; exit 1; }; \
    grep -q 'CHANGE_AGENT_NAME' "$conf" || \
        { echo "ERROR: CHANGE_AGENT_NAME is missing from the packaged ossec.conf"; exit 1; }

# Download tini static binary (no external library dependencies)
RUN curl --fail --silent -L \
    https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-${TARGETARCH} \
    -o /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

################################################################################
# Build stage 1 (the actual Wazuh Agent image):
# Copy Wazuh Agent and tini from builder. Install only runtime dependencies.
################################################################################
FROM amazonlinux:2023

ARG WAZUH_UID=101
ARG WAZUH_GID=101

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install only runtime dependencies
RUN dnf install diffutils procps shadow-utils -y && \
    dnf clean all && \
    getent group wazuh || groupadd -r -g ${WAZUH_GID} wazuh && \
    getent passwd wazuh || useradd --system \
        --no-create-home \
        --home-dir /var/ossec \
        --uid ${WAZUH_UID} \
        --gid ${WAZUH_GID} \
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
