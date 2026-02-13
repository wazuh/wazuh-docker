# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
FROM amazonlinux:2023

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ARG WAZUH_VERSION
ARG WAZUH_TAG_REVISION
ARG S6_VERSION="v2.2.0.3"
ARG TARGETARCH
ARG wazuh_manager_amd64_rpm
ARG wazuh_manager_arm64_rpm

RUN URL_VAR="wazuh_manager_${TARGETARCH}_rpm" && \
    manager_url="${!URL_VAR}" && \
    dnf install curl-minimal xz gnupg tar gzip openssl findutils procps -y &&\
    dnf clean all && \
    curl -o /wazuh-manager.rpm "${manager_url}" && \
    dnf install /wazuh-manager.rpm -y && \
    rm -rf /wazuh-manager.rpm && \
    dnf clean all && \
    S6_ARCH="amd64" && \
    if [ "${TARGETARCH}" = "arm64" ]; then S6_ARCH="aarch64"; fi && \
    curl --fail --silent -L https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${S6_ARCH}.tar.gz \
    -o /tmp/s6-overlay-${S6_ARCH}.tar.gz && \
    tar xzf /tmp/s6-overlay-${S6_ARCH}.tar.gz -C / --exclude="./bin" && \
    tar xzf /tmp/s6-overlay-${S6_ARCH}.tar.gz -C /usr ./bin && \
    rm  /tmp/s6-overlay-${S6_ARCH}.tar.gz && \
    rm -f /var/wazuh-manager/etc/sslmanager.key && \
    rm -f /var/wazuh-manager/etc/sslmanager.cert

COPY config/etc/ /etc/
COPY --chown=root:wazuh config/create_user.py /var/wazuh-manager/framework/scripts/create_user.py
# Prepare permanent data
# Sync calls are due to https://github.com/docker/docker/issues/9547

COPY config/permanent_data.env config/permanent_data.sh /

#Make mount directories for keep permissions

RUN mkdir -p /var/wazuh-manager/var/multigroups && \
    chown root:wazuh /var/wazuh-manager/var/multigroups && \
    chmod 770 /var/wazuh-manager/var/multigroups && \
    mkdir -p /var/wazuh-manager/active-response/bin && \
    chown root:wazuh /var/wazuh-manager/active-response/bin && \
    chmod 770 /var/wazuh-manager/active-response/bin && \
    chmod 755 /permanent_data.sh && \
    sync && /permanent_data.sh && \
    sync && rm /permanent_data.sh

# Services ports
EXPOSE 55000/tcp 1514/tcp 1515/tcp 514/udp 1516/tcp

ENTRYPOINT [ "/init" ]
