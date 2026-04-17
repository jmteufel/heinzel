# Disaster Recovery

## What to Back Up

A full stack recovery needs more than the
database. Back up all of the following:

- `compose.yaml`, `compose.override.yaml`
- `.env` files — keep an encrypted copy off the
  server (password manager, secrets vault). The
  on-server copy alone is not sufficient.
- Bind-mounted config directories (reverse proxy
  config, TLS certificates, app config files)
- Named volumes — use the procedure in
  `references/operations.md`
- `/etc/docker/daemon.json` and note the
  `data-root` path if non-default

Store compose files and config in git (without
secrets). Store volume archives and `.env` copies
off-server — a server failure takes both the
data and any backup stored only on that server.

## Backup Procedure

**Stopping the stack before snapshotting volumes**
is the only way to guarantee consistency for
databases that do not support hot backup.

Recommended order to minimise downtime:
1. Stop app containers (not the database).
2. Take a database dump (see
   `references/database-lifecycle.md`).
3. Restart app containers.
4. Snapshot remaining volumes (uploads, config,
   etc.) using the running-container tar method
   from `references/operations.md`.
5. Copy compose files and configs to off-server
   storage.

For databases that support consistent hot backup
(PostgreSQL with `pg_dump --serializable-deferred`
or MySQL with `--single-transaction`), step 1 is
not needed.

## Recovery Runbook

Execute in order — each step depends on the
previous.

**1. Provision server, install Docker**
Follow `references/installation.md`. Do not
skip the official repo requirement.

**2. Restore daemon configuration**
Write `/etc/docker/daemon.json`. Create the
`data-root` directory if non-default and ensure
it is owned by root. Restart Docker.
Reference: `references/config.md`.

**3. Restore compose files and `.env`**
Clone the git repo or copy from backup. Restore
`.env` files from the encrypted off-server copy.
Verify no secrets are missing before proceeding.

**4. Restore named volumes**
For each named volume used by the stack:

```bash
docker volume create <volume-name>
docker run --rm \
  -v <volume-name>:/data \
  -v /path/to/backup:/backup \
  alpine tar xzf /backup/<volume>.tar.gz -C /data
```

**5. Restore bind-mount directories**
Copy config directories to their host paths.
Check file ownership — containers running as
non-root may fail if files are owned by root.

**6. Pull images and start**

```bash
docker compose pull
docker compose up -d
```

**7. Verify**
- `docker compose ps` — all services healthy.
- `docker compose logs` — no startup errors.
- Application smoke tests.
- Spot-check data integrity against a known-good
  state (row counts, last transaction timestamp).

## Recovery Drills

Run a complete recovery drill on a staging server
before you need it in production. Drills reveal:

- Missing backup components (a config file that
  was never included in the backup job).
- Steps that take longer than expected.
- Dependencies between steps that are not
  documented.

After the drill, record:

- **RTO** (Recovery Time Objective): how long
  the full runbook actually took.
- **RPO** (Recovery Point Objective): how old
  was the data in the most recent backup — the
  maximum data loss in the worst-case scenario.

If the RTO is 4 hours and the RPO is 24 hours,
decide whether that is acceptable before an
incident, not during one. Adjust backup frequency
or automate runbook steps accordingly.
