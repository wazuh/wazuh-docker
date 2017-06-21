FROM centos:latest

COPY config/*.repo /etc/yum.repos.d/

RUN yum -y update; yum clean all;
RUN yum -y install epel-release openssl useradd; yum clean all
RUN yum -y install postfix mailx cyrus-sasl cyrus-sasl-plain; yum clean all
RUN groupadd -g 1000 ossec
RUN useradd -u 1000 -g 1000 ossec
RUN yum install -y wazuh-manager wazuh-api


ADD config/data_dirs.env /data_dirs.env
ADD config/init.bash /init.bash
# Sync calls are due to https://github.com/docker/docker/issues/9547
RUN chmod 755 /init.bash &&\
  sync && /init.bash &&\
  sync && rm /init.bash


RUN  curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.4.2-x86_64.rpm &&\
  rpm -vi filebeat-5.4.2-x86_64.rpm && rm filebeat-5.4.2-x86_64.rpm

COPY config/filebeat.yml /etc/filebeat/

ADD config/run.sh /tmp/run.sh
RUN chmod 755 /tmp/run.sh

VOLUME ["/var/ossec/data"]

EXPOSE 55000/tcp 1514/udp 1515/tcp 514/udp

# Run supervisord so that the container will stay alive

ENTRYPOINT ["/tmp/run.sh"]
