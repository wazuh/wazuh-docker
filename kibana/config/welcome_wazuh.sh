#!/bin/bash

if [[ $CHANGE_WELCOME == "true" ]]
then

    kibana_path="/usr/share/kibana"
    # Set Wazuh app as the default landing page
    echo "Set Wazuh app as the default landing page"
    echo "server.defaultRoute: /app/wazuh" >> /etc/kibana/kibana.yml

    # Redirect Kibana welcome screen to Discover
    echo "Redirect Kibana welcome screen to Discover"
    sed -i "s:'/app/kibana#/home':'/app/kibana#/discover':g" $kibana_path/src/ui/public/chrome/directives/global_nav/global_nav.html
    sed -i "s:'/app/kibana#/home':'/app/kibana#/discover':g" $kibana_path/src/ui/public/chrome/directives/header_global_nav/header_global_nav.js
fi
