# Container Operations

## Volume Backup and Restore

Named volumes are opaque to the host. To back up,
spin up a temporary container that mounts the
volume and writes a tar archive to a host path:

```bash
# Backup
docker run --rm \
  -v <volume>:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz -C /data .

# Restore
docker run --rm \
  -v <volume>:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/backup.tar.gz -C /data
```

Bind mounts (`./data:/app/data`) sit directly on
the host filesystem — back them up like any other
directory.

## Prune Caution

`docker system prune` and `docker volume prune`
are destructive and non-reversible. Key behavior
to know before running:

- `docker volume prune` removes **all** volumes
  not currently mounted by a running container —
  including volumes for stopped or `down` Compose
  stacks that you intend to restart.
- `docker system prune -af` removes unused images
  too — including ones you deliberately pulled but
  haven't started yet.

Back up volume data before pruning. Use
`docker volume ls` and `docker system df -v` to
understand what will be removed.

## Port Conflicts

Before publishing a host port, verify it is free.
Follow `rules/port-check.md` for the full check.

Prefer Unix sockets over TCP for services behind
a reverse proxy — avoids the port entirely and
keeps the binding off the network stack. Pass the
socket into the container via a bind mount:

```yaml
volumes:
  - /run/myapp:/run/myapp
```

Then configure nginx/caddy to proxy to the socket.
