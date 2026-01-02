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
ARG WAZUH_AGENT_GROUPS='CHANGE_AGENT_GROUPS'
ARG TARGETARCH

COPY config/check_repository.sh /

RUN yum install curl-minimal tar gzip procps -y &&\
    yum clean all

RUN chmod 775 /check_repository.sh
RUN source /check_repository.sh

RUN yum install wazuh-agent-${WAZUH_VERSION}-${WAZUH_TAG_REVISION} -y && \
    yum clean all && \
    sed -i '/<authorization_pass_path>/d' /var/ossec/etc/ossec.conf && \
    S6_ARCH="amd64" && \
    if [ "${TARGETARCH}" = "arm64" ]; then S6_ARCH="aarch64"; fi && \
    curl --fail --silent -L https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${S6_ARCH}.tar.gz \
    -o /tmp/s6-overlay-${S6_ARCH}.tar.gz && \
    tar xzf /tmp/s6-overlay-${S6_ARCH}.tar.gz -C / --exclude="./bin" && \
    tar xzf /tmp/s6-overlay-${S6_ARCH}.tar.gz -C /usr ./bin && \
    rm  /tmp/s6-overlay-${S6_ARCH}.tar.gz

COPY config/etc/ /etc/

RUN rm /etc/yum.repos.d/wazuh.repo

ENTRYPOINT [ "/init" ]
