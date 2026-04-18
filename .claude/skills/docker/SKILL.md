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
  from official repos per distro.
- `references/config.md` — data-root placement,
  daemon.json defaults, logging, security-relevant
  daemon options.
- `references/compose.md` — compose.yaml
  conventions, env var mechanisms, depends_on
  readiness, init containers, resource limits,
  profiles, compose.override.yaml.
- `references/operations.md` — volume backup/
  restore, prune/down -v caution, port conflicts.
- `references/debugging.md` — containers that
  exit immediately, entrypoint override, OOM
  diagnosis, compose-specific debugging.
- `references/network-namespace.md` — VPN/proxy
  sidecar pattern, shared network namespaces.
- `references/images.md` — Dockerfile best
  practices, layer caching, multi-stage and
  multi-arch builds, tini, image tags.
- `references/security.md` — non-root user
  tradeoffs, vulnerability scanning, socket
  mounting risks, capabilities, rootless Docker,
  secrets, hardening checklist.
- `references/zero-downtime-updates.md` —
  graceful shutdown, Traefik health-based drain,
  blue-green with compose projects, rollback.
- `references/database-lifecycle.md` — schema
  migration backward compatibility, major version
  upgrades, backup schedule with profiles, PITR.
- `references/disaster-recovery.md` — what to
  back up, recovery runbook, RTO/RPO drills.
- `references/log-management.md` — default
  driver disk risk, centralized logging options,
  non-blocking driver config.
- `references/scheduling-in-containers.md` —
  busybox crond vs supercronic, PID 1 and zombie
  reaping, tini pairing.
