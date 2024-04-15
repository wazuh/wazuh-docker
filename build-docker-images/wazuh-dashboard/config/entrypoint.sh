#!/bin/bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)

INSTALL_DIR=/usr/share/wazuh-dashboard
DASHBOARD_USERNAME="${DASHBOARD_USERNAME:-kibanaserver}"
DASHBOARD_PASSWORD="${DASHBOARD_PASSWORD:-kibanaserver}"

# Create and configure Wazuh dashboard keystore

yes | $INSTALL_DIR/bin/opensearch-dashboards-keystore create --allow-root && \
echo $DASHBOARD_USERNAME | $INSTALL_DIR/bin/opensearch-dashboards-keystore add opensearch.username --stdin --allow-root && \
echo $DASHBOARD_PASSWORD | $INSTALL_DIR/bin/opensearch-dashboards-keystore add opensearch.password --stdin --allow-root

##############################################################################
# Start Wazuh dashboard
##############################################################################

/wazuh_app_config.sh $WAZUH_UI_REVISION

export OPENSEARCH_DASHBOARDS_HOME=/usr/share/wazuh-dashboard

opensearch_dashboards_vars=(
    console.enabled
    console.proxyConfig
    console.proxyFilter
    ops.cGroupOverrides.cpuPath
    ops.cGroupOverrides.cpuAcctPath
    cpu.cgroup.path.override
    cpuacct.cgroup.path.override
    server.basePath
    server.customResponseHeaders
    server.compression.enabled
    server.compression.referrerWhitelist
    server.cors
    server.cors.origin
    server.defaultRoute
    server.host
    server.keepAliveTimeout
    server.maxPayloadBytes
    server.name
    server.port
    csp.rules
    csp.strict
    csp.warnLegacyBrowsers
    data.search.usageTelemetry.enabled
    opensearch.customHeaders
    opensearch.hosts
    opensearch.logQueries
    opensearch.memoryCircuitBreaker.enabled
    opensearch.memoryCircuitBreaker.maxPercentage
    opensearch.password
    opensearch.pingTimeout
    opensearch.requestHeadersWhitelist
    opensearch.requestHeadersAllowlist
    opensearch_security.multitenancy.enabled
    opensearch_security.readonly_mode.roles
    opensearch.requestTimeout
    opensearch.shardTimeout
    opensearch.sniffInterval
    opensearch.sniffOnConnectionFault
    opensearch.sniffOnStart
    opensearch.ssl.alwaysPresentCertificate
    opensearch.ssl.certificate
    opensearch.ssl.certificateAuthorities
    opensearch.ssl.key
    opensearch.ssl.keyPassphrase
    opensearch.ssl.keystore.path
    opensearch.ssl.keystore.password
    opensearch.ssl.truststore.path
    opensearch.ssl.truststore.password
    opensearch.ssl.verificationMode
    opensearch.username
    i18n.locale
    interpreter.enableInVisualize
    opensearchDashboards.autocompleteTerminateAfter
    opensearchDashboards.autocompleteTimeout
    opensearchDashboards.defaultAppId
    opensearchDashboards.index
    logging.dest
    logging.json
    logging.quiet
    logging.rotate.enabled
    logging.rotate.everyBytes
    logging.rotate.keepFiles
    logging.rotate.pollingInterval
    logging.rotate.usePolling
    logging.silent
    logging.useUTC
    logging.verbose
    map.includeOpenSearchMapsService
    map.proxyOpenSearchMapsServiceInMaps
    map.regionmap
    map.tilemap.options.attribution
    map.tilemap.options.maxZoom
    map.tilemap.options.minZoom
    map.tilemap.options.subdomains
    map.tilemap.url
    monitoring.cluster_alerts.email_notifications.email_address
    monitoring.enabled
    monitoring.opensearchDashboards.collection.enabled
    monitoring.opensearchDashboards.collection.interval
    monitoring.ui.container.opensearch.enabled
    monitoring.ui.container.logstash.enabled
    monitoring.ui.opensearch.password
    monitoring.ui.opensearch.pingTimeout
    monitoring.ui.opensearch.hosts
    monitoring.ui.opensearch.username
    monitoring.ui.opensearch.logFetchCount
    monitoring.ui.opensearch.ssl.certificateAuthorities
    monitoring.ui.opensearch.ssl.verificationMode
    monitoring.ui.enabled
    monitoring.ui.max_bucket_size
    monitoring.ui.min_interval_seconds
    newsfeed.enabled
    ops.interval
    path.data
    pid.file
    regionmap
    security.showInsecureClusterWarning
    server.rewriteBasePath
    server.socketTimeout
    server.customResponseHeaders
    server.ssl.enabled
    server.ssl.key
    server.ssl.keyPassphrase
    server.ssl.keystore.path
    server.ssl.keystore.password
    server.ssl.truststore.path
    server.ssl.truststore.password
    server.ssl.cert
    server.ssl.certificate
    server.ssl.certificateAuthorities
    server.ssl.cipherSuites
    server.ssl.clientAuthentication
    server.ssl.redirectHttpFromPort
    server.ssl.supportedProtocols
    server.xsrf.disableProtection
    server.xsrf.whitelist
    status.allowAnonymous
    status.v6ApiFormat
    tilemap.options.attribution
    tilemap.options.maxZoom
    tilemap.options.minZoom
    tilemap.options.subdomains
    tilemap.url
    timeline.enabled
    vega.enableExternalUrls
    apm_oss.apmAgentConfigurationIndex
    apm_oss.indexPattern
    apm_oss.errorIndices
    apm_oss.onboardingIndices
    apm_oss.spanIndices
    apm_oss.sourcemapIndices
    apm_oss.transactionIndices
    apm_oss.metricsIndices
    telemetry.allowChangingOptInStatus
    telemetry.enabled
    telemetry.optIn
    telemetry.optInStatusUrl
    telemetry.sendUsageFrom
    vis_builder.enabled
    data_source.enabled
    data_source.encryption.wrappingKeyName
    data_source.encryption.wrappingKeyNamespace
    data_source.encryption.wrappingKey
    data_source.audit.enabled
    data_source.audit.appender.kind
    data_source.audit.appender.path
    data_source.audit.appender.layout.kind
    data_source.audit.appender.layout.highlight
    data_source.audit.appender.layout.pattern
    ml_commons_dashboards.enabled
    assistant.chat.enabled
    observability.query_assist.enabled
    uiSettings.overrides.defaultRoute
)
function runOpensearchDashboards {
    longopts=()
    if [ ! -f $OPENSEARCH_DASHBOARDS_HOME/config/opensearch_dashboards.yml ]; then
        touch $OPENSEARCH_DASHBOARDS_HOME/config/opensearch_dashboards.yml
        for opensearch_dashboards_var in ${opensearch_dashboards_vars[*]}; do
            # 'opensearch.hosts' -> 'OPENSEARCH_URL'
            env_var=$(echo ${opensearch_dashboards_var^^} | tr . _)
            # Indirectly lookup env var values via the name of the var.
            # REF: http://tldp.org/LDP/abs/html/bashver2.html#EX78
            value=${!env_var}
            if [[ -n $value ]]; then
                longopt="--${opensearch_dashboards_var}=${value}"
                longopts+=("${longopt}")
                echo $longopt | sed 's/--//' >> $OPENSEARCH_DASHBOARDS_HOME/config/opensearch_dashboards.yml
                cat $OPENSEARCH_DASHBOARDS_HOME/config/opensearch_dashboards.yml
            fi
        done
    fi

    /usr/share/wazuh-dashboard/bin/opensearch-dashboards -c /usr/share/wazuh-dashboard/config/opensearch_dashboards.yml "${longopts[@]}"
}

runOpensearchDashboards

