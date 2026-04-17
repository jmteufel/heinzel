# Docker Security

## Rootless Docker

Rootless Docker runs the daemon and containers
without root privileges. Preferred for all
non-privileged workloads.

**Supported:** Debian 10+, Ubuntu 20.04+,
RHEL 8+, Fedora 31+.

Install rootless mode (as the target user, not
root):

```bash
dockerd-rootless-setuptool.sh install
```

The socket path changes:
`unix:///run/user/<uid>/docker.sock`

Set `DOCKER_HOST` for CLI use:

```bash
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
```

Limitations: some network modes and host-port
bindings below 1024 require additional setup.

## Privileged Containers

**Never use `--privileged` without explicit user
approval.** It grants the container nearly
complete access to the host kernel and devices —
equivalent to running as root on the host.

If a container claims to need `--privileged`,
investigate first:
- Often only one or two capabilities are actually
  needed — use `--cap-add` instead.
- Device access: use `--device /dev/foo` rather
  than full `--privileged`.

## docker Group

**Avoid adding users to the `docker` group.**
Group membership grants passwordless root
equivalent via `docker run --rm -v /:/host alpine`.

Safer alternatives:
- Use rootless Docker per user.
- Use `sudo docker` with a specific `sudoers`
  rule if rootless is not an option.

## Capabilities

Drop all capabilities and add only what the
application needs:

```bash
docker run \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  <image>
```

Common capabilities actually needed:
- `NET_BIND_SERVICE` — bind ports below 1024
- `CHOWN` — change file ownership at startup
- `SETUID`/`SETGID` — switch UID at startup

Avoid: `SYS_ADMIN`, `SYS_PTRACE`, `NET_ADMIN`,
`DAC_OVERRIDE` (usually a sign of a misconfigured
image).

## Non-Root UID

Run containers as a non-root user when the image
supports it:

```bash
docker run --user 1001:1001 <image>
```

Or set in `compose.yml`:

```yaml
services:
  app:
    user: "1001:1001"
```

## Read-Only Filesystem

Make the container filesystem read-only and add
tmpfs for writable directories:

```bash
docker run \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid \
  --tmpfs /run:rw,noexec,nosuid \
  <image>
```

In `compose.yml`:

```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp:exec
      - /run
```

## Secrets

- **Never pass secrets as environment variables**
  if avoidable — they appear in `docker inspect`
  and process listings.
- Use Docker Secrets (Swarm) or a secrets manager
  (Vault, AWS SSM) for production.
- For simpler setups, bind-mount a secrets file
  from a protected host path (mode 0400):

  ```bash
  docker run \
    -v /etc/myapp/secret.key:/run/secrets/key:ro \
    <image>
  ```

- Never bake secrets into images — they persist
  in layer history even after `RUN rm`.

## Network Isolation

- Services that do not need to communicate should
  be on separate networks.
- Disable inter-container communication when not
  needed (`--icc=false` in `daemon.json`).
- Internal-only services: set `internal: true` on
  the Compose network — no outbound internet.

  ```yaml
  networks:
    backend:
      internal: true
  ```

## Security Hardening Checklist

- [ ] Rootless Docker where possible
- [ ] No `--privileged` without approval
- [ ] No users in `docker` group
- [ ] `--cap-drop=ALL` + explicit `--cap-add`
- [ ] Non-root `USER` in Dockerfile or `--user`
  at runtime
- [ ] `--read-only` + tmpfs for writable paths
- [ ] No secrets in env vars or image layers
- [ ] Internal Compose network for backend
  services
- [ ] Firewall: loopback-bind published ports
  (see main skill)
