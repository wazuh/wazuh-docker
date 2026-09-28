# Credentials

The Wazuh images ship no passwords. Every deployment gets its own: they are
generated once, before the first start, by
`tools/utils/deployment/credentials-conf.sh`. Each component receives only the
ones it needs, through the environment. On its first start, each component
stores what it received: the indexer in its security configuration, the manager
in its Wazuh API user database and keystore, the dashboard in its keystore. From
then on, the stored values are the ones that count.

## Table of Contents

- [The accounts](#the-accounts)
- [Creating the credentials](#creating-the-credentials)
- [What the first start does](#what-the-first-start-does)
- [Changing a password later](#changing-a-password-later)
- [Multi-node deployments](#multi-node-deployments)
- [Password rules](#password-rules)
- [Checking that no default is left](#checking-that-no-default-is-left)
- [Notes](#notes)

## The accounts

| Account | Key | In | Used by |
| - | - | - | - |
| `admin` | `WAZUH_INDEXER_ADMIN_PASSWORD` | `indexer.env` | People: administrator of the indexer, and **the account to log into the Wazuh dashboard with** |
| `kibanaserver` | `WAZUH_INDEXER_KIBANASERVER_PASSWORD` | `indexer.env`, `dashboard.env` | The dashboard, to authenticate to the indexer |
| `wazuh-manager` | `WAZUH_INDEXER_MANAGER_PASSWORD` | `indexer.env`, `manager.env` | The manager, to write events and read state in the indexer |
| `wazuh` | `WAZUH_MANAGER_API_PASSWORD` | `manager.env` | People and automation: superuser of the Wazuh API, for example to mint agent enrollment tokens |
| `wazuh-wui` | `WAZUH_MANAGER_WUI_PASSWORD` | `manager.env`, `dashboard.env` | The dashboard, to call the Wazuh API on behalf of the logged-in user |

The files are `config/credentials/<file>` under `single-node/` or `multi-node/`.
The first three accounts live in the indexer, and the last two in the manager's
Wazuh API. The OpenSearch demo accounts (`kibanaro`, `logstash`, `readall`,
`snapshotrestore`, `anomalyadmin`) are not part of a Wazuh deployment and are
not in the image.

## Creating the credentials

Run it from `single-node/` or `multi-node/`, after the certificates and before
the first `docker compose up`. It needs the shared credentials library next to
`wazuh-certs-tool.sh`, in the same version as the images:

```bash
curl -o wazuh-credentials.sh https://packages.wazuh.com/5.0/wazuh-credentials-5.0.0-1.sh
sudo bash ../tools/utils/deployment/credentials-conf.sh
```

```text
WAZUH_INDEXER_ADMIN_PASSWORD: generated
WAZUH_INDEXER_KIBANASERVER_PASSWORD: generated
WAZUH_INDEXER_MANAGER_PASSWORD: generated
WAZUH_MANAGER_API_PASSWORD: generated
WAZUH_MANAGER_WUI_PASSWORD: generated
Credentials written to ./config/credentials: indexer.env, manager.env, dashboard.env
Log in to the Wazuh dashboard as 'admin'. Read its password with:
  grep '^WAZUH_INDEXER_ADMIN_PASSWORD=' ./config/credentials/indexer.env | cut -d= -f2-
```

- **Why `sudo`:** `certificates-conf.sh` creates `config/` as root. The files are
  still given to the user who ran `sudo`, with `0700` on the directory and
  `0600` on each file, so `docker compose` can read them without root.
- **Your own values:** to set a password instead of generating it, give its key
  in the environment. The value is validated against the
  [password rules](#password-rules), and nothing is written if any value fails:

  ```bash
  sudo WAZUH_INDEXER_ADMIN_PASSWORD='<password>' bash ../tools/utils/deployment/credentials-conf.sh
  ```

- **No overwrite:** the script never replaces existing files. `--force` replaces
  them, and is only for a deployment that has never been started.
- **If you skip this step:** `docker compose up` refuses to start and names the
  env file that is missing.

## What the first start does

On its first start, each component takes the keys from its env file, validates
them and stores them:

- **Indexer:** writes the password digests into its security configuration, and
  loads them into the cluster.
- **Manager:** creates the Wazuh API user database, and stores the indexer
  password in its keystore.
- **Dashboard:** stores both of its passwords in its keystore.

Later starts, restarts and recreated containers keep what was stored, and the
env files are no longer read for those values. The stores are on the
deployment's named volumes, so recreating the containers without `-v` keeps
them.

If a key is missing or does not meet the rules, the container stops before its
service starts, and names the key. It never prints the value:

```text
credentials: MISSING WAZUH_INDEXER_ADMIN_PASSWORD
credentials: create the deployment credentials with tools/utils/deployment/credentials-conf.sh
```

Fix `config/credentials/<file>.env` and run `docker compose up -d` again.

## Changing a password later

**Editing a value in `config/credentials/*.env` after the first start changes
nothing.** Use `password-tool.sh` instead. It changes the account on the running
deployment, then prints the commands that apply the new value everywhere else it
is used. Run it from the directory of `docker-compose.yml`:

```bash
docker compose exec wazuh.indexer /password-tool.sh --user kibanaserver
docker compose exec wazuh.manager /password-tool.sh --user wazuh-wui
```

`--all` changes every account of that component. To choose the password
yourself, pass it on standard input:

```bash
printf '%s\n' '<password>' | docker compose exec -T wazuh.indexer /password-tool.sh --user admin --stdin
```

The printed commands have to be run, because the components that consume an
account keep the value they stored. For `kibanaserver`, for example, they
update both env files, write the new password into the dashboard keystore and
restart the dashboard:

```text
  kibanaserver:
    sed -i 's|^WAZUH_INDEXER_KIBANASERVER_PASSWORD=.*|WAZUH_INDEXER_KIBANASERVER_PASSWORD=<new password>|' config/credentials/indexer.env
    sed -i 's|^WAZUH_INDEXER_KIBANASERVER_PASSWORD=.*|WAZUH_INDEXER_KIBANASERVER_PASSWORD=<new password>|' config/credentials/dashboard.env
    printf '%s' '<new password>' | docker compose exec -T wazuh.dashboard runuser -u wazuh-dashboard -- /usr/share/wazuh-dashboard/bin/opensearch-dashboards-keystore add -f --stdin opensearch.password
    docker compose restart wazuh.dashboard
```

| Account | Consumer updated by the printed commands |
| - | - |
| `admin`, `wazuh` | None: only the env file |
| `kibanaserver` | Dashboard keystore, `opensearch.password` |
| `wazuh-manager` | Manager keystore, `indexer` / `password` |
| `wazuh-wui` | Dashboard keystore, `wazuh_core.hosts.default.password` |

The manager's tool refuses to run before the manager's first start. It would
otherwise create the Wazuh API user database itself, and the first start would
then keep that database instead of the passwords in `manager.env`.

## Multi-node deployments

- **Indexer:** the three indexer nodes share `indexer.env`. Each writes the same
  passwords on its first start, so it does not matter which node initializes the
  cluster's security configuration. The indexer accounts are cluster-wide:
  change them on `wazuh1.indexer`, the node that mounts the admin certificate.
- **Manager:** `wazuh.master` and `wazuh.worker` share `manager.env`, so both
  create their Wazuh API user database with the same passwords. The database is
  local to each node and the cluster does not synchronize it. When you change an
  API password on the master, set the same value on the worker. The tool prints
  the command:

  ```bash
  docker compose exec wazuh.master /password-tool.sh --user wazuh-wui
  printf '%s\n' '<the wazuh-wui password it printed>' | \
    docker compose exec -T wazuh.worker /password-tool.sh --user wazuh-wui --stdin
  ```

- **The printed commands** use the single-node service names. In multi-node, the
  manager keystore commands have to be run on `wazuh.master` and on
  `wazuh.worker`.

## Password rules

These are the rules the Wazuh packages apply. `credentials-conf.sh`, both
`password-tool.sh` and the components at start refuse anything else:

- 12 to 64 characters, only from `A-Z a-z 0-9 . , _ + : @ % ^ = ~ -`;
- at least one lowercase letter, one uppercase letter, one digit and one symbol.

Generated passwords are 32 characters long.

## Checking that no default is left

```bash
cd single-node        # or multi-node
../tools/tests/check-default-credentials.sh
```

It asserts two things. The image carries none of the OpenSearch demo accounts.
No Wazuh indexer or Wazuh API account authenticates with its own username as its
password, on the published API and in the user database of every manager node.

## Notes

- `config/credentials/*.env` is the record of the deployment's passwords, in
  clear text. The directory is in `.gitignore`: keep it out of your commits,
  back it up with the certificates, and restrict access to it.
- The files are also passed to the containers as environment variables, so
  anyone who can run `docker inspect` on the host can read them. The containers
  drop them from the environment of their services once the values are stored.
- `docker compose down -v` removes the stores. The next start then takes the
  passwords from the env files again.
- The names of earlier releases still work as aliases, in the environment only:
  `INDEXER_PASSWORD` on the manager, and `DASHBOARD_PASSWORD` and `API_PASSWORD`
  on the dashboard. `INDEXER_USERNAME` and `DASHBOARD_USERNAME` are ignored: the
  accounts are always `wazuh-manager` and `kibanaserver`.
- `/securityadmin.sh` on its own is a different thing. With no arguments, it
  uploads the whole security configuration of the image and replaces the one the
  cluster is running: internal users that are not in the image are deleted,
  custom role mappings are reverted, and every password is replaced by what the
  container's own `internal_users.yml` holds. That is the digests of the first
  start, which undoes any later rotation, or, in a recreated container, the
  placeholders the image ships, which no password matches. Use
  `password-tool.sh` to change a password.
