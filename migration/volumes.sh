#!/bin/bash 
# Copyright (C) 2019, Wazuh Inc.

# Script to update old environments containing /var/ossec/data with symbolic links the new structure

wazuh_path=/var/ossec/
data_path=/var/ossec/data/
wazuh_dirs=(api/configuration etc logs queue var/multigroups active-response/bin integrations)
no_wazuh_dirs=(/etc/filebeat)

wazuh_preserve_links=(/var/ossec/api/configuration/auth/htpasswd /var/ossec/etc/ossec-init.conf)
wazuh_files=(/var/ossec/queue/agents-timestamp)
filebeat_files=(/var/lib/filebeat/registry /var/lib/filebeat/meta.json)
postfix_files=(/etc/postfix/dynamicmaps.cf /etc/postfix/main.cf /etc/postfix/main.cf.proto /etc/postfix/master.cf /etc/postfix/master.cf.proto /etc/postfix/postfix-files /etc/postfix/sasl /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db /etc/postfix/postfix-script /etc/postfix/post-install)

for dir in "${wazuh_dirs[@]}"; do
  if [ ! -e $data_path"wazuh"$wazuh_path$dir ]
  then
    mkdir -p $data_path"wazuh"$wazuh_path$dir
  fi
  echo "Copying $wazuh_path$dir to $data_path"wazuh"$wazuh_path$dir"
  cp -LR --preserve=all $wazuh_path$dir/* $data_path"wazuh"$wazuh_path$dir
done

for dir in "${no_wazuh_dirs[@]}"; do
  base=$(basename $dir)
  if [ ! -e $data_path$base$dir ]
  then
    mkdir -p $data_path$base$dir
  fi
  echo "Copying $dir to $data_path$base$dir"
  cp -a $dir/* $data_path$base$dir
done


for file in "${wazuh_files[@]}"; do
  echo "Copying $file to $data_path"wazuh"$file"
  cp -LR --preserve=all $file $data_path"wazuh"$file
done

echo ">> Checking filebeat files" 
mkdir -p $data_path"filebeat/var/lib/filebeat"

for file in "${filebeat_files[@]}"; do
  if [[ -e $file ]]; then
    if [[ -d $file ]]; then
        mkdir -p $data_path"filebeat"$file
        echo "Copying $file to $data_path"filebeat"$file"
        cp -a $file/* $data_path"filebeat"$file
    else
        echo "Copying $file to $data_path"filebeat"$file"
        cp -a $file $data_path"filebeat"$file
    fi
  fi
done

echo ">> Checking postfix files"
mkdir -p $data_path"postfix/etc/postfix"

for file in "${postfix_files[@]}"; do
  if [[ -e $file ]]; then
    if [[ -d $file ]]; then
        mkdir -p $data_path"postfix"$file
        echo "Copying $file to $data_path"postfix"$file"
        cp -a $file/* $data_path"postfix"$file
    else
        echo "Copying $file to $data_path"postfix"$file"
        cp -a $file $data_path"postfix"$file
    fi
  fi
done

echo ">> Preserving Wazuh symbolic links files"
for file in "${wazuh_preserve_links[@]}"; do
  rm  $wazuh_path"data/wazuh"$file
  cp -a $file $wazuh_path"data/wazuh"$file
done

# Grant proper permissions

chmod 750 /var/ossec/data/wazuh/var/ossec/api/configuration
chown root:ossec /var/ossec/data/wazuh/var/ossec/api/configuration
chmod 750 /var/ossec/data/wazuh/var/ossec/api/configuration/auth
chmod 740 /var/ossec/data/wazuh/var/ossec/api/configuration/config.js
chmod 750 /var/ossec/data/wazuh/var/ossec/api/configuration/preloaded_vars.conf
chmod 750 /var/ossec/data/wazuh/var/ossec/api/configuration/ssl
chmod 400 /var/ossec/data/wazuh/var/ossec/api/configuration/ssl/server.crt
chmod 400 /var/ossec/data/wazuh/var/ossec/api/configuration/ssl/server.key
chmod 770 /var/ossec/data/wazuh/var/ossec/etc
chown ossec:ossec /var/ossec/data/wazuh/var/ossec/etc
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/client.keys
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/decoders/local_decoder.xml
chown root:ossec /var/ossec/data/wazuh/var/ossec/etc/decoders/local_decoder.xml
chmod 660 /var/ossec/data/wazuh/var/ossec/etc/lists/amazon/aws-sources.cdb
chown ossec:ossec /var/ossec/data/wazuh/var/ossec/etc/lists/amazon/aws-sources.cdb
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/lists/audit-keys
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/lists/audit-keys.cdb
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/lists/security-eventchannel
chmod 640 /var/ossec/data/wazuh//var/ossec/etc/lists/security-eventchannel.cdb
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/local_internal_options.conf
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/localtime
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/ossec.conf
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/rules/local_rules.xml
chown root:ossec /var/ossec/data/wazuh/var/ossec/etc/rules/local_rules.xml
chown root:ossec /var/ossec/data/wazuh/var/ossec/etc/shared/default/agent.conf
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/sslmanager.cert
chmod 640 /var/ossec/data/wazuh/var/ossec/etc/sslmanager.key
chmod 770 /var/ossec/data/wazuh/var/ossec/logs
chown ossec:ossec /var/ossec/data/wazuh/var/ossec/logs
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/alerts
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/alerts/2019
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/alerts/2019/May
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/api
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/archives
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/archives/2019
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/archives/2019/May
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/cluster
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/firewall
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/firewall/2019
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/firewall/2019/May
chmod 640 /var/ossec/data/wazuh/var/ossec/logs/integrations.log
chmod 750 /var/ossec/data/wazuh/var/ossec/logs/ossec
chmod 750 /var/ossec/data/wazuh/var/ossec/queue
chown root:ossec /var/ossec/data/wazuh/var/ossec/queue
chmod 750 /var/ossec/data/wazuh/var/ossec/queue/agentless
chmod 600 /var/ossec/data/wazuh/var/ossec/queue/agents-timestamp
chmod 750 /var/ossec/data/wazuh/var/ossec/queue/db 
chmod 640 /var/ossec/data/wazuh/var/ossec/queue/db/000.db
chmod 640 /var/ossec/data/wazuh/var/ossec/queue/db/000.db-shm
chmod 640 /var/ossec/data/wazuh/var/ossec/queue/db/000.db-wal
chmod 750 /var/ossec/data/wazuh/var/ossec/queue/fts
chmod 640 /var/ossec/data/wazuh/var/ossec/queue/fts/fts-queue
chmod 640 /var/ossec/data/wazuh/var/ossec/queue/fts/hostinfo
chmod 640 /var/ossec/data/wazuh/var/ossec/queue/fts/ig-queue
chmod 644 /var/ossec/data/wazuh/var/ossec/queue/rids/sender_counter
chmod 750 /var/ossec/data/wazuh/var/ossec/queue/rootcheck
chmod 770 /var/ossec/data/wazuh/var/ossec/var/multigroups
chown root:ossec /var/ossec/data/wazuh/var/ossec/var/multigroups