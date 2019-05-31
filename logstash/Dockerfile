# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/logstash/logstash:6.8.0

COPY --chown=logstash:logstash config/entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

RUN rm -f /usr/share/logstash/pipeline/logstash.conf

COPY config/01-wazuh.conf /usr/share/logstash/pipeline/01-wazuh.conf

# CA for secure communication with Elastic
ADD https://raw.githubusercontent.com/SitoRBJ/test-ca/master/server.CA-signed.crt /usr/share/logstash/config

ENTRYPOINT /entrypoint.sh
