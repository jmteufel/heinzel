---
name: housekeeping
description: Routine health inspection on the current server
disable-model-invocation: true
---

Run a routine housekeeping inspection on the target
server. Only invoke on explicit user request.

## Steps

1. Load [report format](assets/report-format.md) and
   [thresholds](references/thresholds.md).
2. Read `memory/housekeeping.md` — custom checks, if
   it exists. Missing is normal.
3. Read `memory/servers/<hostname>/memory.md` for
   service context.
4. Collect baseline data using the appropriate script
   from `scripts/`: `linux.sh` for Linux,
   `macos.sh` for macOS.
5. For each service in `memory.md`, run the relevant
   check from
   [service-checks](references/service-checks.md).
6. Check installed software versions per the
   `/version-check` skill. Include a Versions
   section in the report.
7. Interpret all output against the loaded thresholds
   and present the report using the loaded format.
8. Update `memory/servers/<hostname>/memory.md` if
   checks revealed changed facts (e.g. disk usage
   shifted, a service appeared or disappeared).
9. Log a one-line summary to the system journal and
   mirror to local `changelog.log`.

## Unprivileged Mode

When running without root, the baseline scripts
output `needs_root` for checks that require elevated
privileges. List these in the report:

```
### Skipped (needs root)

- Pending security updates (apt-get update)
- Firewall status (ufw requires root)
- SSL certificate files (/etc/letsencrypt/)
```

## Custom Checks

Users can extend checks via `memory/housekeeping.md`
(gitignored). Read it alongside the baseline results.
Format: free-form Markdown describing what to check,
which commands to run, and what thresholds to apply.
