#!/bin/bash

kibana_config_file="/usr/share/kibana/config/kibana.yml"
if grep -Fq  "#xpack features" "$kibana_config_file";
then 
  declare -A CONFIG_MAP=(
    [xpack.apm.ui.enabled]=$XPACK_APM
    [xpack.grokdebugger.enabled]=$XPACK_DEVTOOLS
    [xpack.searchprofiler.enabled]=$XPACK_DEVTOOLS
    [xpack.ml.enabled]=$XPACK_ML
    [xpack.canvas.enabled]=$XPACK_CANVAS
    [xpack.logstash.enabled]=$XPACK_LOGS
    [xpack.infra.enabled]=$XPACK_INFRA
    [xpack.monitoring.enabled]=$XPACK_MONITORING
    [console.enabled]=$XPACK_DEVTOOLS
  )
  for i in "${!CONFIG_MAP[@]}"
  do
    if [ "${CONFIG_MAP[$i]}" != "" ]; then
      sed -i 's/.'"$i"'.*/'"$i"': '"${CONFIG_MAP[$i]}"'/' $kibana_config_file
    fi
  done
else
  echo "
#xpack features
xpack.apm.ui.enabled: $XPACK_APM 
xpack.grokdebugger.enabled: $XPACK_DEVTOOLS
xpack.searchprofiler.enabled: $XPACK_DEVTOOLS
xpack.ml.enabled: $XPACK_ML
xpack.canvas.enabled: $XPACK_CANVAS
xpack.logstash.enabled: $XPACK_LOGS
xpack.infra.enabled: $XPACK_INFRA
xpack.monitoring.enabled: $XPACK_MONITORING
console.enabled: $XPACK_DEVTOOLS
" >> $kibana_config_file
fi
