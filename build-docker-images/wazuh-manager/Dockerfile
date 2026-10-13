# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

################################################################################
# Build stage 0 (builder):
# Install Wazuh Manager RPM, configure directories, prepare permanent data,
# and download tini (static PID-1 init shim).
################################################################################
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG TINI_VERSION="v0.19.0"
# SHA-256 of tini-static-<arch> for TINI_VERSION, from its release page.
ARG TINI_SHA256_AMD64="c5b0666b4cb676901f90dfcb37106783c5fe2077b04590973b885950611b30ee"
ARG TINI_SHA256_ARM64="eae1d3aa50c48fb23b8cbdf4e369d0910dfc538566bfd09df89a774aa84a48b9"
ARG TARGETARCH
ARG wazuh_manager_x86_64_rpm
ARG wazuh_manager_aarch64_rpm
ARG SKIP_PACKAGE_SIGNATURE_CHECK
ARG WAZUH_UID=101
ARG WAZUH_GID=101

# Prepare permanent data config needed by permanent_data.sh at build time
COPY config/permanent_data.env config/permanent_data.sh config/check-data-exceptions.sh /
COPY --from=shared verify-package-signature.sh /

RUN dnf install openssl findutils procps shadow-utils util-linux diffutils iproute hostname -y && \
    dnf clean all && \
    getent group wazuh-manager || groupadd -r -g ${WAZUH_GID} wazuh-manager && \
    getent passwd wazuh-manager || useradd --system \
        --no-create-home \
        --home-dir /var/wazuh-manager \
        --uid ${WAZUH_UID} \
        --gid ${WAZUH_GID} \
        --shell /sbin/nologin \
        wazuh-manager && \
    RPM_ARCH="x86_64" && \
    if [ "${TARGETARCH}" = "arm64" ]; then RPM_ARCH="aarch64"; fi && \
    URL_VAR="wazuh_manager_${RPM_ARCH}_rpm" && \
    manager_url="${!URL_VAR}" && \
    dnf install curl-minimal xz gnupg tar gzip -y && \
    dnf clean all && \
    curl --fail --proto '=https' -o /wazuh-manager.rpm "${manager_url}" && \
    bash /verify-package-signature.sh /wazuh-manager.rpm && \
    dnf install /wazuh-manager.rpm -y && \
    rm -rf /wazuh-manager.rpm && \
    dnf clean all && \
    # Set up required directories with correct ownership
    mkdir -p /var/wazuh-manager/var/multigroups && \
    chown root:wazuh-manager /var/wazuh-manager/var/multigroups && \
    chmod 770 /var/wazuh-manager/var/multigroups && \
    mkdir -p /var/wazuh-manager/etc/certs && \
    chown root:wazuh-manager /var/wazuh-manager/etc/certs && \
    chmod 1770 /var/wazuh-manager/etc/certs && \
    # The package's %post resolved credentials for this build host: rbac.db,
    # the keystore, a bootstrap CA and the three certificate pairs. Remove them
    # so no two containers from this image share one; each container resolves
    # its own at start (etc/cont-init.d/1-credentials), and the certificate
    # pairs are mounted from the host.
    /var/wazuh-manager/bin/wazuh-manager-resolve-credentials --clear -H /var/wazuh-manager && \
    rm -rf /etc/wazuh && \
    # Clear the cluster key for the same reason the certificates above are
    # removed: the installer generates it once, here, and copying the installed
    # tree into the image would publish that single secret inside every pull of
    # this tag. Each container generates its own key on first start
    # (etc/cont-init.d/0-wazuh-init) unless WAZUH_CLUSTER_KEY is set.
    # This runs before permanent_data.sh, so the snapshot restored into a fresh
    # 'etc' volume ships the empty key too.
    sed -i "/<cluster>/,/<\/cluster>/ s|<key>.*</key>|<key></key>|" \
        /var/wazuh-manager/etc/wazuh-manager.conf

# Prepare permanent data snapshot (sync calls: https://github.com/docker/docker/issues/9547)
RUN chmod 755 /permanent_data.sh && \
    sync && /permanent_data.sh && \
    sync && rm /permanent_data.sh

# Fail the build if the image ships content under data/ that neither the exclusion
# list nor the manager itself owns: a deployment upgrading onto an existing data
# volume would never see it. See docs/ref/configuration/configuration-files.md.
RUN chmod 755 /check-data-exceptions.sh && \
    /check-data-exceptions.sh && \
    rm /check-data-exceptions.sh

# Download tini static binary (no external library dependencies) and check it
# against its pinned SHA-256
RUN case "${TARGETARCH}" in \
        amd64) tini_sha256="${TINI_SHA256_AMD64}" ;; \
        arm64) tini_sha256="${TINI_SHA256_ARM64}" ;; \
        *) echo "ERROR: No tini checksum for architecture '${TARGETARCH}'"; exit 1 ;; \
    esac && \
    curl --fail --silent -L \
    https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-${TARGETARCH} \
    -o /usr/local/bin/tini && \
    { echo "${tini_sha256}  /usr/local/bin/tini" | sha256sum -c - || \
        { echo "ERROR: tini-static-${TARGETARCH} ${TINI_VERSION} does not match its pinned SHA-256"; exit 1; }; } && \
    chmod +x /usr/local/bin/tini

################################################################################
# Build stage 1 (the actual Wazuh Manager image):
# Copy Wazuh Manager and tini from builder. Install only runtime dependencies.
################################################################################
FROM amazonlinux:2023

ARG WAZUH_UID=101
ARG WAZUH_GID=101

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install only runtime dependencies (no curl, tar, gzip, xz, or full dnf stack)
# util-linux-core provides flock, which the credentials resolver takes on its
# first start; the tools it needs to issue certificates are not required here.
RUN dnf install openssl findutils procps shadow-utils util-linux-core -y && \
    dnf clean all && \
    getent group wazuh-manager || groupadd -r -g ${WAZUH_GID} wazuh-manager && \
    getent passwd wazuh-manager || useradd --system \
        --no-create-home \
        --home-dir /var/wazuh-manager \
        --uid ${WAZUH_UID} \
        --gid ${WAZUH_GID} \
        --shell /sbin/nologin \
        wazuh-manager

# Copy Wazuh Manager installation (includes permanent data snapshot)
COPY --from=builder /var/wazuh-manager /var/wazuh-manager

# Copy tini static binary
COPY --from=builder /usr/local/bin/tini /usr/local/bin/tini

# Copy entrypoint, init scripts and runtime config
COPY config/entrypoint.sh /entrypoint.sh
COPY config/password-tool.sh /password-tool.sh
COPY config/install-credentials.sh /install-credentials.sh
COPY config/etc/ /etc/
COPY config/permanent_data.env /

RUN chmod 755 /entrypoint.sh /password-tool.sh && \
    chmod 700 /etc/wazuh-api-users.py && \
    chown root:root /install-credentials.sh && \
    chmod 700 /install-credentials.sh

# Services ports
#   1517/tcp: agent communication and enrollment (Wazuh 5.x agents, HTTPS)
#   1514/tcp: agent communication for Wazuh 4.x agents (legacy remoted)
#   1515/tcp: agent enrollment for Wazuh 4.x agents (authd)
#   514/udp:  syslog event collection
#   1516/tcp: cluster communication between manager nodes
#   55000/tcp: Wazuh API
EXPOSE 55000/tcp 1517/tcp 1514/tcp 1515/tcp 514/udp 1516/tcp

ENTRYPOINT ["/usr/local/bin/tini", "--", "/entrypoint.sh"]
