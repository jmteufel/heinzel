---
name: antipatterns
description: Load before executing any request that installs software, creates
  or configures services, changes file permissions, modifies firewall rules, or
  chooses storage locations — check for common anti-patterns and suggest better
  alternatives.
---

## When to Check

Trigger on user requests that:
- Install software or runtimes
- Create or configure services
- Change file permissions or ownership
- Modify firewall rules or network exposure
- Choose file storage locations

Skip: read-only commands, proactive Claude actions, housekeeping, security
audit.

## Protocol

1. **Detect** — match the request against the catalog below
2. **Suggest** — if matched:
   ```
   **Suggestion:** Instead of <X>, <alternative> — <why in one sentence>.
   Proceed with <alternative>, or <original> as requested?
   ```
   3–4 lines max. No lecturing.
3. **Respect override** — user confirms original: execute immediately, log
   `(user override: <what>)` in changelog, don't repeat in this session.

Advisory only — never refuse after an informed override.

## Always Intercept

High risk — almost never correct. Always raise an alternative, even if
the user seems sure.

- `chmod 777` / `chmod -R 777` → identify actual owner/group; use 750, 644
- `curl | bash` (or `wget | sh`) as root for unknown software → distro
  package or official repo. Known-safe exceptions: mise, Ollama, rustup.
- Disabling SELinux/AppArmor → check audit logs; create targeted exception
- Persistent data in `/tmp` → `/etc` config, `/var` data, `/opt` or `/srv`
  apps
- Cron job that restarts a service → diagnose the crash; use systemd
  `Restart=on-failure`
- Packages from Debian testing/unstable/sid or mixing Ubuntu releases →
  backports, upstream repo, static binary, or mise first. Only pin a
  single package from testing as absolute last resort with user override.
  Cross-reference: `/debian` skill (Stable Branch Only)

## Intercept Once

Usually suboptimal but has valid uses. Raise once; respect override.

- Runtime via distro package manager → `mise use --global <runtime>@<ver>`
  Cross-reference: `/mise` skill
- `nohup` / `screen` / `&` for daemons → create a systemd unit file
- Binding services to `0.0.0.0` → `127.0.0.1` or Unix socket. Databases
  especially must never bind to all interfaces without explicit need.
- Opening application ports directly in firewall → nginx reverse proxy +
  TLS on 443

## Anti-Pattern Catalog

### Permissions & Security

- `chmod 666` on sensitive files → 640 or 600 with correct owner/group
- `docker --privileged` without justification → use `--cap-add` instead
- Application server running as root → create a dedicated service user
  Cross-reference: `rules/deployment.md`
- Compiling from source when distro package exists → prefer packages;
  source builds don't get automatic security updates

### Network & Exposure

- App port directly exposed to internet (3000, 4000, 8080…) → nginx
  reverse proxy with TLS on 443
  Cross-reference: `rules/port-check.md`
- Broad firewall port ranges (e.g. 8000–9000) → open individual ports;
  restrict source IPs where possible

### File & Storage

- Application data in `/root` or user home → `/opt/<app>` or `/srv/<app>`
  with a dedicated user
- Hardcoded temp file paths (`/tmp/myfile`) → `mktemp` or `mktemp -d`

### Maintenance Shortcuts

- Disabling automatic security updates → fix the package conflict or pin
  only the affected package
- `--force` on package managers (`apt --force-yes`, `rpm --force`) →
  understand and resolve the conflict properly
- Editing package-managed config files in `/etc` → use `.d/` drop-ins,
  `dpkg-divert`, or the app's override mechanism
