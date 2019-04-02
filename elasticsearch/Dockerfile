# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/elasticsearch/elasticsearch:6.7.0

ENV ALERTS_SHARDS="1" \
    ALERTS_REPLICAS="0"

ENV API_USER="foo" \
    API_PASS="bar"

ENV XPACK_ML="true" 

ENV ENABLE_CONFIGURE_S3="false"

ENV TEMPLATE_VERSION=v3.8.2

ADD https://raw.githubusercontent.com/wazuh/wazuh/$TEMPLATE_VERSION/extensions/elasticsearch/wazuh-elastic6-template-alerts.json /usr/share/elasticsearch/config

COPY config/entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

COPY --chown=elasticsearch:elasticsearch ./config/load_settings.sh ./

RUN chmod +x ./load_settings.sh

RUN bin/elasticsearch-plugin install --batch https://artifacts.elastic.co/downloads/elasticsearch-plugins/repository-s3/repository-s3-6.7.0.zip

COPY config/configure_s3.sh ./config/configure_s3.sh
RUN chmod 755 ./config/configure_s3.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["elasticsearch"]
