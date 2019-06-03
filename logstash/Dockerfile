# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/logstash/logstash:6.8.0

COPY --chown=logstash:logstash config/entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

RUN rm -f /usr/share/logstash/pipeline/logstash.conf

COPY config/01-wazuh.conf /usr/share/logstash/pipeline/01-wazuh.conf

# CA for secure communication with Elastic
ADD https://raw.githubusercontent.com/SitoRBJ/test-ca/master/server.CA-signed.pem /usr/share/logstash/config

# Set permissions for CA
USER root
RUN chown logstash: /usr/share/logstash/config/server.CA-signed.pem
RUN chmod 774 /usr/share/logstash/config/server.CA-signed.pem
USER logstash

ENTRYPOINT /entrypoint.sh
