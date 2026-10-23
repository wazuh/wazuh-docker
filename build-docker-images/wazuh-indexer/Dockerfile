# Wazuh Docker Copyright (C) Wazuh Inc. (License GPLv2)
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG TARGETARCH
ARG wazuh_indexer_x86_64_rpm
ARG wazuh_indexer_aarch64_rpm
ARG wazuh_certs_tool
ARG wazuh_config_yml
ARG SKIP_PACKAGE_SIGNATURE_CHECK
ARG WAZUH_UID=101
ARG WAZUH_GID=101

ENV USER="wazuh-indexer" \
    GROUP="wazuh-indexer" \
    NAME="wazuh-indexer" \
    INSTALL_DIR="/usr/share/wazuh-indexer" 

COPY config/config.sh .
COPY --from=shared verify-package-signature.sh /

RUN yum install curl-minimal shadow-utils findutils hostname -y && \
    yum clean all && \
    getent group $GROUP || groupadd -r -g ${WAZUH_GID} $GROUP && \
    useradd --system \
            --uid ${WAZUH_UID} \
            --no-create-home \
            --home-dir $INSTALL_DIR \
            --gid ${WAZUH_GID} \
            --shell /sbin/nologin \
            --comment "$USER user" \
            $USER && \
    RPM_ARCH="x86_64" && \
    if [ "${TARGETARCH}" = "arm64" ]; then RPM_ARCH="aarch64"; fi && \
    URL_VAR="wazuh_indexer_${RPM_ARCH}_rpm" && \
    indexer_url="${!URL_VAR}" && \
    dnf install curl-minimal openssl xz tar findutils shadow-utils -y &&\
    curl --fail --proto '=https' -o /wazuh-indexer.rpm "${indexer_url}" && \
    bash /verify-package-signature.sh /wazuh-indexer.rpm && \
    dnf install /wazuh-indexer.rpm -y && \
    # The package's %post resolved credentials for this build host. --clear
    # removes the published passwords, certificates and CA, puts the password
    # placeholders back in internal_users.yml, empties the DN settings and
    # drops the build CA from the JVM truststore, so each container resolves
    # its own at start. The keystore %post created is removed too, so no two
    # containers share one: the resolver creates it again at --prestart.
    $INSTALL_DIR/bin/resolve-credentials.sh --clear && \
    rm -f /etc/wazuh-indexer/opensearch.keystore /etc/wazuh-indexer/.wazuh-indexer-keystore && \
    rm -f /wazuh-indexer.rpm && \
    dnf clean all && \
    bash config.sh && \
    ENGINE_DIR="$INSTALL_DIR/engine" && \
    if [ -d "$ENGINE_DIR" ]; then \
    find "$ENGINE_DIR" -type d -exec chmod 750 {} + && \
    find "$ENGINE_DIR" -type f -exec chmod 640 {} + && \
    { [ -f "$ENGINE_DIR/run_engine.sh" ] && chmod 750 "$ENGINE_DIR/run_engine.sh" || true; } && \
    { [ -f "$ENGINE_DIR/bin/wazuh-engine" ] && chmod 750 "$ENGINE_DIR/bin/wazuh-engine" || true; } && \
    { [ -d "$ENGINE_DIR/sockets" ] && chmod 777 "$ENGINE_DIR/sockets" || true; }; \
    fi

################################################################################
# Build stage 1 (the actual Wazuh indexer image):
# Copy wazuh-indexer from builder
# Add entrypoint
################################################################################
FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal

ARG WAZUH_UID=101
ARG WAZUH_GID=101

ENV USER="wazuh-indexer" \
    GROUP="wazuh-indexer" \
    NAME="wazuh-indexer" \
    INSTALL_DIR="/usr/share/wazuh-indexer" 
ENV ENGINE_DIR="$INSTALL_DIR/engine"


COPY config/entrypoint.sh /
COPY config/securityadmin.sh /
COPY config/password-tool.sh /
COPY --from=shared credentials-env.sh password-policy.sh /

# The entrypoint and the tools run as root, so none of them may be writable
# by the service user.
# Only the install directory is copied from the builder, so the tools the
# container runs are installed here: openssl and curl-minimal for the
# credentials resolver and the healthcheck, util-linux for setpriv.
# shadow-utils is only needed to create the account.
RUN dnf install --setopt=install_weak_deps=0 curl-minimal shadow-utils util-linux openssl -y && \
    getent group $GROUP || groupadd -r -g ${WAZUH_GID} $GROUP && \
    useradd --system \
            --uid ${WAZUH_UID} \
            --no-create-home \
            --home-dir $INSTALL_DIR \
            --gid ${WAZUH_GID} \
            --shell /sbin/nologin \
            --comment "$USER user" \
            $USER && \
    dnf remove shadow-utils -y && \
    dnf clean all && \
    chown root:root /entrypoint.sh /securityadmin.sh /password-tool.sh /credentials-env.sh /password-policy.sh && \
    chmod 755 /entrypoint.sh && \
    chmod 700 /securityadmin.sh /password-tool.sh && \
    chmod 644 /credentials-env.sh /password-policy.sh && \
    mkdir -p $INSTALL_DIR && \
    mkdir -p /var/lib/wazuh-indexer && chown ${WAZUH_UID}:${WAZUH_GID} /var/lib/wazuh-indexer && \
    mkdir -p $INSTALL_DIR/logs && chown ${WAZUH_UID}:${WAZUH_GID} $INSTALL_DIR/logs && \
    mkdir -p /run/wazuh-indexer && chown ${WAZUH_UID}:${WAZUH_GID} /run/wazuh-indexer && \
    mkdir -p /var/log/wazuh-indexer && chown ${WAZUH_UID}:${WAZUH_GID} /var/log/wazuh-indexer

COPY --from=builder $INSTALL_DIR $INSTALL_DIR

# COPY keeps the package's ownership of everything below the install
# directory, but not of the directory itself: it gets the package's
# root:wazuh-indexer 750 here. The credentials resolver runs as root and
# trusts only root-owned configuration, which the indexer reads through its
# group, as the package installs /etc/wazuh-indexer. The engine modes are set
# in the builder.
RUN chown root:${WAZUH_GID} $INSTALL_DIR && \
    chmod 750 $INSTALL_DIR && \
    chown root:${WAZUH_GID} $INSTALL_DIR/config && \
    chmod 750 $INSTALL_DIR/config

# Starts as root and drops to wazuh-indexer once the credentials are resolved
WORKDIR $INSTALL_DIR

# Services ports
EXPOSE 9200

ENTRYPOINT ["/entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
CMD ["opensearch"]
