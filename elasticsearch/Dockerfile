# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)
FROM docker.elastic.co/elasticsearch/elasticsearch:6.8.0

ENV ELASTICSEARCH_URL="http://elasticsearch:9200"

ENV ALERTS_SHARDS="1" \
    ALERTS_REPLICAS="0"

ENV API_USER="foo" \
    API_PASS="bar"

ENV XPACK_ML="true" 

ENV ENABLE_CONFIGURE_S3="false"

ENV TEMPLATE_VERSION=v3.9.2

# Elasticearch cluster configuration environment variables
# If ELASTIC_CLUSTER is set to "true" the following variables will be added to the Elasticsearch configuration
ENV ELASTIC_CLUSTER="false" \
    CLUSTER_NAME="wazuh" \
    CLUSTER_NODE_MASTER="true" \
    CLUSTER_NODE_DATA="true" \
    CLUSTER_NODE_INGEST="true" \
    CLUSTER_NODE_NAME="wazuh-elasticsearch" \
    CLUSTER_MEMORY_LOCK="true" \
    CLUSTER_DISCOVERY_SERVICE="wazuh-elasticsearch" \
    CLUSTER_NUMBER_OF_MASTERS="2" \
    CLUSTER_MAX_NODES="1" \
    CLUSTER_DELAYED_TIMEOUT="1m"

ADD https://raw.githubusercontent.com/wazuh/wazuh/$TEMPLATE_VERSION/extensions/elasticsearch/6.x/wazuh-template.json /usr/share/elasticsearch/config

COPY config/entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

COPY --chown=elasticsearch:elasticsearch ./config/load_settings.sh ./

RUN chmod +x ./load_settings.sh

RUN bin/elasticsearch-plugin install --batch https://artifacts.elastic.co/downloads/elasticsearch-plugins/repository-s3/repository-s3-6.8.0.zip

COPY config/configure_s3.sh ./config/configure_s3.sh
RUN chmod 755 ./config/configure_s3.sh

COPY --chown=elasticsearch:elasticsearch ./config/config_cluster.sh ./
RUN chmod +x ./config_cluster.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["elasticsearch"]
