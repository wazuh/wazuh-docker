# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
FROM amazonlinux:2023 AS builder

ARG WAZUH_VERSION
ARG WAZUH_TAG_REVISION
ARG TARGETARCH
ARG wazuh_indexer_url_amd64_rpm
ARG wazuh_indexer_url_arm64_rpm
ARG wazuh_cert_tool
ARG wazuh_config_yml

COPY config/config.sh .

RUN URL_VAR="wazuh_indexer_url_${TARGETARCH}_rpm" && \
    indexer_url="${!URL_VAR}" && \
    dnf install curl-minimal openssl xz tar findutils shadow-utils -y &&\
    curl -o /wazuh-indexer.rpm "${indexer_url}" && \
    dnf install /wazuh-indexer.rpm -y && \
    rm -rf /wazuh-indexer.rpm && \
    dnf clean all && \
    bash config.sh

################################################################################
# Build stage 1 (the actual Wazuh indexer image):
#
# Copy wazuh-indexer from stage 0
# Add entrypoint
################################################################################
FROM amazonlinux:2023

ENV USER="wazuh-indexer" \
    GROUP="wazuh-indexer" \
    NAME="wazuh-indexer" \
    INSTALL_DIR="/usr/share/wazuh-indexer"


COPY config/entrypoint.sh /
COPY config/securityadmin.sh /

RUN yum install curl-minimal shadow-utils findutils hostname -y && \
    yum clean all && \
    getent group $GROUP || groupadd -r -g 1000 $GROUP && \
    useradd --system \
            --uid 1000 \
            --no-create-home \
            --home-dir $INSTALL_DIR \
            --gid $GROUP \
            --shell /sbin/nologin \
            --comment "$USER user" \
            $USER && \
    chmod 700 /entrypoint.sh && chmod 700 /securityadmin.sh && \
    mkdir -p $INSTALL_DIR && \
    chown 1000:1000 $INSTALL_DIR && \
    chown 1000:1000 /*.sh && \
    mkdir -p /var/lib/wazuh-indexer && chown 1000:1000 /var/lib/wazuh-indexer && \
    mkdir -p $INSTALL_DIR/logs && chown 1000:1000 $INSTALL_DIR/logs && \
    mkdir -p /run/wazuh-indexer && chown 1000:1000 /run/wazuh-indexer && \
    mkdir -p /var/log/wazuh-indexer && chown 1000:1000 /var/log/wazuh-indexer    

COPY --from=builder --chown=1000:1000 $INSTALL_DIR $INSTALL_DIR

RUN chmod 700 $INSTALL_DIR && \
    chmod 700 $INSTALL_DIR/config && \
    chmod 600 $INSTALL_DIR/config/jvm.options && \
    chmod 600 $INSTALL_DIR/config/opensearch.yml

USER wazuh-indexer
WORKDIR $INSTALL_DIR

# Services ports
EXPOSE 9200

ENTRYPOINT ["/entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
CMD ["opensearch"]