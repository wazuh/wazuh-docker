# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)
FROM ubuntu:focal

RUN apt-get update && apt-get install openssl curl -y

WORKDIR /

#RUN curl -o wazuh-cert-tool.sh https://s3.us-west-1.amazonaws.com/packages.wazuh.com/4.x/wazuh-cert-tool.sh

COPY config/entrypoint.sh /

RUN chmod 700 /entrypoint.sh && chmod 700 /wazuh-cert-tool.sh

ENTRYPOINT ["/entrypoint.sh"]