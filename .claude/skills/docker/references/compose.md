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

Never put secrets directly in `compose.yaml`.
Use an `.env` file (gitignored) with `env_file:`.
The `.env` file is auto-loaded for variable
substitution, but `env_file:` is required to pass
variables into the container environment.

## Networks

Compose creates a default bridge network for each
project. Services communicate by service name
within that network. Add explicit named networks
only when services across multiple compose projects
need to reach each other.

Internal-only services that should have no outbound
internet access: `internal: true` on the network.

## Updating Images

Pull first, then up — Compose only recreates
containers whose image or config changed. To force
all containers to recreate, use `--force-recreate`.
