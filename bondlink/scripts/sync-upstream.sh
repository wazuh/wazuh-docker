#!/usr/bin/env bash
# Merge a newer upstream wazuh/wazuh-docker release tag into this branch,
# without touching bondlink/. See ../README.md "Syncing with upstream Wazuh
# releases" for the full process this script is one step of.
#
# Usage:
#   bondlink/scripts/sync-upstream.sh            # list upstream tags newer than this branch's base
#   bondlink/scripts/sync-upstream.sh v4.14.1     # merge that tag into the current branch
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "error: no 'upstream' remote configured (expected wazuh/wazuh-docker)" >&2
  exit 1
fi

if [[ $# -gt 0 && -n "$(git status --porcelain)" ]]; then
  echo "error: working tree is not clean; commit or set aside changes first" >&2
  exit 1
fi

echo "Fetching upstream tags..."
git fetch upstream --tags --quiet

branch="$(git rev-parse --abbrev-ref HEAD)"
base_tag="$(git describe --tags --match 'v*' --abbrev=0 HEAD)"

if [[ $# -eq 0 ]]; then
  echo "Current base: $base_tag"
  echo "Upstream tags newer than $base_tag:"
  git tag -l 'v*' --sort=-v:refname --contains "$base_tag" 2>/dev/null \
    | grep -v -x "$base_tag" || true
  echo
  echo "Re-run with a target tag to merge it in, e.g.:"
  echo "  $0 v4.14.1"
  exit 0
fi

target_tag="$1"

if ! git rev-parse -q --verify "refs/tags/${target_tag}" >/dev/null; then
  echo "error: tag '${target_tag}' not found (did you mean to fetch first?)" >&2
  exit 1
fi

echo "Merging ${target_tag} into ${branch}..."
git merge --no-ff "${target_tag}" -m "Merge upstream ${target_tag} into ${branch}"

cat <<EOF

Merge complete. Next steps (see bondlink/README.md):
  1. Resolve any conflicts reported above (there should be none in bondlink/).
  2. docker compose -f multi-node/docker-compose.yml -f bondlink/docker-compose.override.yml config
  3. Bring the stack up and re-validate against the new images.
  4. Update the "Live validation results" section of bondlink/README.md.
EOF
