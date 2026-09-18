#!/usr/bin/env bash
# Push new admin/kibanaserver passwords into a *live* indexer's security
# index via the OpenSearch Security REST API. See ../README.md "Rotating
# live secrets" for why this exists and where it fits in the rollout order
# this script is one step of.
#
# Changing INDEXER_PASSWORD/DASHBOARD_PASSWORD in .env.secrets (rendered by
# salt/wazuh-docker/init.sls's wazuh-docker-env-secrets state into
# /etc/wazuh-docker-runtime/, not this checkout -- see that state and
# README.md's "Rotating live secrets" for why) only changes what
# wazuh.master/worker/dashboard *present* when they authenticate to the
# indexer -- it does not change what the indexer itself accepts. That lives
# in the security index, seeded once from
# multi-node/config/wazuh_indexer/internal_users.yml at first bootstrap and
# never touched again by env vars or config re-renders. On a running cluster
# (or a disposable one deliberately left un-wiped to emulate one -- see
# README), this script is the only thing that actually changes what the
# indexer accepts.
#
# Authenticates via the admin_dn client cert (mTLS identity, bypasses RBAC
# entirely) rather than basic auth with the *current* admin password -- same
# mechanism snapshot_index.py's restore_snapshot()/delete_snapshot() already
# use, and it means this script doesn't need to know or be told what the
# current password is.
#
# Usage:
#   bondlink/scripts/rotate-indexer-secrets.sh [indexer-host]
#     indexer-host defaults to localhost:9200.
#
# Reads the new passwords from /etc/wazuh-docker-runtime/bondlink/.env.secrets
# (must already be rendered -- see salt/wazuh-docker/init.sls). Reads the
# admin_dn cert from multi-node/config/wazuh_indexer_ssl_certs/{admin,admin-key}.pem
# (inside this checkout -- certs aren't part of the runtime_dir treatment),
# matching snapshot_index.py's DEFAULT_ADMIN_CERT_PATH/DEFAULT_ADMIN_KEY_PATH.
set -euo pipefail

cd "$(sudo -u bldeploy git rev-parse --show-toplevel)"

INDEXER_HOST="${1:-localhost:9200}"
ENV_SECRETS="/etc/wazuh-docker-runtime/bondlink/.env.secrets"
ADMIN_CERT="multi-node/config/wazuh_indexer_ssl_certs/admin.pem"
ADMIN_KEY="multi-node/config/wazuh_indexer_ssl_certs/admin-key.pem"

if [[ ! -f "$ENV_SECRETS" ]]; then
  echo "error: $ENV_SECRETS not found -- apply the salt wazuh-docker state first" >&2
  exit 1
fi
if [[ ! -f "$ADMIN_CERT" || ! -f "$ADMIN_KEY" ]]; then
  echo "error: admin_dn cert pair not found at $ADMIN_CERT / $ADMIN_KEY" >&2
  echo "       (generate once via the cert-generator command in README.md)" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a; source "$ENV_SECRETS"; set +a

: "${INDEXER_PASSWORD:?INDEXER_PASSWORD missing from $ENV_SECRETS}"
: "${DASHBOARD_PASSWORD:?DASHBOARD_PASSWORD missing from $ENV_SECRETS}"

push_password() {
  local user="$1" password="$2"
  local body status
  body="$(mktemp)"
  status=$(curl -sk -o "$body" -w '%{http_code}' \
    --cert "$ADMIN_CERT" --key "$ADMIN_KEY" \
    -X PATCH "https://${INDEXER_HOST}/_plugins/_security/api/internalusers/${user}" \
    -H 'Content-Type: application/json' \
    -d "[{\"op\":\"add\",\"path\":\"/password\",\"value\":\"${password}\"}]")
  if [[ "$status" != "200" ]]; then
    echo "error: pushing ${user}'s password failed (HTTP ${status}):" >&2
    cat "$body" >&2
    rm -f "$body"
    exit 1
  fi
  rm -f "$body"
  echo "  ${user}: password updated"
}

echo "Pushing new passwords to indexer at https://${INDEXER_HOST} ..."
push_password admin "$INDEXER_PASSWORD"
push_password kibanaserver "$DASHBOARD_PASSWORD"

cat <<EOF

Done. Next steps (see README.md "Rotating live secrets" for the full order):
  1. wazuh-wui's API password keeps itself in sync automatically as long as
     wazuh.master and wazuh.dashboard both restart (salt's own
     wazuh-docker-wazuh-yml-api-password state handles it) -- no manual
     step here unless you need it live without restarting wazuh.master.
  2. Restart wazuh.master + wazuh.worker together (new INDEXER_PASSWORD/
     cluster key), then the indexer nodes, then wazuh.dashboard.
  3. Validate: dashboard login, API connectivity, Filebeat shipping resumes.
EOF
