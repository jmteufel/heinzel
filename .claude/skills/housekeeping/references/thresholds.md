# Housekeeping Thresholds

Interpret the `=== SECTION ===` output from the
baseline scripts against the thresholds below.

## Linux

### Disk Usage

- **WARN** if any filesystem > 85% used
- **CRITICAL** if any filesystem > 95% used

### Memory and Swap

Report total, used, and available memory.

- **WARN** if available memory < 10% of total
- **WARN** if swap usage > 50% of total swap

### System Load

Report 1m, 5m, 15m load averages and core count.

- **WARN** if 15-minute load average > core count

### Uptime and Reboot Detection

Report uptime. If the server rebooted since the
last housekeeping or last session, flag it:

- **INFO** unexpected reboot detected (compare with
  memory file's last known uptime or last connected
  date)

### Pending Security Updates

- **WARN** if any security updates are pending
- Report the count
- If output is `needs_root`: add to Skipped section

### Automatic Security Updates

- **WARN** if auto-update mechanism is not active

### Firewall Status

- **CRITICAL** if the firewall is inactive or not
  installed

### Failed systemd Units

- **WARN** for each failed unit — list by name

### NTP / Time Sync

- **WARN** if NTP is not synchronized

### Log Anomalies

- **WARN** if any OOM kills found
- **WARN** if any disk I/O errors found
- **INFO** if > 100 failed SSH logins in 24 hours
  (may indicate brute-force attempts)

### SSL/TLS Certificate Expiry

Only check if the server runs a TLS-enabled service
(check memory.md for nginx, Apache, etc.).

- **CRITICAL** if any cert expires in < 7 days
- **WARN** if any cert expires in < 30 days

### Kernel: Running vs Installed

- **INFO** if running kernel differs from installed
  (reboot recommended)

## macOS

### Disk Usage

- **WARN** if > 85% used
- **CRITICAL** if > 95% used

### Memory

Parse `vm_stat` output to calculate used/free pages.
Multiply by page size (usually 16384 on Apple
Silicon, 4096 on Intel — get from `vm_stat` header).

- **WARN** if available memory < 10% of total

### System Load and Uptime

- **WARN** if 15-minute load average > core count

### Pending Software Updates

- **WARN** if updates are available

### Critical Auto-Updates

Check that critical security updates install
automatically — see the `/macos` skill for
context.

- **WARN** if critical auto-updates are disabled

### Homebrew Packages

- **WARN** if any outdated packages — report the
  count and list them

### Application Firewall

- **INFO** if disabled (not WARN — common on macOS
  behind NAT)

### SMART Disk Status

- **CRITICAL** if SMART status is not "Verified"

### Time Sync

- **WARN** if time offset > 5 seconds
