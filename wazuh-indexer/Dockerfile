FROM ubuntu:focal AS builder

ENV tini_bin="tini-amd64"

RUN apt-get update -y && apt-get install curl -y

RUN curl --retry 8 -S -L -O https://github.com/krallin/tini/releases/download/v0.19.0/${tini_bin}
RUN curl --retry 8 -S -L -O https://github.com/krallin/tini/releases/download/v0.19.0/${tini_bin}.sha256sum
RUN sha256sum -c ${tini_bin}.sha256sum && \
    echo ${tini_bin} \
    rm ${tini_bin}.sha256sum && \
    mv ${tini_bin} /tini && \
    chmod +x /tini
#RUN mkdir /usr/share/wazuh-indexer
#WORKDIR /usr/share/opensearch
#RUN tar zxf /opt/opensearch.tar.gz --strip-components=1
#RUN sed -i -e 's/OPENSEARCH_DISTRIBUTION_TYPE=tar/OPENSEARCH_DISTRIBUTION_TYPE=docker/' /usr/share/opensearch/bin/opensearch-env
#RUN mkdir -p config config/jvm.options.d data logs
#RUN chmod 0775 config config/jvm.options.d data logs
#COPY config/opensearch.yml config/log4j2.properties config/
#RUN chmod 0660 config/opensearch.yml config/log4j2.properties
COPY config/unattended_installer.tar.gz /
COPY config/config.sh .
RUN tar -xzvf /unattended_installer.tar.gz
RUN bash config.sh

################################################################################
# Build stage 1 (the actual OpenSearch image):
#
# Copy opensearch from stage 0
# Add entrypoint
################################################################################
FROM ubuntu:focal

ENV USER="wazuh-indexer" \
    GROUP="wazuh-indexer" \
    NAME="wazuh-indexer" \
    INSTALL_DIR="/usr/share/wazuh-indexer"

RUN getent group $GROUP || groupadd -r -g 1000 $GROUP

RUN useradd --system \
            --uid 1000 \
            --no-create-home \
            --home-dir $INSTALL_DIR \
            --gid $GROUP \
            --shell /sbin/nologin \
            --comment "$USER user" \
            $USER

WORKDIR $INSTALL_DIR

COPY config/entrypoint.sh /

RUN chmod 700 /entrypoint.sh

COPY --from=builder --chown=1000:1000 /debian/wazuh-indexer/usr/share/wazuh-indexer /usr/share/wazuh-indexer
COPY --from=builder --chown=0:0 /tini /tini
COPY --from=builder --chown=0:0 /debian/wazuh-indexer/etc/init.d/wazuh-indexer /etc/init.d/wazuh-indexer
COPY --from=builder --chown=0:0 /debian/wazuh-indexer/usr/lib/systemd /usr/lib/systemd
COPY --from=builder --chown=0:0 /debian/wazuh-indexer/usr/lib/sysctl.d /usr/lib/sysctl.d
COPY --from=builder --chown=0:0 /debian/wazuh-indexer/usr/lib/tmpfiles.d /usr/lib/tmpfiles.d
COPY --from=builder --chown=1000:10000 /debian/wazuh-indexer/etc/wazuh-indexer /etc/wazuh-indexer

RUN mkdir -p /var/lib/wazuh-indexer && chown 1000:1000 /var/lib/wazuh-indexer && \
    mkdir -p /usr/share/wazuh-indexer/logs && chown 1000:1000 /usr/share/wazuh-indexer/logs && \
    mkdir -p /run/wazuh-indexer && chown 1000:1000 /run/wazuh-indexer && \
    mkdir -p /var/log/wazuh-indexer && chown 1000:1000 /var/log/wazuh-indexer

# Services ports
EXPOSE 9700

#ENTRYPOINT [ "/entrypoint.sh" ]

ENTRYPOINT ["/tini", "--", "/entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
CMD ["opensearchwrapper"]