---
name: version-check
description: >
  Use when checking installed software versions
  on a server — during housekeeping, before
  installing or upgrading any software, or when
  configuring or troubleshooting specific software.
  Covers version comparison, severity levels,
  cooldown tracking, version pins, EOL awareness,
  and the housekeeping Versions report section.
---

## When to Check

- **During housekeeping:** check all Tier 1
  software and add a Versions section to the
  report.
- **When software is touched:** when configuring,
  troubleshooting, or otherwise working with a
  specific piece of software, check whether the
  installed version is current. Report inline if
  it is not.
- **Before installing or upgrading:** search for
  the current stable version first. After install,
  verify the installed version matches what was
  expected and update server memory.
- **Not every session:** do not check all software
  on every connect — only during housekeeping or
  when a specific piece of software is touched.

## What to Check

### Tier 1 — Always Check During Housekeeping

- **OS release:** still supported? newer stable
  release available?
- **mise-managed runtimes:** compare installed
  versions (from `memory.md`) against current
  stable/LTS releases.
- **Manually installed services:** software listed
  in `memory.md` that was installed outside the
  distro package manager (e.g. Ollama,
  node_exporter, mise itself).

### Tier 2 — Check When Touched

Any software being actively worked on in the
current session, including distro packages if the
user is configuring or troubleshooting them.

### Tier 3 — Do Not Proactively Check

System packages managed by the distro package
manager (`apt`, `dnf`, `zypper`, `pkg`). These
are covered by the existing "pending updates"
housekeeping check.

## Stable Releases Only

Only compare against **stable, GA, or LTS**
releases. Ignore beta, RC, alpha, nightly,
preview, development branches, snapshots, and
odd-numbered development releases (e.g. Fedora
Rawhide, Node.js odd-numbered versions).

For language runtimes, prefer LTS versions when
the project uses LTS (e.g. Node.js LTS, not
Node.js Current).

**Mandatory:** all version lookups must use a
live web search. Never rely on training data.
Cite the source URL when reporting.

## Version Check Procedure

1. Read `memory.md` for the server. Identify all
   installed software with version numbers.
2. Web search for the current stable version of
   each item. Use official project sites or
   release pages.
3. Compare installed vs. current.
4. Classify the result:
   - `UP TO DATE` — installed version matches or
     is within one patch release of current.
   - `UPDATE` — a newer stable version exists
     (minor or patch bump within same major).
   - `UPGRADE` — a new major version is available.
   - `EOL` — the installed version has reached
     end of life.

## Nudge Rules

### Severity

- `INFO` — patch update available (e.g.
  17.1 → 17.2). Mention in housekeeping only.
- `WARN` — minor or major update available (e.g.
  22.x → 24.x for Node.js LTS). Mention in
  housekeeping and inline when touched.
- `CRITICAL` — installed version is EOL or has
  known security vulnerabilities. Always mention.

### Cooldown

Do not repeat the same nudge within **14 days**
unless the available version has changed. Track
the last check date in server memory.

### Inline Nudge Format

Place after the current task output — do not
interrupt the user's workflow:

```
Note: Ollama 0.20.0 is available (installed:
0.18.2). Run `ollama update` when convenient.
```

### Version Pins

If a server has a `version-pin` entry in
`memory.md`, do not nudge for that software:

```markdown
- version-pin: PostgreSQL 16 (legacy app
  dependency)
```

Still report pinned software in housekeeping with
a note explaining the pin, but do not flag it as
WARN.

## Housekeeping Report Section

Add after the "System" section:

```
### Versions

Ollama       0.18.2   -> 0.20.0 available   WARN
PostgreSQL   17.1     -> 17.3 available      INFO
node_export  1.9.0    UP TO DATE
Node.js      22.19.0  -> 24.1.0 LTS avail.  WARN
Debian       13       UP TO DATE
```

- One line per checked item.
- Show installed version, arrow and available
  version (if different), and severity.
- Sort: CRITICAL first, then WARN, then INFO,
  then UP TO DATE.

## OS End-of-Life Awareness

Always check whether the installed OS version is
approaching or past its end-of-life date:

- **Debian:** wiki.debian.org release lifecycle
- **Ubuntu:** ubuntu.com/about/release-cycle
- **RHEL/CentOS:** Red Hat lifecycle policy
- **FreeBSD:** freebsd.org/security
- **SUSE:** suse.com/lifecycle
- **macOS:** Apple supports current and two prior
  major versions

Severity:
- `WARN` if EOL is within 6 months
- `CRITICAL` if the OS is past EOL

## Server Memory

After a version check, update `memory.md`:

```markdown
- last-version-check: 2026-03-22 — Ollama
  0.18.2 (0.20.0 avail), PG 17.1 (17.3 avail),
  node_exporter 1.9.0 (current), Node 22.19.0
  (24.1.0 LTS avail), Debian 13 (current)
```

Replace the previous `last-version-check` line
(do not accumulate). This line serves as the
cooldown tracker.

## Changelog

```bash
logger -t heinzel \
  "Version check: 2 updates available \
(Ollama, Node.js), 0 EOL"
```
