---
name: docker
description: >
  Load when Docker is mentioned, detected, or being
  worked with — installation, Compose, container
  operations, image management, and security.
---

## Firewall Warning

**Docker bypasses ufw and firewalld.** This is not
a bug or misconfiguration — it is by design.

When a port is published, Docker inserts DNAT rules
into the iptables `nat/PREROUTING` chain. Incoming
traffic is rewritten to the container's IP before
the `filter/INPUT` chain is ever evaluated. ufw and
firewalld manage the `INPUT` chain. They never see
the traffic. A port can be closed in ufw and wide
open to the internet via Docker simultaneously.

Mitigations (choose one):

- **Loopback bind** — `-p 127.0.0.1:80:80`. Docker
  still creates the DNAT rule, but only for the
  loopback interface, so external packets never
  match it. Right default for services behind a
  reverse proxy.
- **`DOCKER-USER` chain** — Docker inserts this
  chain into `filter/FORWARD` before its own rules.
  iptables rules added here run first and can block
  traffic Docker would otherwise allow.
- **Disable Docker iptables** —
  `"iptables": false` in `daemon.json`. Docker
  stops managing routing entirely; you own it.

**Discuss with the user before publishing any port
on a server that has a firewall.**

## References

Load the relevant section on demand:

- `references/installation.md` — installing Docker
  from official repos per distro, daemon.json.
- `references/compose.md` — Docker Compose v2
  conventions, depends_on readiness, resource
  limits, env var mechanisms.
- `references/operations.md` — container lifecycle,
  logs, exec, volumes, port conflicts.
- `references/images.md` — image management,
  Dockerfile best practices, multi-stage builds.
- `references/security.md` — socket mounting
  risks, no-new-privileges, rootless Docker,
  capabilities, non-root user tradeoffs, secrets,
  hardening checklist.
