# Debugging Containers

## Container Exits Immediately

You cannot `exec` into a dead container. The
two-step approach: check logs first, then get a
shell by overriding the entrypoint.

```bash
# Step 1 — what did it say before dying?
docker logs <name>

# Step 2 — get a shell instead of running the app
docker run --rm -it --entrypoint sh <image>
```

If the image has no shell (`scratch` or `distroless`
base), use a debug image that shares the namespace:

```bash
docker run --rm -it \
  --pid container:<name> \
  --network container:<name> \
  busybox sh
```

For a Compose service:

```bash
docker compose run --rm --entrypoint sh <service>
```

This starts the service with a shell instead of its
normal command, using the same environment, volumes,
and networks defined in compose.yaml.

## Diagnosing Exit Reasons

```bash
# Exit code — 0 = clean, 1 = error, 137 = OOM/SIGKILL
docker inspect <name> \
  --format '{{.State.ExitCode}}'

# Was it OOM-killed?
docker inspect <name> \
  --format '{{.State.OOMKilled}}'

# Full state (status, started/finished, error)
docker inspect <name> \
  --format '{{json .State}}' | jq
```

Exit code 137 with `OOMKilled: true` means the
container exceeded its memory limit. Set or raise
`deploy.resources.limits.memory` in compose.yaml.

Exit code 1 usually means the application errored
at startup — check logs. Exit code 126/127 usually
means the command or entrypoint was not found.

## Keeping a Failing Container Alive

To inspect a container whose process exits
immediately, override the entrypoint to sleep:

```bash
docker run --rm -it \
  --entrypoint sleep <image> infinity
```

Then `exec` into it and replicate the failing
command manually to see the error interactively.

## Compose-Specific Debugging

```bash
# Validate compose.yaml syntax
docker compose config

# Start one service without its dependencies
docker compose run --rm --no-deps <service>

# See environment variables the container will see
docker compose run --rm <service> env

# Start in foreground (non-detached) to see output
docker compose up <service>
```

`docker compose config` catches YAML errors,
missing variables, and invalid keys before anything
starts — run it first when compose.yaml changes.
