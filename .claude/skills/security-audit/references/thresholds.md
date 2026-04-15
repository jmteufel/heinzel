# Security Audit Thresholds

Interpret the `=== SECTION ===` output from the
audit scripts against the rules below.

## SSH Authentication (`=== SSH_AUTH ===`)

Prefer `sshd -T` output (compiled config). Fall back
to config file parsing when `sshd_T=needs_root`.
On OpenSSH 8.8+, always check drop-in files in
`/etc/ssh/sshd_config.d/` — they may override the
main file.

- `passwordauthentication yes` → **WARN**
- `passwordauthentication no` → OK
- macOS: if `=== SSH_REMOTE_LOGIN ===` shows SSH
  off → **INFO** "SSH disabled — checks skipped"

## SSH Hardening (`=== SSH_HARDENING ===`)

### PermitRootLogin

- `yes` or `prohibit-password` → **INFO** (root SSH
  is normal in heinzel — informational only)
- `no` → OK

### Weak Algorithms

Flag as **WARN** if any of these appear:

- **Ciphers:** `3des-cbc`, `arcfour`, `arcfour128`,
  `arcfour256`, `blowfish-cbc`, `cast128-cbc`
- **MACs:** `hmac-md5`, `hmac-md5-96`,
  `hmac-sha1-96`, `umac-64@openssh.com`
- **KEX:** `diffie-hellman-group1-sha1`,
  `diffie-hellman-group-exchange-sha1`
- **Host key types:** `ssh-dss`

### MaxAuthTries

- Value > 4 → **INFO**
- Value ≤ 4 → OK

### X11Forwarding (Linux only)

- `yes` → **INFO**
- `no` → OK

## Firewall (`=== FIREWALL ===`)

### Linux — ufw

- Not installed or inactive → **WARN** "No active
  firewall"
- Active but default incoming not `deny` → **WARN**
- Active, default deny → OK

### Linux — firewalld

- Not running → **WARN** "No active firewall"
- Default zone target `ACCEPT` → **WARN** "Default
  zone target is ACCEPT (allows all incoming)"
- Zone target `default` (reject/drop) → OK

### macOS — Application Firewall

- Disabled → **INFO** (not WARN — common behind NAT)
- Enabled → OK

## Empty Password Accounts (`=== EMPTY_PASSWORDS ===`)

- Any account found → **CRITICAL** per account
- `needs_root` → add to Skipped section
- No accounts → OK

## UID 0 Accounts (`=== UID0 ===`)

- Only `root` → OK
- Any other account → **CRITICAL**

## System Accounts (`=== SYSTEM_ACCOUNTS ===`)

Expected exception: `root` (has `/bin/bash` or
`/bin/sh`). All other system accounts (UID < 1000)
with a login shell are unexpected.

- Any unexpected account → **WARN** per account
- Only expected exceptions → OK

## Listening Services (`=== LISTENING ===`)

Flag as **WARN** if any of these ports bind to
`0.0.0.0` or `::` instead of `127.0.0.1`/`::1`:

- 3306 — MySQL/MariaDB
- 5432 — PostgreSQL
- 6379 — Redis
- 27017 — MongoDB
- 11211 — Memcached

If the server's memory.md shows a legitimate reason
(e.g. replication), note OK with context. All other
listening services: report for review, no automatic
severity.

## Kernel / sysctl (`=== SYSCTL ===`)

### ASLR (`aslr=`)

- `0` → **CRITICAL** (disabled)
- `1` → **WARN** (partial)
- `2` → OK

### IP Forwarding (`ip_forward=`)

- `1` → **WARN** unless memory.md mentions WireGuard,
  VPN, or router role — then OK with note
- `0` → OK

### ICMP Redirect Acceptance (`icmp_redirects=`)

- `1` → **WARN**
- `0` → OK

### SUID Core Dumps (`suid_dumpable=`)

- `1` → **WARN**
- `0` or `2` → OK

## World-Writable Files (`=== WORLD_WRITABLE ===`)

- Any file found → **WARN** per file
- None → OK

## SUID/SGID Binaries (`=== SUID_SGID ===`)

Known-good binaries (do not flag): `sudo`, `su`,
`passwd`, `chsh`, `chfn`, `newgrp`, `gpasswd`,
`mount`, `umount`, `ping`, `ping6`, `fusermount`,
`fusermount3`, `pkexec`, `unix_chkpwd`, `crontab`,
`ssh-agent`, `at`, `expiry`, `wall`, `write`,
`dotlockfile`, `mount.nfs`, `mount.cifs`, `staprun`.

- Any binary not in list → **INFO** with full path
- Report total count

## /tmp and /dev/shm (`=== TMP_MOUNTS ===`)

- `/dev/shm` lacks `noexec` → **WARN**
- `/tmp` lacks `noexec` → **INFO**
- `/tmp` not a separate mount → **INFO**

## Cron Permissions (`=== CRON_PERMS ===`)

- Any directory world-writable → **CRITICAL**
- World-readable but not writable → **INFO**
- Owner root, no world access → OK

## Unowned Files (`=== UNOWNED ===`)

- Any file found → **INFO** per file
- None → OK

## fail2ban (`=== FAIL2BAN ===`)

- Not running / not installed → **INFO** (recommended
  but not critical when SSH uses key-only auth)
- Active → OK

## macOS: IP Forwarding (`=== IP_FORWARD ===`)

- `1` → **WARN** unless memory.md mentions WireGuard
  or VPN
- `0` → OK

## macOS: SIP (`=== SIP ===`)

- Disabled → **CRITICAL**
- Enabled → OK

## macOS: FileVault (`=== FILEVAULT ===`)

- Off → **WARN**
- On → OK

## macOS: Gatekeeper (`=== GATEKEEPER ===`)

- `assessments disabled` → **WARN**
- `assessments enabled` → OK
