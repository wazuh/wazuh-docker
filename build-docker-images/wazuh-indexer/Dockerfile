# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
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
    dnf install curl-minimal openssl xz tar findutils shadow-utils cpio -y &&\
    curl --fail --proto '=https' -o /wazuh-indexer.rpm "${indexer_url}" && \
    bash /verify-package-signature.sh /wazuh-indexer.rpm && \
    dnf install /wazuh-indexer.rpm -y && \
    # The package's %post resolved credentials for this build host. --clear
    # removes the published keys, certificates and CA, but not the password
    # digests it wrote into internal_users.yml or the DNs in opensearch.yml:
    # both files are restored from the package, and the build CA is dropped
    # from the JVM truststore, so each container resolves its own at start.
    $INSTALL_DIR/bin/resolve-credentials.sh --clear && \
    (cd / && rpm2cpio /wazuh-indexer.rpm | cpio -idu --quiet \
        ./etc/wazuh-indexer/opensearch-security/internal_users.yml \
        ./etc/wazuh-indexer/opensearch.yml) && \
    chown $USER:$GROUP /etc/wazuh-indexer/opensearch-security/internal_users.yml /etc/wazuh-indexer/opensearch.yml && \
    chmod 640 /etc/wazuh-indexer/opensearch-security/internal_users.yml && \
    chmod 660 /etc/wazuh-indexer/opensearch.yml && \
    if $INSTALL_DIR/jdk/bin/keytool -list -cacerts -storepass changeit -alias wazuh-root-ca >/dev/null 2>&1; then \
        $INSTALL_DIR/jdk/bin/keytool -delete -cacerts -storepass changeit -alias wazuh-root-ca; \
    fi && \
    rm -rf /etc/wazuh /wazuh-indexer.rpm && \
    dnf clean all && \
    bash config.sh

################################################################################
# Build stage 1 (the actual Wazuh indexer image):
# Copy wazuh-indexer from builder
# Add entrypoint
################################################################################
FROM amazonlinux:2023

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
COPY config/install-credentials.sh /

# The entrypoint and the tools run as root, so none of them may be writable
# by the service user.
# Only the install directory is copied from the builder, so the runtime
# dependencies the package declares are installed here. coreutils is provided
# by the base image's coreutils-single.
RUN yum install curl-minimal shadow-utils findutils hostname util-linux openssl \
        diffutils iproute procps-ng -y && \
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
    chown root:root /entrypoint.sh /securityadmin.sh /password-tool.sh /install-credentials.sh && \
    chmod 755 /entrypoint.sh && \
    chmod 700 /securityadmin.sh /password-tool.sh /install-credentials.sh && \
    mkdir -p $INSTALL_DIR && \
    mkdir -p /var/lib/wazuh-indexer && chown ${WAZUH_UID}:${WAZUH_GID} /var/lib/wazuh-indexer && \
    mkdir -p $INSTALL_DIR/logs && chown ${WAZUH_UID}:${WAZUH_GID} $INSTALL_DIR/logs && \
    mkdir -p /run/wazuh-indexer && chown ${WAZUH_UID}:${WAZUH_GID} /run/wazuh-indexer && \
    mkdir -p /var/log/wazuh-indexer && chown ${WAZUH_UID}:${WAZUH_GID} /var/log/wazuh-indexer

COPY --from=builder $INSTALL_DIR $INSTALL_DIR

# COPY keeps the package's ownership of everything below the install
# directory, but not of the directory itself: it gets the package's
# root:wazuh-indexer 750 here. The credentials resolver runs as root, so
# nothing it runs may belong to the service user.
RUN chown root:${WAZUH_GID} $INSTALL_DIR && \
    chmod 750 $INSTALL_DIR && \
    chmod 700 $INSTALL_DIR/config && \
    chmod 600 $INSTALL_DIR/config/jvm.options && \
    chmod 600 $INSTALL_DIR/config/opensearch.yml && \
    if [ -d "$ENGINE_DIR" ]; then \
    find "$ENGINE_DIR" -type d -exec chmod 750 {} + && \
    find "$ENGINE_DIR" -type f -exec chmod 640 {} + && \
    { [ -f "$ENGINE_DIR/run_engine.sh" ] && chmod 750 "$ENGINE_DIR/run_engine.sh" || true; } && \
    { [ -f "$ENGINE_DIR/bin/wazuh-engine" ] && chmod 750 "$ENGINE_DIR/bin/wazuh-engine" || true; } && \
    { [ -d "$ENGINE_DIR/sockets" ] && chmod 777 "$ENGINE_DIR/sockets" || true; }; \
    fi

# Starts as root and drops to wazuh-indexer once the credentials are resolved
WORKDIR $INSTALL_DIR

# Services ports
EXPOSE 9200

ENTRYPOINT ["/entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
CMD ["opensearch"]
