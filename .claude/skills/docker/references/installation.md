# Docker Installation

**Always install from Docker's official repo,
not the distro package.** Distro-packaged Docker
is typically several major versions behind and
lacks Docker Compose v2 (`docker-compose-plugin`).

Always search for the current stable release before
installing. The official install guide at
https://docs.docker.com/engine/install/ has
per-distro instructions that stay current.

The packages to install are always:
`docker-ce`, `docker-ce-cli`, `containerd.io`,
`docker-buildx-plugin`, `docker-compose-plugin`.

After installing, enable the service and verify:

```bash
systemctl enable --now docker
docker version
```

## daemon.json

Path: `/etc/docker/daemon.json`. Back up before
editing (`rules/backups.md`). Apply changes:

```bash
systemctl reload docker
# if reload is insufficient:
systemctl restart docker
```

Useful defaults to set on every server:

```json
{
  "log-driver": "journald",
  "log-opts": { "max-size": "10m" },
  "default-address-pools": [
    { "base": "172.16.0.0/12", "size": 24 }
  ]
}
```

- `log-driver: journald` — integrates container
  logs with `journalctl` instead of writing
  separate JSON files under `/var/lib/docker`.
- `default-address-pools` — overrides Docker's
  default `172.17.0.0/16`, which commonly
  conflicts with existing RFC 1918 ranges on
  corporate or datacenter networks. Set it on
  first install before any networks are created.
