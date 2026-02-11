# Backup and restore

On construction...

<!-- This section describes how to back up and restore a Wazuh Docker deployment data.

In this repository, persistence is managed through:

- Docker volumes created by `docker compose` (Wazuh manager, indexer, and dashboard persistent data).
- Local files in the deployment directory, mainly the generated `wazuh-certificates/` folder and any custom configuration files.

## Backup

1. Navigate to your deployment directory (`single-node/` or `multi-node/`).

2. Stop the deployment to create a consistent backup:

	```bash
	docker compose down --remove-orphans
	```

3. Create a backup directory:

	```bash
	BACKUP_DIR="backup-$(date -u +%Y%m%dT%H%M%SZ)"
	mkdir -p "${BACKUP_DIR}/files" "${BACKUP_DIR}/volumes"
	```

4. Back up local files (certificates and deployment configuration):

	```bash
	cp -a docker-compose.yml "${BACKUP_DIR}/files/"
	[ -f config.yml ] && cp -a config.yml "${BACKUP_DIR}/files/"
	[ -f wazuh-certs-tool.sh ] && cp -a wazuh-certs-tool.sh "${BACKUP_DIR}/files/"
	[ -d wazuh-certificates ] && tar -czf "${BACKUP_DIR}/files/wazuh-certificates.tgz" wazuh-certificates/
	[ -d config ] && tar -czf "${BACKUP_DIR}/files/config.tgz" config/
	```

5. Back up Docker volumes created by this Compose project:

	```bash
	PROJECT_NAME="$(basename "${PWD}")"
	docker volume ls -q --filter "label=com.docker.compose.project=${PROJECT_NAME}" \
	  | while read -r VOLUME; do
			docker run --rm \
			  -v "${VOLUME}:/volume:ro" \
			  -v "${PWD}/${BACKUP_DIR}/volumes:/backup" \
			  alpine:3.20 \
			  tar -czf "/backup/${VOLUME}.tgz" -C /volume .
		 done
	```

## Restore

1. Navigate to the target deployment directory.

2. Restore local files (at minimum, the `wazuh-certificates/` folder used by the `docker-compose.yml` bind mounts):

	```bash
	# If you backed up a tarball
	[ -f "${BACKUP_DIR}/files/wazuh-certificates.tgz" ] && tar -xzf "${BACKUP_DIR}/files/wazuh-certificates.tgz"
	```

3. Restore Docker volumes from the backup archives:

	```bash
	for ARCHIVE in "${BACKUP_DIR}/volumes/"*.tgz; do
	  [ -f "${ARCHIVE}" ] || continue
	  VOLUME="$(basename "${ARCHIVE}" .tgz)"
	  docker volume create "${VOLUME}" >/dev/null
	  docker run --rm \
		 -v "${VOLUME}:/volume" \
		 -v "${PWD}/${BACKUP_DIR}/volumes:/backup" \
		 alpine:3.20 \
		 sh -c "rm -rf /volume/* && tar -xzf /backup/$(basename "${ARCHIVE}") -C /volume"
	done
	```

4. Start the deployment:

	```bash
	docker compose up -d
	```

## Notes

- Backups are bound to the Docker Compose project name because the created volumes are prefixed automatically. To keep volume names consistent across hosts, run Compose with an explicit project name (for example: `docker compose -p single-node up -d`).
- Restoring data into a different Wazuh version is not supported. Keep the same image tags, or follow the official upgrade procedure described in the [Upgrade](upgrade.md) section.
- If certificates are missing or replaced, components will fail to establish TLS connections. Ensure the restored `wazuh-certificates/` matches the deployment configuration. -->
