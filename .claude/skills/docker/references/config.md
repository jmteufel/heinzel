# Docker Daemon Configuration

Path: `/etc/docker/daemon.json`. Back up before
editing (`rules/backups.md`). Apply changes:

```bash
systemctl reload docker
# if reload is insufficient:
systemctl restart docker
```

## Data Root

By default Docker stores everything — images,
containers, volumes, logs — under
`/var/lib/docker`. On most servers this is the
root partition. A single large image pull or a
container writing unbounded logs will fill it,
making the whole server unstable.

Set `data-root` to a dedicated partition or volume
before first use. Changing it after containers
exist requires migrating data manually:

```json
{
  "data-root": "/mnt/docker"
}
```

The directory must exist and be owned by root
before starting the daemon. If changing on an
existing installation: stop Docker, move
`/var/lib/docker` to the new location, update
`daemon.json`, start Docker.

## Recommended Defaults

Set these on every server, ideally before any
networks or containers are created:

```json
{
  "log-driver": "journald",
  "log-opts": { "max-size": "10m" },
  "default-address-pools": [
    { "base": "172.16.0.0/12", "size": 24 }
  ]
}
```

- `log-driver: journald` — integrates container
  logs with `journalctl` instead of writing
  separate JSON files under `/var/lib/docker`.
- `default-address-pools` — overrides Docker's
  default `172.17.0.0/16`, which commonly
  conflicts with existing RFC 1918 ranges on
  corporate or datacenter networks. Must be set
  before any networks are created — changing it
  later does not affect existing networks.

## Security-Relevant Options

- `"icc": false` — disables inter-container
  communication on the default bridge network.
  Containers must be explicitly networked to talk.
  Has no effect on user-defined networks (which
  allow ICC by default regardless).
- `"userns-remap": "default"` — enables user
  namespace remapping. Container root (uid 0) maps
  to an unprivileged host UID. Stronger isolation
  than non-root USER alone; some images break.
- `"live-restore": true` — keeps containers
  running when the Docker daemon restarts (e.g.
  during a daemon upgrade). Safe to enable on
  production servers.

## Logging

The default log driver (`json-file`) writes
unbounded log files to `/var/lib/docker/containers/`.
Without `max-size`, a chatty container can fill
the disk. Switching to `journald` centralises logs
and delegates rotation to systemd-journald.

If `journald` is not available, at minimum set
limits on the `json-file` driver:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```
