# Image Management and Creation

## Explicit Tags

**Never use `latest`.** It is a moving target:
a `docker compose pull` silently replaces the
image, and `latest` means something different on
every registry. Always pin to a version tag.

For maximum reproducibility, pin to a digest:
`image: postgres:16.3-alpine3.20@sha256:<digest>`.
The tag is human-readable; the digest is the lock.

Always search for the current stable tag before
writing a Dockerfile or compose.yaml — do not
guess from training data.

## .dockerignore

Create `.dockerignore` before the first `docker
build`. Without it, the entire working directory
— including `.git`, `.env`, `node_modules`, and
any credentials — is sent to the daemon as build
context. Even if those files aren't copied into
the image, they transit the socket and inflate
build times.

## Dockerfile Best Practices

### Base Image

- Smallest image that meets the need:
  `alpine` > `slim` > full Debian/Ubuntu.
- Pin to a specific version tag, never `latest`.
- Prefer official images or Docker-verified
  publishers.

### Layer Caching

Order from least-changed to most-changed.
Dependency installation must come before
application code — a single code change
invalidates all subsequent layers:

```dockerfile
# Rarely changes → runs from cache
COPY requirements.txt .
RUN pip install -r requirements.txt

# Changes on every commit → always re-runs
COPY . .
```

Getting this order wrong is the single most
common cause of slow builds.

### Non-Root User

See `references/security.md` for the full
tradeoff between `USER` in the Dockerfile and
`user:` in compose.yaml. Rule of thumb: if you
own the image, set `USER` in the Dockerfile and
`chown` files in the same build stage.

### COPY vs ADD

Use `COPY` for local files. `ADD` has implicit
behaviour (tar auto-extraction, remote URLs) that
makes Dockerfiles harder to reason about. The
only common legitimate use of `ADD` is extracting
a local tar archive in one step.

### Exec Form for ENTRYPOINT and CMD

Always use exec form: `["executable", "arg"]`,
not shell form: `executable arg`. Shell form
wraps the process in `/bin/sh -c`, which becomes
PID 1. Signals like SIGTERM go to the shell, not
the application — graceful shutdown breaks.

```dockerfile
# Correct — app receives SIGTERM
ENTRYPOINT ["python", "-m", "gunicorn"]

# Wrong — /bin/sh receives SIGTERM, app is orphaned
ENTRYPOINT python -m gunicorn
```

### Multi-Stage Builds

Keep build tooling out of the final image. Copy
only the compiled artifact into a minimal final
stage:

```dockerfile
FROM golang:1.22 AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /app ./cmd/server

FROM scratch
COPY --from=builder /app /app
ENTRYPOINT ["/app"]
```

Common patterns:
- Go: `golang` builder → `scratch` or `alpine`
- Node SPA: `node` builder → `nginx:alpine`
- Python: full image for pip → `python:slim` for
  runtime

### Secrets at Build Time

`ARG` values passed during `docker build` are
visible in `docker history` — do not use `ARG`
for secrets. Use `--secret` with BuildKit:

```dockerfile
RUN --mount=type=secret,id=mytoken \
    curl -H "Auth: $(cat /run/secrets/mytoken)" …
```

The secret is never written to a layer.

### Health Check

Define a `HEALTHCHECK` so Docker and Compose know
when the container is actually ready, not just
running. Without it, `depends_on: condition:
service_healthy` in compose.yaml has nothing to
evaluate and Compose will error. See
`references/compose.md` for the full `depends_on`
readiness pattern.

### Dockerfile Checklist

- [ ] Explicit base image tag (no `latest`)
- [ ] `.dockerignore` present
- [ ] Dependencies before application code
- [ ] `USER` set (non-root), files chowned first
- [ ] Exec form for `ENTRYPOINT`/`CMD`
- [ ] No secrets in `ARG`, `ENV`, or `COPY`ed
      files
- [ ] Multi-stage build if build tooling is heavy
- [ ] `HEALTHCHECK` defined
