# Image Management and Creation

## Image Management

```bash
docker images                 # list local images
docker pull <image>:<tag>     # pull specific tag
docker tag <src> <dst>        # retag image
docker rmi <image>            # remove image
docker image prune -f         # remove dangling only
docker system prune -af       # remove all unused
```

**Always use explicit tags.** Never use `latest`
in production — it changes without notice and
breaks reproducible deployments.

```bash
# Bad
image: postgres:latest

# Good
image: postgres:16.3-alpine3.20
```

Pin to a digest for maximum reproducibility:

```bash
docker pull postgres:16.3-alpine3.20
docker inspect postgres:16.3-alpine3.20 \
  --format '{{index .RepoDigests 0}}'
# postgres@sha256:<digest>
```

## Building Images

```bash
docker build -t <name>:<tag> .
docker build -t <name>:<tag> \
  -f path/to/Dockerfile .
docker build --no-cache \
  -t <name>:<tag> .           # force full rebuild
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t <name>:<tag> .           # multi-arch
```

Always search for the current stable base image
tag before writing a Dockerfile.

## .dockerignore

Always create `.dockerignore` to exclude files
from the build context:

```
.git
.env
*.log
node_modules
__pycache__
.pytest_cache
*.pyc
```

A missing `.dockerignore` can send secrets or
gigabytes of data to the daemon unnecessarily.

## Dockerfile Best Practices

### Base Image

- Use the smallest image that meets the need:
  `alpine` > `slim` > `full`.
- Pin base image to a specific version tag, never
  `latest`.
- Prefer official images or verified publishers.

```dockerfile
# Good
FROM python:3.12.4-slim-bookworm

# Bad
FROM python:latest
```

### Layer Caching

Order instructions from least-changed to
most-changed. Dependency install before code copy:

```dockerfile
# Dependencies (rarely changes)
COPY requirements.txt .
RUN pip install -r requirements.txt

# Application code (changes often)
COPY . .
```

### Non-Root User

Run the application as a non-root user:

```dockerfile
RUN useradd -r -u 1001 appuser
USER appuser
```

Or use the numeric UID directly if the image
already has a non-root user:

```dockerfile
USER 1001
```

### COPY vs ADD

- Use `COPY` for local files — it is explicit.
- Use `ADD` only for remote URLs or tar
  auto-extraction (rare; wget + COPY is clearer).

### Multi-Stage Builds

Keep the final image lean by building in one
stage and copying only the artifact:

```dockerfile
# Build stage
FROM golang:1.22 AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /app ./cmd/server

# Final stage
FROM scratch
COPY --from=builder /app /app
ENTRYPOINT ["/app"]
```

Common patterns:
- `golang` → `scratch` or `alpine` for Go binaries
- `node` → `nginx:alpine` for SPA frontends
- `python` build → `python:slim` for smaller images

### Environment Variables and Secrets

- Do not `COPY` `.env` files or credentials into
  the image — they persist in the layer history.
- Pass secrets at runtime via environment
  variables, bind mounts, or Docker secrets.
- Use `ARG` (build-time) vs `ENV` (runtime)
  correctly — `ARG` values are still visible in
  `docker history`.

### Entrypoint vs CMD

```dockerfile
# Fixed executable, variable args
ENTRYPOINT ["python", "-m", "gunicorn"]
CMD ["myapp:app", "--bind", "0.0.0.0:8000"]

# All overridable — good for dev images
CMD ["python", "manage.py", "runserver"]
```

Use exec form (`["cmd", "arg"]`), not shell form
(`cmd arg`) — shell form wraps in `/bin/sh -c`
and breaks signal handling (SIGTERM won't reach
the process).

### Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s \
  --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8000/health \
    || exit 1
```

### Minimal Final Checklist

- [ ] Explicit base image tag (no `latest`)
- [ ] `.dockerignore` present
- [ ] Dependencies copied and installed before
      application code
- [ ] Non-root `USER` declared
- [ ] Exec form for `ENTRYPOINT`/`CMD`
- [ ] No secrets or `.env` copied into image
- [ ] Multi-stage build if build tooling is heavy
