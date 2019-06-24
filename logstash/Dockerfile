# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/logstash/logstash:6.8.0

COPY --chown=logstash:logstash config/entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

RUN rm -f /usr/share/logstash/pipeline/logstash.conf

COPY config/01-wazuh.conf /usr/share/logstash/pipeline/01-wazuh.conf

# This CA is created for testing. Please set your own CA pem signed certificate. 
# command: $ docker build <logstash_directory> --build-arg SECURITY_CA_PEM_LOCATION=<CA_PEM_LOCATION> --build-arg SECURITY_CA_PEM_ARG=<CA_PEM_NAME>
# ENV variables are necessary: SECURITY_CA_PEM 
ARG SECURITY_CA_PEM_LOCATION="config/server.TEST-CA-signed.pem"
ARG SECURITY_CA_PEM_ARG="server.TEST-CA-signed.pem"

# CA for secure communication with Elastic
ADD $SECURITY_CA_PEM_LOCATION /usr/share/logstash/config

RUN mkdir /entrypoint-scripts
COPY --chown=logstash:logstash ./config/10-entrypoint.sh /entrypoint-scripts/10-entrypoint.sh
RUN chmod +x /entrypoint-scripts/10-entrypoint.sh

# Set permissions for CA
USER root
RUN chown logstash: /usr/share/logstash/config/$SECURITY_CA_PEM_ARG
RUN chmod 440 /usr/share/logstash/config/$SECURITY_CA_PEM_ARG
USER logstash

ENTRYPOINT /entrypoint.sh
