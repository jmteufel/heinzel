# Housekeeping — Check Reference

Complete list of all checks performed by this skill.
Thresholds for each check are in `thresholds.md`.
Service checks are in `service-checks.md`.

## Baseline Checks — Linux (`scripts/linux.sh`)

| Section tag        | Check                        | Needs root |
|--------------------|------------------------------|------------|
| `=== DISTRO ===`   | OS and distro detection      | no         |
| `=== DISK ===`     | Filesystem usage             | no         |
| `=== MEMORY ===`   | RAM and swap usage           | no         |
| `=== LOAD ===`     | System load vs core count    | no         |
| `=== REBOOTS ===`  | Uptime and reboot history    | no         |
| `=== FAILED_UNITS ===` | Failed systemd units    | no         |
| `=== NTP ===`      | NTP synchronisation status   | no         |
| `=== LOG_ANOMALIES ===` | OOM kills, I/O errors, failed SSH logins | no |
| `=== SSL_CERTS ===` | Let's Encrypt expiry + port-443 fallback | no |
| `=== UPDATES ===`  | Pending security updates     | **yes**    |
| `=== AUTO_UPDATES ===` | Auto-update mechanism status | no    |
| `=== FIREWALL ===` | Firewall active and policy   | no         |
| `=== KERNEL ===`   | Running vs installed kernel  | no         |

## Baseline Checks — macOS (`scripts/macos.sh`)

| Section tag          | Check                          | Needs root |
|----------------------|--------------------------------|------------|
| `=== DISK ===`       | Filesystem usage               | no         |
| `=== MEMORY ===`     | RAM via vm_stat                | no         |
| `=== LOAD ===`       | System load vs core count      | no         |
| `=== UPDATES ===`    | Pending software updates       | no         |
| `=== AUTO_UPDATES ===` | Critical auto-update setting | no         |
| `=== HOMEBREW ===`   | Outdated Homebrew packages     | no         |
| `=== FIREWALL ===`   | Application Firewall status    | no         |
| `=== SMART ===`      | SMART disk health              | no         |
| `=== TIME_SYNC ===`  | NTP time offset                | no         |

## Service-Specific Checks (`service-checks.md`)

Triggered by entries in `memory/servers/<hostname>/memory.md`.

| Service                  | Trigger keyword              |
|--------------------------|------------------------------|
| PostgreSQL               | PostgreSQL                   |
| Backups (apgsqlbackup)   | autopostgresqlbackup         |
| Cross-backup (rsync)     | cross-backup, rsync backups  |
| Docker                   | Docker                       |
| nginx                    | nginx                        |
| Ollama                   | Ollama                       |
| node_exporter            | node_exporter, Prometheus    |
| NVIDIA GPU               | NVIDIA, GPU                  |
| MariaDB / MySQL          | MariaDB, MySQL               |
| WireGuard                | WireGuard                    |

## Version Status

Checked via `rules/version-check.md` (will become
a skill). Appended as a "Versions" section in the
report.
