# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
FROM ubuntu:focal

RUN apt-get update && apt-get install openssl curl -y

WORKDIR /

COPY config/entrypoint.sh /

RUN chmod 700 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]