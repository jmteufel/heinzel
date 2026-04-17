---
name: docker
description: >
  Load when Docker is mentioned, detected, or being
  worked with — installation, Compose, container
  operations, image management, and security.
---

## Firewall Warning

**Docker rewrites iptables directly and bypasses
ufw and firewalld.** A container published with
`-p 80:80` is reachable from the internet even
when ufw/firewalld has that port closed.

Mitigations (choose one):

- **Loopback bind** — `-p 127.0.0.1:80:80` for
  services behind a reverse proxy. Safest default.
- **`DOCKER-USER` chain** — iptables rules Docker
  cannot override.
- **Disable Docker iptables** —
  `"iptables": false` in `daemon.json`, then
  manage routing manually.

**Discuss with the user before publishing any port
on a server that has a firewall.**

## References

Load the relevant section on demand:

- `references/installation.md` — installing Docker
  from official repos per distro, daemon.json.
- `references/compose.md` — Docker Compose v2
  commands and compose file conventions.
- `references/operations.md` — container lifecycle,
  logs, exec, volumes, port conflicts.
- `references/images.md` — image management,
  Dockerfile best practices, multi-stage builds.
- `references/security.md` — rootless Docker,
  capabilities, secrets, hardening checklist.
