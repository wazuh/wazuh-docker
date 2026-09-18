#!/bin/bash
# Build-time guard for the data/ persistence contract.
#
# /var/wazuh-manager/data is mounted on a single volume, so anything the image
# ships under it is shadowed by that volume from the second start onwards. Every
# such path therefore has to be either:
#
#   - declared in PERMANENT_DATA_EXCP, so the init refreshes it from the image
#     on every start, or
#   - listed in RUNTIME_OWNED below, meaning the manager rewrites it itself and
#     the image copy is only a seed.
#
# A directory added by a future release that is in neither list would silently
# never appear in an upgraded deployment. Run this after the manager package is
# installed and fail the build if it reports anything.

set -u
source /permanent_data.env

DATA=/var/wazuh-manager/data

# Paths the manager owns and refreshes by itself. Verified for 5.0.0 by comparing
# image content against a loaded deployment: these are the only ones that differ.
RUNTIME_OWNED=(
  "${DATA}/mmdb"
  "${DATA}/store/geo"
)

covered() {
  local path="$1" entry
  for entry in "${PERMANENT_DATA_EXCP[@]}" "${RUNTIME_OWNED[@]}"; do
    [[ "${path}" == "${entry}" || "${path}" == "${entry}/"* ]] && return 0
  done
  return 1
}

uncovered=()
while IFS= read -r file; do
  covered "${file}" || uncovered+=("${file}")
done < <(find "${DATA}" -type f | sort)

if [ "${#uncovered[@]}" -gt 0 ]; then
  echo "ERROR: content shipped under ${DATA} is covered by neither PERMANENT_DATA_EXCP"
  echo "       nor RUNTIME_OWNED. A deployment upgrading onto an existing volume would"
  echo "       never see it. Add each path to one of the two lists:"
  printf '         %s\n' "${uncovered[@]}"
  exit 1
fi

echo "data/ persistence contract: all image-shipped content accounted for"
