#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

if [[ $CHANGE_WELCOME == "true" ]]
then

    rm -rf ./optimize/bundles

    kibana_path="/usr/share/kibana"
    # Set Wazuh app as the default landing page
    echo "Set Wazuh app as the default landing page"
    echo "server.defaultRoute: /app/wazuh" >> $kibana_path/config/kibana.yml

    # Redirect Kibana welcome screen to Discover
    echo "Redirect Kibana welcome screen to Discover"
    sed -i "s:'/app/kibana#/home':'/app/wazuh':g" $kibana_path/src/core/public/chrome/chrome_service.js

    # Hide management undesired links
    echo "Hide management undesired links"
    sed -i 's#visible: true#visible: false#g' $kibana_path/x-pack/legacy/plugins/rollup/public/crud_app/index.js
    sed -i 's#visible: true#visible: false#g' $kibana_path/x-pack/legacy/plugins/license_management/public/management_section.js
    sed -i 's#visible: true#visible: false#g' $kibana_path/x-pack/legacy/plugins/index_lifecycle_management/public/register_management_section.js
    sed -i 's#visible: true#visible: false#g' $kibana_path/x-pack/legacy/plugins/cross_cluster_replication/public/register_routes.js
    sed -i 's#visible: true#visible: false#g' $kibana_path/x-pack/legacy/plugins/remote_clusters/public/index.js
    sed -i 's#visible: true#visible: false#g' $kibana_path/x-pack/legacy/plugins/upgrade_assistant/public/index.js
    sed -i 's#visible: true#visible: false#g' $kibana_path/x-pack/legacy/plugins/snapshot_restore/public/plugin.js
fi

