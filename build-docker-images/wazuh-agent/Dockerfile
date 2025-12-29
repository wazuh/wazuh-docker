# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
FROM amazonlinux:2023

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ARG WAZUH_VERSION
ARG WAZUH_TAG_REVISION
ARG S6_VERSION="v2.2.0.3"
ARG WAZUH_MANAGER='CHANGE_MANAGER_IP'
ARG WAZUH_MANAGER_PORT='CHANGE_MANAGER_PORT'
ARG WAZUH_REGISTRATION_SERVER='CHANGE_ENROLL_IP'
ARG WAZUH_REGISTRATION_PORT='CHANGE_ENROLL_PORT'
ARG WAZUH_AGENT_NAME='CHANGE_AGENT_NAME'
ARG TARGETARCH
ARG wazuh_agent_url_amd64_rpm
ARG wazuh_agent_url_arm64_rpm

RUN URL_VAR="wazuh_agent_url_${TARGETARCH}_rpm" && \
    agent_url="${!URL_VAR}" && \
    dnf install curl-minimal tar gzip procps -y &&\
    curl -o /wazuh-agent.rpm "${agent_url}" && \
    dnf install /wazuh-agent.rpm -y && \
    rm -rf /wazuh-agent.rpm && \
    dnf clean all && \
    sed -i '/<authorization_pass_path>/d' /var/ossec/etc/ossec.conf && \
    S6_ARCH="amd64" && \
    if [ "${TARGETARCH}" = "arm64" ]; then S6_ARCH="aarch64"; fi && \
    curl --fail --silent -L https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${S6_ARCH}.tar.gz \
    -o /tmp/s6-overlay-${S6_ARCH}.tar.gz && \
    tar xzf /tmp/s6-overlay-${S6_ARCH}.tar.gz -C / --exclude="./bin" && \
    tar xzf /tmp/s6-overlay-${S6_ARCH}.tar.gz -C /usr ./bin && \
    rm  /tmp/s6-overlay-${S6_ARCH}.tar.gz &&
COPY config/etc/ /etc/

ENTRYPOINT [ "/init" ]
