# mise Skill — Script Reference

## scripts/check.sh

Detect existing mise installation. Run as the SSH
user (not root).

| Output key          | Values                              |
|---------------------|-------------------------------------|
| `mise_path=`        | full path or `absent`               |
| `mise_type=`        | `system` / `user` / `other` / `absent` |
| `shims_in_path=`    | `yes` / `no`                        |
| `bashrc_configured=`| `yes` / `no`                        |

`mise_type=system` means mise is in `/usr/bin` or
`/usr/local/bin` (installed via package manager).
`mise_type=user` means `~/.local/bin/mise`.

## scripts/install-standalone.sh

Install mise via the official installer. No root
required. Works on all distro families. Installs
to `~/.local/bin/mise`. Run as the SSH user.

| Output key       | Values                              |
|------------------|-------------------------------------|
| `install_method=`| `curl` / `wget`                     |
| `install_ok=`    | `yes` / `no`                        |
| `install_failed=`| `no_curl_or_wget` (only on failure) |

## scripts/install-debian.sh

Install mise from the official apt repository.
**Needs root.** Only use when the user explicitly
prefers the package manager. Adds a third-party
repo — ask the user first.

## scripts/install-rhel.sh

Install mise from the official RPM repository.
**Needs root.** Uses `dnf`; falls back to `yum`
on RHEL 7/CentOS 7. Only use when the user
explicitly prefers the package manager. Adds a
third-party repo — ask the user first.

## scripts/install-suse.sh

Install mise from the official RPM repository via
zypper. **Needs root.** Only use when the user
explicitly prefers the package manager. Adds a
third-party repo — ask the user first.

## scripts/setup-path.sh

Configure PATH for SSH non-interactive shells.
Run as the SSH user (not root).

Inserts `~/.local/bin` and
`~/.local/share/mise/shims` at the top of
`~/.bashrc` (before the interactive guard) and
creates/updates `~/.bash_profile`. Both operations
are idempotent.

| Output key              | Values                              |
|-------------------------|-------------------------------------|
| `bashrc_updated=`       | `yes` / `no (already configured)`  |
| `bash_profile_updated=` | `yes` / `no (already configured)`  |
| `setup_complete=`       | `yes`                               |
