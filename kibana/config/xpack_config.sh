#!/bin/bash

kibana_config_file="/usr/share/kibana/config/kibana.yml"
declare -A CONFIG_MAP=(
  [xpack.apm.ui.enabled]=$XPACK_APM
  [xpack.grokdebugger.enabled]=$XPACK_DEVTOOLS
  [xpack.searchprofiler.enabled]=$XPACK_DEVTOOLS
  [xpack.ml.enabled]=$XPACK_ML
  [xpack.canvas.enabled]=$XPACK_CANVAS
  [xpack.logstash.enabled]=$XPACK_LOGS
  [xpack.infra.enabled]=$XPACK_INFRA
  [xpack.monitoring.enabled]=$XPACK_MONITORING_ENABLED
  [console.enabled]=$XPACK_DEVTOOLS
  [xpack.security.enabled]=$XPACK_SECURITY_ENABLED
  [xpack.reporting.enabled]=$XPACK_REPORTING_ENABLED
  [xpack.spaces.enabled]=$XPACK_SPACES_ENABLED
  [xpack.apm.enabled]=$XPACK_APM_ENABLED
  [xpack.graph.enabled]=$XPACK_GRAPH_ENABLED
)
for i in "${!CONFIG_MAP[@]}"
  do
    if grep -Fq "$i" "$kibana_config_file"; then
      if [ "${CONFIG_MAP[$i]}" != "" ]; then
        sed -i 's/.'"$i"'.*/'"$i"': '"${CONFIG_MAP[$i]}"'/' $kibana_config_file
      fi
    else
      echo "$i: ${CONFIG_MAP[$i]}" >> $kibana_config_file
    fi
  done