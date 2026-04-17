# Docker Compose v2

Use `docker compose` (v2, part of Docker Engine).
**Do not use `docker-compose`** (v1, deprecated and
removed from current Docker installs).

## File Naming

Name the file `compose.yaml` — it is the preferred
canonical name in the Docker v2 specification.
`docker-compose.yml` still works but is the legacy
name from v1. Discovery order when both exist:
`compose.yaml` wins.

## compose.override.yaml

Compose automatically loads and merges
`compose.override.yaml` from the same directory.
Override keys win; new keys are added. This is the
standard pattern for dev/prod splits without
maintaining separate file sets or `-f` flag chains.

Convention:
- `compose.yaml` — production baseline: no source
  mounts, no debug ports, no dev-only services.
- `compose.override.yaml` — dev additions: source
  bind-mounts, exposed debugger ports, dev tools.

```yaml
# compose.override.yaml
services:
  app:
    volumes:
      - ./src:/app/src       # live code reload
    ports:
      - "127.0.0.1:9229:9229"  # debugger
    environment:
      DEBUG: "true"
```

Never commit override files containing secrets or
personal paths. If the file is shared, it is code.

## Image Tags

Always pin to explicit tags — never `latest`. It
changes without notice and breaks reproducible
deployments.

Good: `image: postgres:16.3-alpine3.20`
Bad: `image: postgres:latest`

## Restart Policy

Use `unless-stopped` for persistent services.
Use `on-failure` for one-shot or init containers.
`always` restarts even after `docker compose down`,
which is rarely what you want.

## Volumes: Named vs Bind-Mount

**Named volume** — managed by Docker, survives
`docker compose down`, portable, opaque to the
host. Good for database storage.

**Bind mount** — host path exposed directly,
survives anything, easy to back up and inspect
from the host. Good for config files and data you
own.

Prefer bind mounts when you need to back up data
from the host or inspect it without entering the
container.

## Port Binding

Bind to loopback for services behind a reverse
proxy — not `0.0.0.0`. See the firewall warning
in the main skill: Docker bypasses ufw/firewalld,
so `0.0.0.0` binds are reachable from the internet
even when the firewall closes the port.

Good: `"127.0.0.1:3000:3000"`
Bad: `"3000:3000"` (binds `0.0.0.0` by default)

## Environment Variables

There are three distinct mechanisms — they are
not interchangeable:

- **`.env` file** (same directory as `compose.yaml`)
  — auto-loaded by Compose for variable
  *substitution inside the compose file* itself:
  `image: myapp:${VERSION}`. These variables are
  NOT automatically injected into containers.
- **`env_file:`** (service key) — reads a file and
  injects its contents into the *container's*
  environment. Not parsed by Compose; goes straight
  to the process.
- **`environment:`** (service key) — inline
  key=value pairs injected into the container.

Common mistake: putting secrets in `.env` and
assuming the container sees them. It doesn't
unless `env_file: .env` is also set.

Never commit `.env` files. Add to `.gitignore`.

## `depends_on` Does Not Mean Ready

`depends_on: - db` only waits for the `db`
container to *start*, not for the database to be
*accepting connections*. Apps that connect at
startup will fail with a race condition.

The correct pattern combines a `healthcheck` on
the dependency with `condition: service_healthy`:

```yaml
services:
  app:
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
```

Without the `healthcheck`, `condition:
service_healthy` has nothing to evaluate and
Compose will error. See `references/images.md`
for Dockerfile HEALTHCHECK guidance.

## Init Containers

For tasks that must complete before the app starts
— database migrations, schema checks, seed data —
use a one-shot service with `condition:
service_completed_successfully`:

```yaml
services:
  migrate:
    image: myapp
    command: ["python", "manage.py", "migrate"]
    restart: "no"
    depends_on:
      db:
        condition: service_healthy

  app:
    image: myapp
    depends_on:
      migrate:
        condition: service_completed_successfully
      db:
        condition: service_healthy
```

`service_completed_successfully` waits for the
container to exit with code 0. If the migration
fails (non-zero exit), the app does not start.
`restart: "no"` prevents Compose from restarting
the migration container on failure — let it fail
visibly instead of looping.

## Resource Limits

Without memory limits, a single runaway container
can consume all host memory and trigger the OOM
killer, taking down unrelated services. Set limits
on every production service:

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          memory: 512m
          cpus: "1.0"
        reservations:
          memory: 128m
```

`deploy.resources` is respected by Compose v2 in
standalone mode (no Swarm required). Set `limits`
to the maximum the service should ever use. Set
`reservations` to what it needs under normal load.

When a container exceeds its memory limit it is
killed by OOM. Size limits conservatively and
monitor actual usage with `docker stats` before
tightening.

## `container_name:` Anti-Pattern

Avoid setting `container_name:` in compose.yaml.

- It breaks `docker compose up --scale` — you
  cannot run multiple replicas of a service with
  a fixed container name.
- It creates collision risk when multiple compose
  projects run on the same server.
- It is unnecessary for inter-service networking:
  within a Compose project, services reach each
  other by *service name*, not container name.

The only reason to set it is to make a container
predictable for external scripts — which is a
sign those scripts should use service names or
labels instead.

## Profiles

Mark optional services with `profiles:` to keep
them out of the default `docker compose up`:

```yaml
services:
  app:
    image: myapp            # always starts

  debugger:
    image: busybox
    profiles: [dev]         # opt-in only

  exporter:
    image: prom/node-exporter
    profiles: [monitoring]
```

Activate with `--profile dev` or by setting
`COMPOSE_PROFILES=dev,monitoring` in the
environment. Services without `profiles:` always
start regardless of which profiles are active.

Use cases: dev tools, debuggers, monitoring
sidecars, load testing services — anything that
must never start automatically in production.

## Networks

Compose creates a default bridge network for each
project. Services communicate by service name
within that network. Add explicit named networks
only when services across multiple compose projects
need to reach each other.

Internal-only services with no outbound internet
requirement: `internal: true` on the network.

## Network Namespace Sharing (Sidecar)

For VPN/proxy sidecars and similar patterns, use
`network_mode: "service:<name>"` to share a
network namespace between containers. See
`references/network-namespace.md`.

## Updating Images

Pull first, then up — Compose only recreates
containers whose image or config changed. To force
all containers to recreate, use `--force-recreate`.
