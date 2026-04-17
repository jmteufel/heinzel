# Docker Compose v2

Use `docker compose` (v2, part of Docker Engine).
**Do not use `docker-compose`** (v1, deprecated and
removed from current Docker installs).

## Common Commands

```bash
docker compose up -d          # start detached
docker compose down           # stop and remove
docker compose down -v        # also remove volumes
docker compose pull           # pull latest images
docker compose logs -f        # follow all logs
docker compose logs -f <svc>  # follow one service
docker compose ps             # list services
docker compose restart        # restart all
docker compose restart <svc>  # restart one service
docker compose exec <svc> sh  # shell into service
docker compose config         # validate and dump
docker compose top            # show processes
```

## compose.yml Conventions

### Image Tags

Always pin to explicit tags — never `latest`:

```yaml
services:
  web:
    image: nginx:1.27.3-alpine
```

### Restart Policy

```yaml
services:
  app:
    restart: unless-stopped
```

Use `unless-stopped` for most services.
Use `on-failure` for one-shot or init containers.

### Volumes: Named vs Bind-Mount

**Named volume** — data managed by Docker, survives
`down`, portable:

```yaml
services:
  db:
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

**Bind mount** — host path exposed directly, easier
to back up and inspect:

```yaml
services:
  app:
    volumes:
      - ./data:/app/data
```

Prefer bind mounts for config files and data you
need to back up or edit from the host. Use named
volumes for opaque database storage.

### Environment Variables

Never put secrets directly in `compose.yml`.
Use an `.env` file (gitignored) or a secrets
manager:

```yaml
services:
  app:
    env_file: .env
```

### Port Binding

Bind to loopback for services behind a reverse
proxy:

```yaml
services:
  app:
    ports:
      - "127.0.0.1:3000:3000"
```

Only expose to `0.0.0.0` when the service must
be directly reachable. See the firewall warning
in the main skill.

### Networks

Compose creates a default bridge network. Add
explicit networks when services across multiple
compose files need to communicate:

```yaml
networks:
  shared:
    external: true
```

Create the network first: `docker network create shared`.

## Updating Services

```bash
docker compose pull           # pull new images
docker compose up -d          # recreate if changed
```

Compose only recreates containers whose image or
config changed. Use `--force-recreate` to restart
all regardless.
