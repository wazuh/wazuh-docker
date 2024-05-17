#!/usr/bin/env bash
# Wazuh Docker Copyright (C) 2017, Wazuh Inc. (License GPLv2)
set -e

umask 0002

export USER=wazuh-indexer
export INSTALLATION_DIR=/usr/share/wazuh-indexer
export OPENSEARCH_PATH_CONF=${INSTALLATION_DIR}
export CACERT=$(grep -oP "(?<=plugins.security.ssl.transport.pemtrustedcas_filepath: ).*" ${OPENSEARCH_PATH_CONF}/opensearch.yml)
export CERT="${OPENSEARCH_PATH_CONF}/certs/admin.pem"
export KEY="${OPENSEARCH_PATH_CONF}/certs/admin-key.pem"

opensearch_vars=(
    cluster.name
    node.name
    node.roles
    path.data
    path.logs
    bootstrap.memory_lock
    network.host
    http.port
    transport.port
    network.bind_host
    network.publish_host
    transport.tcp.port
    compatibility.override_main_response_version
    http.host
    http.bind_host
    http.publish_host
    http.compression
    transport.host
    transport.bind_host
    transport.publish_host
    discovery.seed_hosts
    discovery.seed_providers
    discovery.type
    cluster.initial_cluster_manager_nodes
    cluster.initial_master_nodes
    node.max_local_storage_nodes
    gateway.recover_after_nodes
    gateway.recover_after_data_nodes
    gateway.expected_data_nodes
    gateway.recover_after_time
    plugins.security.nodes_dn
    plugins.security.nodes_dn_dynamic_config_enabled
    plugins.security.authcz.admin_dn
    plugins.security.roles_mapping_resolution
    plugins.security.dls.mode
    plugins.security.compliance.salt
    config.dynamic.http.anonymous_auth_enabled
    plugins.security.restapi.roles_enabled
    plugins.security.restapi.password_validation_regex
    plugins.security.restapi.password_validation_error_message
    plugins.security.restapi.password_min_length
    plugins.security.restapi.password_score_based_validation_strength
    plugins.security.unsupported.restapi.allow_securityconfig_modification
    plugins.security.authcz.impersonation_dn
    plugins.security.authcz.rest_impersonation_user
    plugins.security.allow_default_init_securityindex
    plugins.security.allow_unsafe_democertificates
    plugins.security.system_indices.permission.enabled
    plugins.security.config_index_name
    plugins.security.cert.oid
    plugins.security.cert.intercluster_request_evaluator_class
    plugins.security.enable_snapshot_restore_privilege
    plugins.security.check_snapshot_restore_write_privileges
    plugins.security.cache.ttl_minutes
    plugins.security.protected_indices.enabled
    plugins.security.protected_indices.roles
    plugins.security.protected_indices.indices
    plugins.security.system_indices.enabled
    plugins.security.system_indices.indices
    plugins.security.audit.enable_rest
    plugins.security.audit.enable_transport
    plugins.security.audit.resolve_bulk_requests
    plugins.security.audit.config.disabled_categories
    plugins.security.audit.ignore_requests
    plugins.security.audit.threadpool.size
    plugins.security.audit.threadpool.max_queue_len
    plugins.security.audit.ignore_users
    plugins.security.audit.type
    plugins.security.audit.config.http_endpoints
    plugins.security.audit.config.index
    plugins.security.audit.config.type
    plugins.security.audit.config.username
    plugins.security.audit.config.password
    plugins.security.audit.config.enable_ssl
    plugins.security.audit.config.verify_hostnames
    plugins.security.audit.config.enable_ssl_client_auth
    plugins.security.audit.config.cert_alias
    plugins.security.audit.config.pemkey_filepath
    plugins.security.audit.config.pemkey_content
    plugins.security.audit.config.pemkey_password
    plugins.security.audit.config.pemcert_filepath
    plugins.security.audit.config.pemcert_content
    plugins.security.audit.config.pemtrustedcas_filepath
    plugins.security.audit.config.pemtrustedcas_content
    plugins.security.audit.config.webhook.url
    plugins.security.audit.config.webhook.format
    plugins.security.audit.config.webhook.ssl.verify
    plugins.security.audit.config.webhook.ssl.pemtrustedcas_filepath
    plugins.security.audit.config.webhook.ssl.pemtrustedcas_content
    plugins.security.audit.config.log4j.logger_name
    plugins.security.audit.config.log4j.level
    opendistro_security.audit.config.disabled_rest_categories
    opendistro_security.audit.config.disabled_transport_categories
    plugins.security.ssl.transport.enforce_hostname_verification
    plugins.security.ssl.transport.resolve_hostname
    plugins.security.ssl.http.clientauth_mode
    plugins.security.ssl.http.enabled_ciphers
    plugins.security.ssl.http.enabled_protocols
    plugins.security.ssl.transport.enabled_ciphers
    plugins.security.ssl.transport.enabled_protocols
    plugins.security.ssl.transport.keystore_type
    plugins.security.ssl.transport.keystore_filepath
    plugins.security.ssl.transport.keystore_alias
    plugins.security.ssl.transport.keystore_password
    plugins.security.ssl.transport.truststore_type
    plugins.security.ssl.transport.truststore_filepath
    plugins.security.ssl.transport.truststore_alias
    plugins.security.ssl.transport.truststore_password
    plugins.security.ssl.http.enabled
    plugins.security.ssl.http.keystore_type
    plugins.security.ssl.http.keystore_filepath
    plugins.security.ssl.http.keystore_alias
    plugins.security.ssl.http.keystore_password
    plugins.security.ssl.http.truststore_type
    plugins.security.ssl.http.truststore_filepath
    plugins.security.ssl.http.truststore_alias
    plugins.security.ssl.http.truststore_password
    plugins.security.ssl.transport.enable_openssl_if_available
    plugins.security.ssl.http.enable_openssl_if_available
    plugins.security.ssl.transport.pemkey_filepath
    plugins.security.ssl.transport.pemkey_password
    plugins.security.ssl.transport.pemcert_filepath
    plugins.security.ssl.transport.pemtrustedcas_filepath
    plugins.security.ssl.http.pemkey_filepath
    plugins.security.ssl.http.pemkey_password
    plugins.security.ssl.http.pemcert_filepath
    plugins.security.ssl.http.pemtrustedcas_filepath
    plugins.security.ssl.transport.enabled
    plugins.security.ssl.transport.client.pemkey_password
    plugins.security.ssl.transport.keystore_keypassword
    plugins.security.ssl.transport.server.keystore_keypassword
    plugins.sercurity.ssl.transport.server.keystore_alias
    plugins.sercurity.ssl.transport.client.keystore_alias
    plugins.sercurity.ssl.transport.server.truststore_alias
    plugins.sercurity.ssl.transport.client.truststore_alias
    plugins.security.ssl.client.external_context_id
    plugins.secuirty.ssl.transport.principal_extractor_class
    plugins.security.ssl.http.crl.file_path
    plugins.security.ssl.http.crl.validate
    plugins.security.ssl.http.crl.prefer_crlfile_over_ocsp
    plugins.security.ssl.http.crl.check_only_end_entitites
    plugins.security.ssl.http.crl.disable_ocsp
    plugins.security.ssl.http.crl.disable_crldp
    plugins.security.ssl.allow_client_initiated_renegotiation
    indices.breaker.total.use_real_memory
    indices.breaker.total.limit
    indices.breaker.fielddata.limit
    indices.breaker.fielddata.overhead
    indices.breaker.request.limit
    indices.breaker.request.overhead
    network.breaker.inflight_requests.limit
    network.breaker.inflight_requests.overhead
    cluster.routing.allocation.enable
    cluster.routing.allocation.node_concurrent_incoming_recoveries
    cluster.routing.allocation.node_concurrent_outgoing_recoveries
    cluster.routing.allocation.node_concurrent_recoveries
    cluster.routing.allocation.node_initial_primaries_recoveries
    cluster.routing.allocation.same_shard.host
    cluster.routing.rebalance.enable
    cluster.routing.allocation.allow_rebalance
    cluster.routing.allocation.cluster_concurrent_rebalance
    cluster.routing.allocation.balance.shard
    cluster.routing.allocation.balance.index
    cluster.routing.allocation.balance.threshold
    cluster.routing.allocation.balance.prefer_primary
    cluster.routing.allocation.disk.threshold_enabled
    cluster.routing.allocation.disk.watermark.low
    cluster.routing.allocation.disk.watermark.high
    cluster.routing.allocation.disk.watermark.flood_stage
    cluster.info.update.interval
    cluster.routing.allocation.shard_movement_strategy
    cluster.blocks.read_only
    cluster.blocks.read_only_allow_delete
    cluster.max_shards_per_node
    cluster.persistent_tasks.allocation.enable
    cluster.persistent_tasks.allocation.recheck_interval
    cluster.search.request.slowlog.threshold.warn
    cluster.search.request.slowlog.threshold.info
    cluster.search.request.slowlog.threshold.debug
    cluster.search.request.slowlog.threshold.trace
    cluster.search.request.slowlog.level
    cluster.fault_detection.leader_check.timeout
    cluster.fault_detection.follower_check.timeout
    action.auto_create_index
    action.destructive_requires_name
    cluster.default.index.refresh_interval
    cluster.minimum.index.refresh_interval
    cluster.indices.close.enable
    indices.recovery.max_bytes_per_sec
    indices.recovery.max_concurrent_file_chunks
    indices.recovery.max_concurrent_operations
    indices.recovery.max_concurrent_remote_store_streams
    indices.time_series_index.default_index_merge_policy
    indices.fielddata.cache.size
    index.number_of_shards
    index.number_of_routing_shards
    index.shard.check_on_startup
    index.codec
    index.codec.compression_level
    index.routing_partition_size
    index.soft_deletes.retention_lease.period
    index.load_fixed_bitset_filters_eagerly
    index.hidden
    index.merge.policy
    index.merge_on_flush.enabled
    index.merge_on_flush.max_full_flush_merge_wait_time
    index.merge_on_flush.policy
    index.check_pending_flush.enabled
    index.number_of_replicas
    index.auto_expand_replicas
    index.search.idle.after
    index.refresh_interval
    index.max_result_window
    index.max_inner_result_window
    index.max_rescore_window
    index.max_docvalue_fields_search
    index.max_script_fields
    index.max_ngram_diff
    index.max_shingle_diff
    index.max_refresh_listeners
    index.analyze.max_token_count
    index.highlight.max_analyzed_offset
    index.max_terms_count
    index.max_regex_length
    index.query.default_field
    index.query.max_nested_depth
    index.routing.allocation.enable
    index.routing.rebalance.enable
    index.gc_deletes
    index.default_pipeline
    index.final_pipeline
    index.optimize_doc_id_lookup.fuzzy_set.enabled
    index.optimize_doc_id_lookup.fuzzy_set.false_positive_probability
    search.max_buckets
    search.phase_took_enabled
    search.allow_expensive_queries
    search.default_allow_partial_results
    search.cancel_after_time_interval
    search.default_search_timeout
    search.default_keep_alive
    search.keep_alive_interval
    search.max_keep_alive
    search.low_level_cancellation
    search.max_open_scroll_context
    search.request_stats_enabled
    search.highlight.term_vector_multi_value
    snapshot.max_concurrent_operations
    cluster.remote_store.translog.buffer_interval
    remote_store.moving_average_window_size
    opensearch.notifications.core.allowed_config_types
    opensearch.notifications.core.email.minimum_header_length
    opensearch.notifications.core.email.size_limit
    opensearch.notifications.core.http.connection_timeout
    opensearch.notifications.core.http.host_deny_list
    opensearch.notifications.core.http.max_connection_per_route
    opensearch.notifications.core.http.max_connections
    opensearch.notifications.core.http.socket_timeout
    opensearch.notifications.core.tooltip_support
    opensearch.notifications.general.filter_by_backend_roles
)

run_as_other_user_if_needed() {
  if [[ "$(id -u)" == "0" ]]; then
    # If running as root, drop to specified UID and run command
    exec chroot --userspec=1000:0 / "${@}"
  else
    # Either we are running in Openshift with random uid and are a member of the root group
    # or with a custom --user
    exec "${@}"
  fi
}

function buildOpensearchConfig {
    echo "" >> $OPENSEARCH_PATH_CONF/opensearch.yml
      for opensearch_var in ${opensearch_vars[*]}; do
        env_var=$(echo ${opensearch_var^^} | tr . _)
        value=${!env_var}
        if [[ -n $value ]]; then
          if grep -q $opensearch_var $OPENSEARCH_PATH_CONF/opensearch.yml; then
            lineNum="$(grep -n "$opensearch_var" $OPENSEARCH_PATH_CONF/opensearch.yml | head -n 1 | cut -d: -f1)"
            sed -i "${lineNum}d" $OPENSEARCH_PATH_CONF/opensearch.yml
            charline=$(awk "NR == ${lineNum}" $OPENSEARCH_PATH_CONF/opensearch.yml | head -c 1)
          fi
          while :
          do
            case "$charline" in
              "-"| "#" |" ") sed -i "${lineNum}d" $OPENSEARCH_PATH_CONF/opensearch.yml;;
              *) break;;
            esac
            charline=$(awk "NR == ${lineNum}" $OPENSEARCH_PATH_CONF/opensearch.yml | head -c 1)
          done
          longoptfile="${opensearch_var}: ${value}"
          if grep -q $opensearch_var $OPENSEARCH_PATH_CONF/opensearch.yml; then
            sed -i "/${opensearch_var}/ s|^.*$|${longoptfile}|" $OPENSEARCH_PATH_CONF/opensearch.yml
          else
            echo $longoptfile >> $OPENSEARCH_PATH_CONF/opensearch.yml
          fi
        fi
      done
}

buildOpensearchConfig

# Allow user specify custom CMD, maybe bin/opensearch itself
# for example to directly specify `-E` style parameters for opensearch on k8s
# or simply to run /bin/bash to check the image
if [[ "$1" != "opensearchwrapper" ]]; then
  if [[ "$(id -u)" == "0" && $(basename "$1") == "opensearch" ]]; then
    # Rewrite CMD args to replace $1 with `opensearch` explicitly,
    # Without this, user could specify `opensearch -E x.y=z` but
    # `bin/opensearch -E x.y=z` would not work.
    set -- "opensearch" "${@:2}"
    # Use chroot to switch to UID 1000 / GID 0
    exec chroot --userspec=1000:0 / "$@"
  else
    # User probably wants to run something else, like /bin/bash, with another uid forced (Openshift?)
    exec "$@"
  fi
fi

# Allow environment variables to be set by creating a file with the
# contents, and setting an environment variable with the suffix _FILE to
# point to it. This can be used to provide secrets to a container, without
# the values being specified explicitly when running the container.
#
# This is also sourced in opensearch-env, and is only needed here
# as well because we use INDEXER_PASSWORD below. Sourcing this script
# is idempotent.
source /usr/share/wazuh-indexer/bin/opensearch-env-from-file

if [[ -f bin/opensearch-users ]]; then
  # Check for the INDEXER_PASSWORD environment variable to set the
  # bootstrap password for Security.
  #
  # This is only required for the first node in a cluster with Security
  # enabled, but we have no way of knowing which node we are yet. We'll just
  # honor the variable if it's present.
  if [[ -n "$INDEXER_PASSWORD" ]]; then
    [[ -f /usr/share/wazuh-indexer/opensearch.keystore ]] || (run_as_other_user_if_needed opensearch-keystore create)
    if ! (run_as_other_user_if_needed opensearch-keystore has-passwd --silent) ; then
      # keystore is unencrypted
      if ! (run_as_other_user_if_needed opensearch-keystore list | grep -q '^bootstrap.password$'); then
        (run_as_other_user_if_needed echo "$INDEXER_PASSWORD" | opensearch-keystore add -x 'bootstrap.password')
      fi
    else
      # keystore requires password
      if ! (run_as_other_user_if_needed echo "$KEYSTORE_PASSWORD" \
          | opensearch-keystore list | grep -q '^bootstrap.password$') ; then
        COMMANDS="$(printf "%s\n%s" "$KEYSTORE_PASSWORD" "$INDEXER_PASSWORD")"
        (run_as_other_user_if_needed echo "$COMMANDS" | opensearch-keystore add -x 'bootstrap.password')
      fi
    fi
  fi
fi

if [[ "$(id -u)" == "0" ]]; then
  # If requested and running as root, mutate the ownership of bind-mounts
  if [[ -n "$TAKE_FILE_OWNERSHIP" ]]; then
    chown -R 1000:0 /usr/share/wazuh-indexer/{data,logs}
  fi
fi


run_as_other_user_if_needed /usr/share/wazuh-indexer/bin/opensearch <<<"$KEYSTORE_PASSWORD"