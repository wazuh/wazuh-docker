# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)
ARG ELASTIC_VERSION=7.2.1
FROM docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}
ARG S3_PLUGIN_URL="https://artifacts.elastic.co/downloads/elasticsearch-plugins/repository-s3/repository-s3-${ELASTIC_VERSION}.zip"
ARG TEMPLATE_VERSION=v3.9.5

ENV ELASTICSEARCH_URL="http://elasticsearch:9200"

ENV API_USER="foo" \
    API_PASS="bar"

ENV XPACK_ML="true" 

ENV ENABLE_CONFIGURE_S3="false"

ENV TEMPLATE_VERSION=v3.9.4


# This CA is created for testing. Please set your own CA zip containing the key and the signed certificate. 
# command: $ docker build <elasticsearch_directory> --build-arg SECURITY_CA_PEM_LOCATION=<CA_PEM_LOCATION> --build-arg SECURITY_CA_KEY_LOCATION=<CA_KEY_LOCATION>
# ENV variables are necessary: SECURITY_CA_PEM, SECURITY_CA_KEY, SECURITY_CA_TRUST, SECURITY_OPENSSL_CONF 
# Example:
# ARG SECURITY_CA_PEM_LOCATION="config/server.TEST-CA-signed.pem"
# ARG SECURITY_CA_KEY_LOCATION="config/server.TEST-CA.key"
# ARG SECURITY_OPENSSL_CONF_LOCATION="config/TEST_openssl.cnf"
# ARG SECURITY_CA_TRUST_LOCATION="config/server.TEST-CA-signed.pem"
ARG SECURITY_CA_PEM_LOCATION=""
ARG SECURITY_CA_KEY_LOCATION=""
ARG SECURITY_OPENSSL_CONF_LOCATION=""
ARG SECURITY_CA_TRUST_LOCATION=""

# Elasticearch cluster configuration environment variables
# If ELASTIC_CLUSTER is set to "true" the following variables will be added to the Elasticsearch configuration
# CLUSTER_INITIAL_MASTER_NODES set to own node by default.
ENV ELASTIC_CLUSTER="false" \
    CLUSTER_NAME="wazuh" \
    CLUSTER_NODE_MASTER="false" \
    CLUSTER_NODE_DATA="true" \
    CLUSTER_NODE_INGEST="true" \
    CLUSTER_NODE_NAME="wazuh-elasticsearch" \
    CLUSTER_MASTER_NODE_NAME="master-node" \
    CLUSTER_MEMORY_LOCK="true" \
    CLUSTER_DISCOVERY_SERVICE="wazuh-elasticsearch" \
    CLUSTER_NUMBER_OF_MASTERS="2" \
    CLUSTER_MAX_NODES="1" \
    CLUSTER_DELAYED_TIMEOUT="1m" \
    CLUSTER_INITIAL_MASTER_NODES="wazuh-elasticsearch"

ADD https://raw.githubusercontent.com/wazuh/wazuh/$TEMPLATE_VERSION/extensions/elasticsearch/6.x/wazuh-template.json /usr/share/elasticsearch/config

# CA cert for Transport SSL
ADD $SECURITY_CA_PEM_LOCATION /usr/share/elasticsearch/config
ADD $SECURITY_CA_KEY_LOCATION /usr/share/elasticsearch/config 
ADD $SECURITY_OPENSSL_CONF_LOCATION /usr/share/elasticsearch/config 
ADD $SECURITY_CA_TRUST_LOCATION /usr/share/elasticsearch/config 

RUN yum install openssl -y

RUN mkdir /entrypoint-scripts

COPY config/entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

COPY --chown=elasticsearch:elasticsearch ./config/load_settings.sh ./

RUN chmod +x ./load_settings.sh

RUN ${bin/elasticsearch-plugin install --batch S3_PLUGIN_URL}

COPY config/configure_s3.sh ./config/configure_s3.sh
RUN chmod 755 ./config/configure_s3.sh

COPY --chown=elasticsearch:elasticsearch ./config/10-config_cluster.sh /entrypoint-scripts/10-config_cluster.sh
RUN chmod +x /entrypoint-scripts/10-config_cluster.sh

COPY --chown=elasticsearch:elasticsearch ./config/20-config_secure.sh /entrypoint-scripts/20-config_secure.sh
RUN chmod +x /entrypoint-scripts/10-config_cluster.sh

COPY --chown=elasticsearch:elasticsearch ./config/30-entrypoint.sh /entrypoint-scripts/30-entrypoint.sh
RUN chmod +x /entrypoint-scripts/30-entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["elasticsearch"]
