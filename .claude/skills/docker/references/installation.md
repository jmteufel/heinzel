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

## Post-Install Configuration

Configure `daemon.json` immediately after
installing, before creating any networks or
containers. See `references/config.md`.
