# Docker Security

## Non-Root User

Running a container process as root is the most
common Docker security mistake. The right fix
depends on who owns the image.

### Dockerfile `USER` (preferred when you own the
image)

Set the user in the Dockerfile. This is the right
layer: ownership of files can be fixed at build
time, and the UID becomes part of the image
contract.

```dockerfile
RUN useradd -r -u 1001 appuser && \
    chown -R appuser:appuser /app
USER appuser
```

- The `chown` must come before `USER` — after the
  switch you no longer have permission to change
  ownership.
- Visible in image metadata; anyone running the
  image gets the right default without thinking
  about it.
- Can still be overridden at runtime with `--user`.

### Runtime `--user` / compose `user:` (for
third-party images)

Overrides the image's `USER` at runtime without
rebuilding. Useful when the upstream image runs as
root and you want to harden it.

**Critical tradeoff:** runtime `--user` changes
the UID of the process but does NOT change file
ownership inside the container. If the image was
built with files owned by root (uid 0) and you
run it as uid 1001, the process will fail to read
or write those files.

Before using `user:` on a third-party image:
- Check what UID the image was designed for:
  `docker inspect --format '{{.Config.User}}' <image>`
- Many official images (postgres, redis, nginx)
  already use a non-root user with correct
  ownership — overriding it may break things.
- If the image has an explicit non-root user but
  runs as root by default, switching to that UID
  is safe: `user: "1001:1001"` in `compose.yaml`.
- If files in the image are all owned by root,
  runtime `--user` will produce permission errors.
  The fix is a custom image with a proper `chown`.

**Anti-pattern:** blindly adding `user: "1001:1001"`
to every service in `compose.yaml` without
checking the image's ownership model. It looks
like a security improvement but often just breaks
the service in a confusing way.

### Summary

| Scenario | Approach |
|---|---|
| You build the image | `USER` in Dockerfile + `RUN chown` |
| Third-party image, non-root UID available | `user:` in compose.yaml |
| Third-party image, files owned by root | Build a wrapper image with `chown` |

## Rootless Docker

Runs the daemon and containers without root
privileges. Preferred for all non-privileged
workloads. Supported on Debian 10+, Ubuntu 20.04+,
RHEL 8+, Fedora 31+.

Set up as the target user (not root):
`dockerd-rootless-setuptool.sh install`

Limitations: some network modes and port bindings
below 1024 require extra setup.

## Privileged Containers

**Never use `--privileged` without explicit user
approval.** It grants the container nearly complete
access to the host kernel and devices — equivalent
to running as root on the host.

When a container claims to need `--privileged`,
investigate: usually only one or two specific
capabilities are actually needed. Use
`--cap-add=<CAP>` instead. For device access,
use `--device /dev/foo` rather than full privilege.

Common capabilities actually needed:
- `NET_BIND_SERVICE` — bind ports below 1024
- `CHOWN` — change file ownership at startup
- `SETUID`/`SETGID` — switch UID at startup

Avoid adding: `SYS_ADMIN`, `SYS_PTRACE`,
`NET_ADMIN`, `DAC_OVERRIDE` — their presence in
a request usually signals a misconfigured image.

## docker Group

**Avoid adding users to the `docker` group.**
Group membership is equivalent to passwordless
root — a group member can trivially escalate:
`docker run --rm -v /:/host alpine chroot /host`.

Safer alternatives: rootless Docker per user, or
`sudo docker` with a narrow `sudoers` rule.

## Read-Only Filesystem

Mark the container filesystem read-only and add
tmpfs mounts for paths the process needs to write:

```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp
      - /run
```

This limits the blast radius if the container is
compromised — the attacker cannot write to the
container's filesystem.

## Secrets

- **Never pass secrets as environment variables**
  if avoidable — they appear in `docker inspect`,
  `/proc/<pid>/environ`, and often in logs.
- Never bake secrets into images — they persist in
  layer history even after `RUN rm`.
- For simple setups, bind-mount a secrets file
  from a host path with mode 0400.
- For production, use Docker Secrets (Swarm) or an
  external secrets manager.

## Network Isolation

Services that don't need to communicate should be
on separate networks — Compose's default bridge
puts all services in the same network and they can
reach each other freely.

For backend services with no outbound internet
requirement, set `internal: true` on the network.

## Security Hardening Checklist

- [ ] Non-root `USER` in Dockerfile (owned images)
      or verified `user:` in compose.yaml (third-
      party images — check ownership first)
- [ ] Rootless Docker where possible
- [ ] No `--privileged` without approval
- [ ] `--cap-drop=ALL` + explicit `--cap-add`
- [ ] No users in `docker` group
- [ ] `read_only: true` + tmpfs for writable paths
- [ ] No secrets in env vars or image layers
- [ ] Separate networks for unrelated services
- [ ] Firewall: loopback-bind published ports
      (see main skill)
