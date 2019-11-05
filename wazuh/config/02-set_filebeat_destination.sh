#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

##############################################################################
# Set Filebeat destination.  
##############################################################################

if [[ $FILEBEAT_DESTINATION == "elasticsearch" ]]; then

    echo "FILEBEAT - Set destination to Elasticsearch"
    cp filebeat_to_elasticsearch.yml /etc/filebeat/filebeat.yml
    if [[ $FILEBEAT_OUTPUT != "" ]]; then
        sed -i "s/elasticsearch:9200/$FILEBEAT_OUTPUT:9200/" /etc/filebeat/filebeat.yml
    fi

elif [[ $FILEBEAT_DESTINATION == "logstash" ]]; then

    echo "FILEBEAT - Set destination to Logstash"
    cp filebeat_to_logstash.yml /etc/filebeat/filebeat.yml
    if [[ $FILEBEAT_OUTPUT != "" ]]; then
        sed -i "s/logstash:5000/$FILEBEAT_OUTPUT:5000/" /etc/filebeat/filebeat.yml
    fi

else
    echo "FILEBEAT - Error choosing destination. Set default filebeat.yml "
fi

echo "FILEBEAT - Set permissions"

chmod go-w /etc/filebeat/filebeat.yml