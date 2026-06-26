# Wazuh Docker Deployment

## Deploying Wazuh on Rootless Podman with SELinux

The `single-node/docker-compose.yml` and `multi-node/docker-compose.yml` files are
compatible with [Podman](https://podman.io/) in **rootless** mode on hosts with
SELinux in **enforcing** mode. The bind-mounted certificate and configuration files
carry the `:z` SELinux relabel option, so Podman relabels them with a container
context automatically. On Docker hosts (or hosts without SELinux) the `:z` option is
ignored, so the same files work unchanged in both engines.

This guide covers the host preparation needed for a rootless deployment and the
differences from the standard Docker workflow. It has been validated with
`podman` 5.x and `podman-compose` 1.3.x on Rocky Linux 9.

> **Note:** Rootless Podman support is community-contributed. The official, fully
> supported deployment method remains `docker compose`.

### 1. Host preparation (run as root)

1.  Increase `vm.max_map_count`, required by the Wazuh indexer:

    ```bash
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
    sysctl -p
    ```

2.  Install Podman and the Netavark network stack:

    ```bash
    dnf install -y podman netavark aardvark-dns python3-pip
    ```

    Make sure `network_backend = "netavark"` is set in
    `/usr/share/containers/containers.conf`.

3.  Keep the user's systemd instance alive after logout, so the containers keep
    running when the user is not logged in. Replace `<user>` with the unprivileged
    account that will own the deployment:

    ```bash
    loginctl enable-linger <user>
    ```

4.  Raise the `memlock` and `nofile` limits the indexer and manager require. Add to
    `/etc/security/limits.conf` and re-login for the change to take effect:

    ```
    <user>  hard  memlock   -1
    <user>  hard  nofile    655360
    ```

### 2. Binding to privileged ports (optional)

The dashboard publishes on host port `443` and the manager on `514/udp`. Rootless
containers cannot bind to ports below `1024` by default. Either publish the services
on high ports (for example, map `443:5601` to `8443:5601` in the compose file), or
lower the unprivileged-port threshold on the host (run as root):

```bash
# Permanent
echo "net.ipv4.ip_unprivileged_port_start=443" >> /etc/sysctl.conf
sysctl -p
```

### 3. Generate the certificates

Run the certificate steps as the unprivileged user from inside the deployment
directory (`single-node` or `multi-node`), exactly as in the Docker workflow:

```bash
curl -o wazuh-certs-tool.sh https://packages.wazuh.com/5.0/wazuh-certs-tool-5.0.1-1.sh
curl -o config.yml https://packages.wazuh.com/5.0/config-5.0.1-1.yml
# Edit config.yml with your node names, then:
bash ../tools/utils/deployment/certificates-conf.sh --cert --copy
```

> **Rootless certificate ownership:** The `--priv` flag of `certificates-conf.sh`
> runs `chown 101:101` and `chmod 400` on the certificate files. Under rootless
> Podman the container's UID `101` is mapped to a high subordinate UID on the host,
> not host UID `101`, so an ownership set by `--priv` will not match the in-container
> user and the files become unreadable inside the container.
>
> For rootless deployments, **omit `--priv`** (the relabel granted by `:z` plus the
> default read permissions are sufficient), or set ownership through the user
> namespace instead:
>
> ```bash
> podman unshare chown -R 101:101 config/*/certs
> ```

### 4. Start the stack

From the `single-node` or `multi-node` directory:

```bash
podman-compose --in-pod=true up -d
```

To manage the deployment with systemd, a simple user service that wraps
`podman-compose` keeps the standard compose files as the single source of truth:

```ini
# ~/.config/systemd/user/wazuh.service
[Unit]
Description=Wazuh (podman-compose)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=%h/wazuh-docker/single-node
ExecStart=%h/.local/bin/podman-compose --in-pod=true up -d
ExecStop=%h/.local/bin/podman-compose down

[Install]
WantedBy=default.target
```

Enable it with `systemctl --user enable --now wazuh.service`.

### Troubleshooting

-   **`Permission denied` writing to `/certificates` or reading certs:** Confirm the
    bind mounts in your compose file end with `:z`. If SELinux is enforcing, check
    for denials with `ausearch -m avc -ts recent`.
-   **`bootstrap check failure ... max virtual memory areas`:** `vm.max_map_count`
    was not applied; re-run step 1.
-   **Containers cannot bind port 443/514:** Apply the unprivileged-port change in
    step 2 or remap to high ports.
