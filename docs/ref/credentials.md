# Credentials

The Wazuh images ship with documented default passwords, and a deployment that
keeps them answers to anyone who has read this page. **Changing them is the
first thing to do after the first start**, and this page is the procedure.

Each image carries `password-tool.sh`, which changes the passwords of the
running deployment and prints the new ones once. It stores nothing: what it
prints is the only copy, and the passwords the components need are written by
hand into `docker-compose.yml`.

## Table of Contents

- [The accounts](#the-accounts)
- [Changing the passwords on the first start](#changing-the-passwords-on-the-first-start)
- [Changing one password later](#changing-one-password-later)
- [Multi-node deployments](#multi-node-deployments)
- [Checking that no default is left](#checking-that-no-default-is-left)
- [Notes](#notes)

## The accounts

Two components hold accounts, in separate databases on separate ports. The
"Compose" column is the variable the new password has to be written into; the
accounts with no variable are for people and are not presented by any container.

**Wazuh indexer**, in the security plugin's internal user database. These are
the accounts the Wazuh dashboard logs in with.

| Account | Default | Compose | What it is for |
| - | - | - | - |
| `admin` | `admin` | — | Administrator of the indexer: every index, the cluster settings and the security configuration. Logging into the dashboard as `admin` also produces a Wazuh API administrator session. |
| `kibanaserver` | `kibanaserver` | `wazuh.dashboard` → `DASHBOARD_PASSWORD` | Service account the dashboard authenticates as. |
| `wazuh-manager` | `wazuh-manager` | `wazuh.manager` → `INDEXER_PASSWORD` | Service account the manager writes events and reads state as. |
| `wazuh-admin` | `wazuh-admin` | — | Wazuh administrator: reads the Wazuh indices, writes Wazuh settings and content, and administers the Security Analytics plugin. |
| `wazuh-readonly` | `wazuh-readonly` | — | Read-only access to settings, content and detectors. |
| `wazuh-demo` | `wazuh-demo` | — | Content management, without administration of the deployment. |

The OpenSearch demo accounts (`kibanaro`, `logstash`, `readall`,
`snapshotrestore`, `anomalyadmin`) are **not** part of a Wazuh deployment. They
are removed from the image when it is built, so they do not exist and cannot be
logged into.

**Wazuh manager**, in the API's RBAC database.

| Account | Default | Compose | What it is for |
| - | - | - | - |
| `wazuh` | `wazuh` | — | Superuser of the Wazuh API. |
| `wazuh-wui` | `wazuh-wui` | `wazuh.dashboard` → `API_PASSWORD` | Service account the dashboard proxies manager requests as. It asks the API to act as the logged-in dashboard user, so what a dashboard session can do is decided by that user's role, not by this account. |

In multi-node the services are `wazuh1.indexer` and `wazuh.master`, and the
manager variables have to be set on `wazuh.master` and `wazuh.worker` alike.

## Changing the passwords on the first start

Run this once, immediately after the deployment comes up for the first time.
The example is single-node; the multi-node differences are in the section below.

**1. Bring the deployment up and wait for it to be healthy.**

```bash
cd single-node
docker compose up -d
docker compose ps
```

The tools work against the running cluster, so every container has to report
`healthy` before going on. The first start takes a couple of minutes.

**2. Change the Wazuh indexer passwords.**

```bash
docker compose exec wazuh.indexer /password-tool.sh --all
```

It prints every account with its new password, and repeats the two that have to
go into the Compose file:

```
Changed on the running deployment:

  admin            r?FT4dqvBn0LxlXQ.uYm-3jHsWk8zAeC
  kibanaserver     G2wrq1B20.eXC85*-8inI+F27y8UwoL.
  wazuh-manager    Bqf7j57J3BNEb5RgP9kprDX0GY*6QjmM
  wazuh-admin      j*YwhC.RUiJYCq4Qs10v3U3qm3keJqec
  wazuh-readonly   2d1a5KtVeVCHkrRytEmRYS4c8VGouku.
  wazuh-demo       o0V1D.k*qdJaydzha3eYQlvdDOjRLg4v

This is the only time these passwords are shown. Nothing is stored.

Write these into docker-compose.yml, then take the stack down and up,
or those components keep authenticating with the old values:

  service wazuh.dashboard:
    - DASHBOARD_PASSWORD=G2wrq1B20.eXC85*-8inI+F27y8UwoL.
  service wazuh.manager:
    - INDEXER_PASSWORD=Bqf7j57J3BNEb5RgP9kprDX0GY*6QjmM
```

**Copy the whole output somewhere safe before going on.** It is not written to
any file and it is not shown again. The `admin` password is the one that logs
into the dashboard.

**3. Change the Wazuh API passwords.**

```bash
docker compose exec wazuh.manager /password-tool.sh --all
```

```
Changed on this manager node:

  wazuh            ZD04YaYFH*JC?gOvWWaF54O-MrgJEm6K
  wazuh-wui        VdzPHTfpFCw8MbPkX?nek2902VkwYDsQ

This is the only time these passwords are shown. Nothing is stored.

Write these into docker-compose.yml, then take the stack down and up,
or those components keep authenticating with the old values:

  service wazuh.dashboard:
    - API_PASSWORD=VdzPHTfpFCw8MbPkX?nek2902VkwYDsQ
```

**4. Write the three service passwords into `docker-compose.yml`.**

Replace the default values, leaving the usernames as they are:

```yaml
  wazuh.manager:
    environment:
      - INDEXER_USERNAME=wazuh-manager
      - INDEXER_PASSWORD=Bqf7j57J3BNEb5RgP9kprDX0GY*6QjmM

  wazuh.dashboard:
    environment:
      - DASHBOARD_USERNAME=kibanaserver
      - DASHBOARD_PASSWORD=G2wrq1B20.eXC85*-8inI+F27y8UwoL.
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=VdzPHTfpFCw8MbPkX?nek2902VkwYDsQ
```

The other five passwords go nowhere in the file: no container presents them.

**5. Take the stack down and up.**

```bash
docker compose down
docker compose up -d
```

Do **not** add `-v`. That deletes the volumes, and with them the security index
and the API user database, which is where the new passwords now live: the
deployment would come back on the defaults and this procedure would have to be
repeated.

`docker compose restart` is not enough either when the values in the file have
changed: `down` and `up` is what recreates the containers with the new
environment.

**6. Confirm.**

```bash
../tools/tests/check-default-credentials.sh
```

Every account has to be refused with its username as its password. Then log
into the dashboard as `admin` with the new password.

### What the tool touches

It changes the password of the accounts you name, on the running cluster, and
nothing else:

| | |
| - | - |
| Passwords of the accounts named | changed |
| Passwords of every other account, including ones you created | untouched |
| Accounts you created yourself | kept, with their roles, attributes and description |
| Roles and role mappings | not written at all |
| The user database inside the image | not modified |

It works this way because it takes the user database from the running cluster
before changing it, rather than uploading the one in the image.

## Changing one password later

The same tool, with `--user` instead of `--all`:

```bash
docker compose exec wazuh.indexer /password-tool.sh --user admin
docker compose exec wazuh.manager /password-tool.sh --user wazuh-wui
```

To choose the password instead of having one generated, pass it on standard
input:

```bash
printf '%s\n' 'MyNewPassword.1' | \
  docker compose exec -T wazuh.indexer /password-tool.sh --user admin --stdin
```

A password must be 8 to 64 characters and contain an upper case letter, a lower
case letter, a digit and one of `.*+?-`. The Wazuh API rejects anything else.

If the account you changed has a Compose variable, repeat steps 4 and 5.
Changing `admin`, `wazuh-admin`, `wazuh-readonly`, `wazuh-demo` or `wazuh` takes
effect immediately and needs no restart.

## Multi-node deployments

**The indexer accounts are cluster-wide.** Run the tool on `wazuh1.indexer`,
which is the node that mounts the admin certificate, and the change reaches the
three nodes:

```bash
docker compose exec wazuh1.indexer /password-tool.sh --all
```

`INDEXER_PASSWORD` then has to be written into both `wazuh.master` and
`wazuh.worker`.

**The Wazuh API accounts are not.** The RBAC database is local to each manager
node and the cluster does not synchronize it, so every node has to be set to the
same value. Change them on the master, then set the same passwords on each
worker with `--stdin`; the tool prints the exact command:

```bash
docker compose exec wazuh.master /password-tool.sh --all

printf '%s\n' '<the wazuh password it printed>' | \
  docker compose exec -T wazuh.worker /password-tool.sh --user wazuh --stdin
printf '%s\n' '<the wazuh-wui password it printed>' | \
  docker compose exec -T wazuh.worker /password-tool.sh --user wazuh-wui --stdin
```

## Checking that no default is left

```bash
cd single-node
../tools/tests/check-default-credentials.sh
```

It asserts that the image carries none of the OpenSearch demo accounts and that
no Wazuh indexer or Wazuh API account authenticates with its own username as its
password. **A deployment that has not been through the procedure above fails
this check**, which is what it is for.

## Notes

- The passwords live in the security index of the indexer and in the RBAC
  database of each manager node, both on named volumes. Removing those volumes
  (`docker compose down -v`) returns the deployment to the defaults.
- `password-tool.sh` writes no file and keeps no copy. A password that is lost
  is replaced, not recovered: run the tool again for that account.
- A password written into `docker-compose.yml` is in clear text in a file that
  is usually under version control. Keep it out of your commits, and restrict
  read access to the deployment directory as you do for `wazuh-certificates/`.
- The indexer accounts are `reserved`, so the security API refuses to modify
  them. `password-tool.sh` goes through `securityadmin` with the admin
  certificate the deployment already mounts, which is why it is the supported
  way to change them.
- `/securityadmin.sh` on its own is a different thing. With no arguments it
  uploads the whole security configuration of the image, replacing the one the
  cluster is running: every internal user that is not in the image is deleted,
  custom role mappings are reverted, and every password returns to the default
  of the image. Use it only when that is what you want.
