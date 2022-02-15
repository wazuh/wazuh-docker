# Wazuh Docker Copyright (C) 2021 Wazuh Inc. (License GPLv2)
FROM ubuntu:focal

RUN apt-get update && apt-get install openssl -y

WORKDIR /

COPY config/unattended_installer.tar.gz /

COPY config/entrypoint.sh /

RUN tar -xzvf /unattended_installer.tar.gz

RUN chmod 700 /entrypoint.sh && chmod -R 700 unattended_installer

ENTRYPOINT ["/entrypoint.sh"]