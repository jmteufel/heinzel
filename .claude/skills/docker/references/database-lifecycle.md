# Database Lifecycle

## Schema Migrations

Run migrations as an init container that completes
before the app starts. See `references/compose.md`
for the `service_completed_successfully` pattern.
The app never starts against an unmigrated schema.

**Backward compatibility is mandatory during
rolling deploys.** While a deploy runs, the old
and new app versions may both be handling traffic
briefly. The new schema must work with both.
Practical rules:

- Add columns as nullable before making them
  required — do that in a later deploy.
- Rename in three deploys: add new column →
  dual-write old and new → remove old column.
- Never drop a column in the same deploy that
  removes the code referencing it.

**Migration rollback:** if the app fails after
a migration succeeds, the database is already
migrated. The path back is either a compensating
migration (preferred) or restoring from backup.
Design every migration to be reversible.

## Major Version Upgrades

Always back up before starting. A failed upgrade
mid-process can leave the database unusable.

### Dump / Restore

Simpler, always works, downtime proportional to
database size. Use this by default.

**PostgreSQL:**
1. Stop the application (not the database).
2. `pg_dump -Fc -h localhost -U postgres mydb
   > backup.dump`
3. Start a new container on the target version
   with a fresh named volume.
4. `pg_restore -h localhost -U postgres -d mydb
   backup.dump`
5. Verify: row counts, spot-check data, run
   smoke tests.
6. Update compose.yaml: new image tag, new
   volume name.
7. Start the application.

**MySQL / MariaDB:**
`mysqldump --single-transaction` for a consistent
logical backup without stopping the database.
Restore with `mysql < backup.sql` into the new
version container.

### pg_upgrade (PostgreSQL only)

Faster for large databases; more complex. Uses
both old and new binaries to upgrade data files
in place. The `pgautoupgrade` image handles the
process without managing binaries manually.

Key risk: extensions (PostGIS, pg_vector, etc.)
must be compatible with the target version and
may need reinstalling. Check before starting —
an incompatible extension can abort the upgrade
and require a restore.

Not worth the complexity for databases under
~50GB where dump/restore takes minutes.

## Bootstrapping

When a database container starts for the first
time against an empty volume, it needs initial
credentials and schema. Docker's official images
support init scripts (`/docker-entrypoint-
initdb.d/`) and env vars (`POSTGRES_PASSWORD`,
`MYSQL_ROOT_PASSWORD`, etc.).

**Credentials:** set the root password via
environment variable (`POSTGRES_PASSWORD`), not
by writing it to an init file. Init files run
only once on first start and are never re-read —
if the password changes later, the init file is
silently stale and misleading.

**Schema:** prefer code-first migrations (run by
your application or an init container) over SQL
files in `initdb.d/`:

- SQL init files run before your app exists and
  cannot be versioned alongside application code.
- Migrations run at deploy time and are tracked,
  reversible, and testable.
- Use `initdb.d/` only for extensions or roles
  that must exist before the first migration.

## Backup Schedule

Run `pg_dump` from a long-lived container that
shares the database network. Keep the schedule
inside the stack — no host cron dependency.

`postgres:XX-alpine` already contains both
`pg_dump` and busybox `crond`. No custom image
is needed:

```yaml
services:
  backup:
    image: postgres:16-alpine
    entrypoint: >
      sh -c '
        echo "0 2 * * * pg_dump -Fc -h db
        -U postgres mydb
        > /backups/$$(date +%F-%H%M).dump"
        > /etc/crontabs/postgres
        && crond -f -d 8'
    environment:
      PGPASSWORD: "${DB_PASSWORD}"
    volumes:
      - /srv/backups/db:/backups
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    user: postgres
```

For on-demand runs, use a one-shot profile
container instead:

```yaml
services:
  backup-once:
    image: postgres:16-alpine
    command: >
      sh -c 'pg_dump -Fc -h db -U postgres
      mydb > /backups/$$(date +%F-%H%M).dump'
    environment:
      PGPASSWORD: "${DB_PASSWORD}"
    volumes:
      - /srv/backups/db:/backups
    depends_on:
      db:
        condition: service_healthy
    profiles: [backup]
    restart: "no"
```

```bash
docker compose --profile backup run --rm backup-once
```

Suggested retention: daily backups for 7 days,
weekly for 4 weeks. Add a cleanup entry to the
crontab alongside the dump command.

**Backup verification is not optional.** An
untested backup is not a backup. Restore a dump
to a throwaway container weekly and run a smoke
test. If restoration fails, find out now.

## Point-in-Time Recovery

`pg_dump` captures state at dump time. To recover
to an arbitrary point (e.g. 5 minutes before an
accidental DELETE), enable WAL archiving in
PostgreSQL:

- `wal_level = replica`
- `archive_mode = on`
- `archive_command` — copies WAL segment files
  to a backup location as they complete

Recovery replays WAL segments on top of a base
backup to reach the target timestamp.

PITR adds operational complexity and continuous
storage writes. Use it when your RPO requirement
is shorter than your dump interval, or when you
need to recover from a logical data error.
