# Security Audit — Check Reference

Complete list of all checks performed by this skill.
Thresholds for each check are in `thresholds.md`.

## Linux Checks (`scripts/linux.sh`)

| Section tag             | Check                                      | Needs root          |
|-------------------------|--------------------------------------------|---------------------|
| `=== SSH_AUTH ===`      | SSH password authentication                | preferred; fallback unprivileged |
| `=== SSH_HARDENING ===` | PermitRootLogin, weak algos, MaxAuthTries, X11Forwarding | preferred; fallback unprivileged |
| `=== FIREWALL ===`      | Firewall active and default incoming policy | no                 |
| `=== EMPTY_PASSWORDS ===` | Accounts with empty /etc/shadow field    | **yes**             |
| `=== UID0 ===`          | Accounts with UID 0 other than root        | no                  |
| `=== SYSTEM_ACCOUNTS ===` | System accounts with interactive login shells | no            |
| `=== LISTENING ===`     | Listening TCP/UDP ports                    | process names only  |
| `=== SYSCTL ===`        | ASLR, IP forwarding, ICMP redirects, SUID core dumps | no   |
| `=== WORLD_WRITABLE ===` | World-writable files in /etc /usr /bin /sbin | no            |
| `=== SUID_SGID ===`     | SUID/SGID binaries system-wide             | no                  |
| `=== TMP_MOUNTS ===`    | Mount options for /tmp and /dev/shm        | no                  |
| `=== CRON_PERMS ===`    | Permissions on cron directories            | some dirs may need root |
| `=== UNOWNED ===`       | Files without a valid owner/group          | no                  |
| `=== FAIL2BAN ===`      | fail2ban service status                    | no                  |

## macOS Checks (`scripts/macos.sh`)

| Section tag               | Check                               | Needs root |
|---------------------------|-------------------------------------|------------|
| `=== SSH_REMOTE_LOGIN ===` | Whether SSH (Remote Login) is enabled | no       |
| `=== SSH_AUTH ===`        | SSH password authentication         | no         |
| `=== SSH_HARDENING ===`   | PermitRootLogin, weak algos, MaxAuthTries | no    |
| `=== FIREWALL ===`        | Application Firewall status         | no         |
| `=== LISTENING ===`       | Listening TCP ports                 | no (sudo for all processes) |
| `=== IP_FORWARD ===`      | IP forwarding (net.inet.ip.forwarding) | no      |
| `=== SIP ===`             | System Integrity Protection         | no         |
| `=== FILEVAULT ===`       | Full disk encryption (FileVault)    | no         |
| `=== GATEKEEPER ===`      | Gatekeeper / app notarisation       | no         |
