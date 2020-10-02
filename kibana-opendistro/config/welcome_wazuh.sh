#!/bin/bash
# Wazuh Docker Copyright (C) 2020 Wazuh Inc. (License GPLv2)

if [[ $CHANGE_WELCOME == "true" ]]
then
    echo "Set Wazuh app as the default landing page"
    echo "server.defaultRoute: /app/wazuh" >> /usr/share/kibana/config/kibana.yml

    echo "Set custom welcome styles"
    cp -f /tmp/custom_welcome/template.js.hbs /usr/share/kibana/src/legacy/ui/ui_render/bootstrap/template.js.hbs
    cp -f /tmp/custom_welcome/light_theme.style.css /usr/share/kibana/optimize/bundles/light_theme.style.css
    cp -f /tmp/custom_welcome/*svg /usr/share/kibana/optimize/bundles/
fi

