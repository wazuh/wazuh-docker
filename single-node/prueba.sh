nodes="`curl -XGET "https://0.0.0.0:9200/_cat/nodes" -u admin:SecretPassword -k  | grep -E "indexer" | wc -l`"
if [[ $nodes -eq 1 ]]; then
 echo "bien"
else
 echo "mal"
fi
