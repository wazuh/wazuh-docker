# Credentials

Every account of a Wazuh Docker deployment gets its password when the
deployment is created, not when the image is built. No password is written to
any file of this repository, and none of them can be set from
`docker-compose.yml`: they are generated on the first start and changed
afterwards with the tool each image ships.

## Table of Contents

- [The accounts](#the-accounts)
- [Where the passwords come from](#where-the-passwords-come-from)
- [Reading the passwords of a deployment](#reading-the-passwords-of-a-deployment)
- [Verifying the passwords in use](#verifying-the-passwords-in-use)
- [Changing a Wazuh indexer password](#changing-a-wazuh-indexer-password)
- [Changing a Wazuh API password](#changing-a-wazuh-api-password)
- [Multi-node deployments](#multi-node-deployments)
- [Injecting passwords from an external secret store](#injecting-passwords-from-an-external-secret-store)
- [Checking that no default is left](#checking-that-no-default-is-left)

## The accounts

Two components hold accounts, in separate databases on separate ports.

**Wazuh indexer**, in the security plugin's internal user database. These are
the accounts the Wazuh dashboard logs in with.

| Account | What it is for |
| - | - |
| `admin` | Administrator of the indexer: every index, the cluster settings and the security configuration. Logging into the dashboard as `admin` also produces a Wazuh API administrator session. |
| `kibanaserver` | Service account the dashboard authenticates as. Not for people. |
| `wazuh-manager` | Service account the manager writes events and reads state as. Not for people. |
| `wazuh-admin` | Wazuh administrator: reads the Wazuh indices, writes Wazuh settings and content, and administers the Security Analytics plugin. |
| `wazuh-readonly` | Read-only access to settings, content and detectors. |
| `wazuh-demo` | Content management, without administration of the deployment. |

The OpenSearch demo accounts (`kibanaro`, `logstash`, `readall`,
`snapshotrestore`, `anomalyadmin`) are **not** part of a Wazuh deployment. They
are removed from the image when it is built, so they do not exist and cannot be
logged into.

**Wazuh manager**, in the API's RBAC database.

| Account | What it is for |
| - | - |
| `wazuh` | Superuser of the Wazuh API. |
| `wazuh-wui` | Service account the dashboard proxies manager requests as. It asks the API to act as the logged-in dashboard user, so what a dashboard session can do is decided by that user's role, not by this account. Not for people. |

## Where the passwords come from

None of these accounts has a password inside the image. The indexer image ships
its user database with the accounts present and no usable hash in it, and the
manager's RBAC database does not exist until the deployment creates it.

On the first start, each container generates a password for the accounts it
owns and writes it to the `wazuh-credentials` volume, which the indexer, the
manager and the dashboard containers share. That volume is the deployment's
password store: it is how the components learn each other's credentials without
any password being written into a Compose file or into this repository.

Generated passwords are 32 characters and satisfy the Wazuh password policy: 8
to 64 characters with an upper case letter, a lower case letter, a digit and one
of `.*+?-`. The API rejects anything else, so a generated password and one you
choose later are interchangeable.

The volume is created from the images, so nothing has to be prepared on the
host, and the files in it are readable only by the containers' own user. Two
containers starting at the same time cannot disagree about its contents: the
file is published with a hard link, so it becomes visible only complete, and
whichever container loses the race adopts the other's values. That is what lets
the three indexer nodes and the two manager nodes of a multi-node deployment
come up on one set of credentials.

> **The `wazuh-credentials` volume is a secret of the deployment.** Restrict
> access to it as you do for the certificates, do not copy it between
> deployments, and remember that anyone who can run `docker compose exec` on
> these containers can read it.

## Reading the passwords of a deployment

The `admin` password is printed once, on the first start of the indexer:

```bash
docker compose logs wazuh.indexer | grep "Log in to the Wazuh dashboard"
```

Afterwards, `password-tool.sh --show` prints the account and the password of
every user of that component:

```bash
docker compose exec wazuh.indexer /password-tool.sh --show
docker compose exec wazuh.manager /password-tool.sh --show
```

## Verifying the passwords in use

`--show` reads the store. `--verify` checks it against the running deployment,
which is what tells you whether a change actually landed:

```bash
$ docker compose exec wazuh.indexer /password-tool.sh --verify
  ok    admin
  ok    kibanaserver
  ok    wazuh-manager
  ok    wazuh-admin
  ok    wazuh-readonly
  ok    wazuh-demo
```

On the indexer each account is authenticated against the cluster; on the manager
each one is checked against that node's user database. A `FAIL` line means the
recorded password is not the one the component would accept, and the command
exits non-zero, so it can be used in a health check or a pipeline.

Every change made with the tool runs this verification on its own and reports
the result before exiting.

## Changing a Wazuh indexer password

```bash
# Generate a new password for one account and print it
docker compose exec wazuh.indexer /password-tool.sh --user admin

# Choose the password yourself
printf 'MyNewPassword.1\n' | docker compose exec -T wazuh.indexer /password-tool.sh --user admin --stdin

# Rotate every account
docker compose exec wazuh.indexer /password-tool.sh --all
```

The command records the new password in the store, writes its hash into the
user database, loads that database into the running cluster with `securityadmin`
and the admin certificate the deployment already mounts, and then authenticates
with the new password to confirm:

```
  ok    admin            r?FT4dqvBn0LxlXQ.uYm-3jHsWk8zAeC
```

These accounts are `reserved`, so the security API refuses to modify them; going
through `securityadmin` is what makes the change possible, and the tool is the
supported way to do it.

If you change `kibanaserver` or `wazuh-manager`, the tool says so: those are
service accounts, read from the store when the container that presents them
starts, so that container has to be restarted.

```bash
docker compose restart wazuh.dashboard wazuh.manager
```

`docker compose up -d` does not do it: the password is not in the Compose file,
so Compose sees nothing to change and leaves the container running.

## Changing a Wazuh API password

```bash
docker compose exec wazuh.manager /password-tool.sh --user wazuh-wui
printf 'MyNewPassword.1\n' | docker compose exec -T wazuh.manager /password-tool.sh --user wazuh --stdin
docker compose exec wazuh.manager /password-tool.sh --all
```

The command records the new password in the store and sets it in the RBAC
database of that node, without going through the API, so it works whether or not
the API is answering. Changing `wazuh-wui` needs the dashboard restarted:

```bash
docker compose restart wazuh.dashboard
```

## Multi-node deployments

The indexer accounts are cluster-wide: run the tool on `wazuh1.indexer`, which
is the node that mounts the admin certificate, and the change reaches the three
nodes.

The Wazuh API accounts are **not**. The RBAC database is local to each manager
node and the cluster does not synchronize it, so the other nodes have to be
brought in line after a change on the master. Either restart them, which makes
them adopt what the store holds:

```bash
docker compose exec wazuh.master /password-tool.sh --user wazuh-wui
docker compose restart wazuh.worker
```

or apply the store to each node without restarting it:

```bash
docker compose exec wazuh.worker /password-tool.sh --apply
```

A manager node applies the recorded passwords to its own database on every
start. This is deliberate: the store is where the deployment's passwords live,
so a password changed out of band, through `PUT /security/users/{id}` for
example, is replaced on the next start of that node. Change API passwords with
the tool and the store stays the single answer to "what is the password".

## Injecting passwords from an external secret store

The Compose files set no password, and there is no variable for setting one per
account. A deployment that keeps its secrets elsewhere can still inject the
three service credentials that one container presents to another, using the
variables the images have always accepted:

| Container | Variable | Account |
| - | - | - |
| manager | `INDEXER_PASSWORD` | the indexer user in `INDEXER_USERNAME` (`wazuh-manager`) |
| dashboard | `DASHBOARD_PASSWORD` | the indexer user in `DASHBOARD_USERNAME` (`kibanaserver`) |
| dashboard | `API_PASSWORD` | the Wazuh API user in `API_USERNAME` (`wazuh-wui`) |

A value given in one of these takes precedence over the store for that
container. It does not change the account: set the password with
`password-tool.sh` first, then hand the same value to the container that has to
present it.

## Checking that no default is left

The repository ships a check that no account of a deployment authenticates with
a password that could be known before the deployment existed. Run it from the
directory of the Compose file:

```bash
cd single-node
../tools/tests/check-default-credentials.sh
```

It asserts that the image carries no usable hash and none of the OpenSearch demo
accounts, that no indexer or API account authenticates with its username as its
password, and, as a positive control, that the credentials the deployment
generated do work.
