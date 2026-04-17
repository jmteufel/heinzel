# Zero-Downtime Updates

## Graceful Shutdown First

Before worrying about the proxy, the container
must shut down cleanly. Docker sends SIGTERM on
stop and waits `stop_grace_period` before sending
SIGKILL:

```yaml
services:
  app:
    stop_grace_period: 30s
```

The default is 10s. Increase it for services with
long-running requests (background jobs, streaming,
file uploads). The app must catch SIGTERM, stop
accepting new connections, finish in-flight work,
then exit 0.

An app that ignores SIGTERM gets SIGKILL'd —
every in-flight request is dropped. No proxy
strategy can compensate for that.

## The Gap in `docker compose up`

`docker compose up -d` recreates containers whose
image or config changed. The old container stops
before the new one is healthy. Without a reverse
proxy that understands health state, there is a
window where requests fail.

`docker compose pull && docker compose up -d` is
acceptable for off-hours or low-traffic deploys.
For production with traffic, pair it with a
healthcheck-aware proxy.

## With Traefik

Traefik watches the Docker socket and updates
routing in real time. When a container is
recreated:

1. Old container stops → Traefik stops sending
   it new requests.
2. New container starts → Traefik waits until its
   healthcheck passes before routing to it.
3. No gap — provided a `HEALTHCHECK` is defined.

Without a `HEALTHCHECK` in the image, Traefik
routes to the new container immediately on start,
before the app is ready. Define a healthcheck on
every service Traefik routes to.

Traefik requires mounting the Docker socket. See
`references/security.md` for the risk and the
socket-proxy mitigation.

## With Caddy or nginx

Neither automatically drains an upstream when its
container is recreated.

**Manual upstream swap (minimal downtime):**
1. Start the new container on a different internal
   port or under a different compose project name.
2. Verify it is healthy.
3. Update the proxy config to point at the new
   container.
4. Reload the proxy without restarting it.
5. Stop the old container.

**Blue-green** — true zero downtime, see below.

## Blue-Green Deployment

Run two compose projects simultaneously. Switch
the proxy upstream between them:

```bash
# blue is currently live
docker compose -p app-green pull
docker compose -p app-green up -d

# verify green is healthy, then switch proxy
# upstream from blue to green, then:
docker compose -p app-blue down
```

The proxy references the green service by name on
a shared external Docker network. Both projects
must attach to the same network for the proxy to
reach either of them.

Trade-offs:
- Doubles resource usage during the cutover
  window.
- Requires a proxy reload or config change to
  switch upstreams.
- Instant rollback: start blue again, switch
  proxy back.

## Rollback

All strategies support rollback only if images
are pinned to explicit tags. `latest` makes it
impossible to know what was running before, and
`docker compose pull` may overwrite it.

- **Traefik:** change the image tag back in
  compose.yaml, `docker compose up -d`.
- **Blue-green:** start the old project, switch
  proxy back. Old containers are still present
  until explicitly removed.
