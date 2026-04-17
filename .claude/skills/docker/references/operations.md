# Container Operations

## Lifecycle

```bash
docker ps -a                  # list all containers
docker start <name>           # start stopped container
docker stop <name>            # graceful stop (SIGTERM)
docker kill <name>            # immediate stop (SIGKILL)
docker restart <name>         # stop + start
docker rm <name>              # remove stopped container
docker rm -f <name>           # force-remove running
docker rename <old> <new>     # rename container
```

## Logs

```bash
docker logs <name>            # all logs
docker logs -f <name>         # follow (tail -f)
docker logs --tail 100 <name> # last 100 lines
docker logs --since 1h <name> # last hour
docker logs --since \
  2024-01-15T10:00:00 <name>  # since timestamp
```

## Shell and Debugging

```bash
docker exec -it <name> sh     # sh shell
docker exec -it <name> bash   # bash (if available)
docker exec -it <name> \
  <cmd>                       # run any command
docker inspect <name>         # full JSON config
docker inspect <name> \
  --format '{{.State.Status}}'  # single field
docker stats                  # live resource usage
docker stats --no-stream      # one-shot snapshot
docker top <name>             # processes in container
docker diff <name>            # filesystem changes
```

## Volumes

### List and Inspect

```bash
docker volume ls
docker volume inspect <name>
```

### Backup Named Volume

```bash
docker run --rm \
  -v <volume>:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz -C /data .
```

### Restore Named Volume

```bash
docker run --rm \
  -v <volume>:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/backup.tar.gz -C /data
```

### Caution with Prune

`docker volume prune` removes **all** unused
volumes — including ones for stopped containers
you intend to restart. Always back up first or
specify volumes explicitly.

## Disk Usage

```bash
docker system df              # summary
docker system df -v           # per-object detail
```

## Cleanup

```bash
# Remove stopped containers and dangling images
docker system prune -f

# Also remove unused named images (careful)
docker system prune -af

# Remove only dangling images
docker image prune -f

# Remove only stopped containers
docker container prune -f
```

## Port Conflicts

Before publishing a host port, verify it is free:

```bash
ss -tlnp | grep :<port>
```

Follow `rules/port-check.md` for the full check
procedure. Prefer Unix sockets (`--network host`
or a socket bind mount) over TCP ports when the
service is behind a reverse proxy.

## Networks

```bash
docker network ls
docker network inspect <name>
docker network connect <net> <container>
docker network disconnect <net> <container>
```
