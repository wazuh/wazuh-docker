#!/bin/bash
# Wazuh App Copyright (C) 2019 Wazuh Inc. (License GPLv2)

elastic_config_file="/usr/share/elasticsearch/config/elasticsearch.yml"


##############################################################################
# Setup bootstrap password to chagne all Elastic Stack passwords.
# Set xpack.security.enabled to true. In Elastic 7 must add ssl options
##############################################################################

if [[ $SETUP_PASSWORDS == "yes" ]]; then

  echo "
# Required to set the passwords
xpack.security.enabled: true
" >> $elastic_config_file

  printf ${BOOTSTRAP_PASS} | /usr/share/elasticsearch/bin/elasticsearch-keystore add "bootstrap.password"

fi

