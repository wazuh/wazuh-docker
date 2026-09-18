# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

################################################################################
# Build stage 0 (builder):
# Install Wazuh Agent RPM and download tini (static PID-1 init shim).
################################################################################
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG TINI_VERSION="v0.19.0"
# WAZUH_MANAGER_ENDPOINT here is a placeholder for the runtime init script to
# substitute, not real configuration -- there is no manager to point at during a
# build. It used to reach the package post-install as an environment variable
# and get written into <endpoint> that way, but wazuh/wazuh#39285 (5.0.0) made
# the package's own installer stop writing any address without a real
# enrollment token, which a build obviously does not have. So it is written
# below, into the packaged ossec.conf directly, instead of relying on the
# installer for it.
ARG WAZUH_MANAGER_ENDPOINT='CHANGE_MANAGER_ENDPOINT'
ARG WAZUH_AGENT_NAME='CHANGE_AGENT_NAME'
ARG TARGETARCH
ARG wazuh_agent_x86_64_rpm
ARG wazuh_agent_aarch64_rpm
ARG WAZUH_UID=101
ARG WAZUH_GID=101

# Prepare permanent data config needed by permanent_data.sh at build time
COPY config/permanent_data.env config/permanent_data.sh /

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

# Write the <endpoint> placeholder ourselves: the packaged ossec.conf ships with
# a real default (<endpoint>IP:1517/wazuh-manager/</endpoint>), and nothing in
# the installer replaces it with our placeholder any more (see the ARG comment
# above), so this is the only thing that puts CHANGE_MANAGER_ENDPOINT there for
# the runtime init script to find. Scoped to <manager> the same way the runtime
# script scopes its own substitution, so a second <endpoint>-shaped tag
# elsewhere in the file is never touched.
RUN conf=/var/ossec/etc/ossec.conf; \
    sed -i "/<manager>/,/<\/manager>/ s#<endpoint>.*</endpoint>#<endpoint>${WAZUH_MANAGER_ENDPOINT}</endpoint>#" "$conf"

# Fail the build if the above stops working, or if the package installer starts
# writing the agent name placeholder somewhere this image does not expect:
# without them the manager endpoint and the agent name are silently ignored at
# container start, which is how the port support was lost once already (#2590).
RUN conf=/var/ossec/etc/ossec.conf; \
    grep -q 'CHANGE_MANAGER_ENDPOINT' "$conf" || \
        { echo "ERROR: CHANGE_MANAGER_ENDPOINT is missing from the packaged ossec.conf"; exit 1; }; \
    grep -q 'CHANGE_AGENT_NAME' "$conf" || \
        { echo "ERROR: CHANGE_AGENT_NAME is missing from the packaged ossec.conf"; exit 1; }

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
# Build stage 1 (the actual Wazuh Agent image):
# Copy Wazuh Agent and tini from builder. Install only runtime dependencies.
################################################################################
FROM amazonlinux:2023

ARG WAZUH_UID=101
ARG WAZUH_GID=101

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install only runtime dependencies
RUN dnf install diffutils findutils procps shadow-utils -y && \
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

# Where the init script puts the TLS material for the manager connection, and
# where a CA may be dropped instead of being named by a variable. The package
# ships no such directory, and wazuh-agentd reads what lands here after dropping
# privileges, so it is created up front and owned by the agent user.
RUN mkdir -p /var/ossec/etc/certs && \
    chown wazuh:wazuh /var/ossec/etc/certs && \
    chmod 750 /var/ossec/etc/certs

# Copy tini static binary
COPY --from=builder /usr/local/bin/tini /usr/local/bin/tini

# Copy entrypoint and init scripts
COPY config/entrypoint.sh /entrypoint.sh
COPY config/etc/ /etc/
COPY config/permanent_data.env /

RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/usr/local/bin/tini", "--", "/entrypoint.sh"]
