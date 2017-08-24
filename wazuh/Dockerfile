FROM centos:latest
ARG FILEBEAT_VERSION=5.5.1
COPY config/*.repo /etc/yum.repos.d/

RUN yum -y update; yum clean all;
RUN yum -y install epel-release openssl useradd which; yum clean all
RUN yum -y install postfix mailx cyrus-sasl cyrus-sasl-plain; yum clean all
RUN groupadd -g 1000 ossec
RUN useradd -u 1000 -g 1000 ossec
RUN curl --silent --location https://rpm.nodesource.com/setup_6.x | bash - &&\
    yum install -y nodejs
RUN yum install -y wazuh-manager wazuh-api


ADD config/data_dirs.env /data_dirs.env
ADD config/init.bash /init.bash
# Sync calls are due to https://github.com/docker/docker/issues/9547
RUN chmod 755 /init.bash &&\
  sync && /init.bash &&\
  sync && rm /init.bash


RUN  curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-x86_64.rpm &&\
  rpm -vi filebeat-${FILEBEAT_VERSION}-x86_64.rpm && rm filebeat-${FILEBEAT_VERSION}-x86_64.rpm

COPY config/filebeat.yml /etc/filebeat/

ADD config/run.sh /tmp/run.sh
RUN chmod 755 /tmp/run.sh

VOLUME ["/var/ossec/data"]

EXPOSE 55000/tcp 1514/udp 1515/tcp 514/udp

# Run supervisord so that the container will stay alive

ENTRYPOINT ["/tmp/run.sh"]
