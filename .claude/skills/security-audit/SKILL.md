---
name: security-audit
description: Security audit of the current server
disable-model-invocation: true
---

Run a security audit on the target server. Only
invoke on explicit user request.

## Steps

1. Load [report format](assets/report-format.md) and
   [thresholds](references/thresholds.md).
2. Read `memory/servers/<hostname>/memory.md` for
   service context (e.g. WireGuard/VPN → IP
   forwarding is expected; affects severity).
3. Collect data using the appropriate script from
   `scripts/`: `linux.sh` for Linux,
   `macos.sh` for macOS.
4. Interpret all output against the loaded thresholds,
   cross-referencing memory.md where noted.
5. Present the report using the loaded format.
6. Do NOT update `memory.md` — these are config
   observations, not server state changes.
7. Log a one-line summary to the system journal and
   mirror to local `changelog.log`.

## Notes

Reading `/etc/ssh/sshd_config` is safe — the
restriction on that file applies to *modifying* it,
not reading it.

## Execution Notes

Run script sections in 2–3 parallel batches for
speed. Keep awk-heavy sections (=== SYSTEM_ACCOUNTS,
=== CRON_PERMS) in their own batch — a quoting
mistake there should not cancel simpler checks.

Note: automatic security updates are checked during
housekeeping (`/housekeeping`). This audit does not
duplicate that check.

## Unprivileged Mode

Sections that need root output `needs_root`. Add
these to the report's Skipped section:

```
### Skipped (needs root)

- SSH effective config (sshd -T requires root)
- Empty password accounts (/etc/shadow unreadable)
- Listening services process names (ss -p needs root)
```

Works without root: SSH config file parsing,
=== UID0, === SYSTEM_ACCOUNTS, === LISTENING
(without process names on Linux), all === SYSCTL
values, === WORLD_WRITABLE, === SUID_SGID,
=== TMP_MOUNTS, === UNOWNED, === FAIL2BAN, all
macOS checks.

Needs root: `sshd -T`, === EMPTY_PASSWORDS
(/etc/shadow), === LISTENING with process names
(ss -tulnp), some === CRON_PERMS dirs.

When using the config file fallback for SSH checks,
note in the report that the result is from config
file parsing, not the effective compiled config.
