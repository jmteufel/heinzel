---
name: mise
description: Install language runtimes (Node.js, Ruby, Python, Go, …) on any server using mise — handles detection, install, PATH setup, and verification. Never use distro repos or other version managers for runtimes.
disable-model-invocation: true
---

Install programming language runtimes using
[mise](https://mise.jdx.dev). Only for language
runtimes (Node.js, Ruby, Python, Elixir, Go,
Java, etc.) — not for system services like nginx
or PostgreSQL (use the distro package manager for
those).

## Steps

1. Run `scripts/check.sh` as the SSH user to
   detect any existing mise installation.
2. If `mise_type=absent`, choose an install method:
   - **Default:** `scripts/install-standalone.sh`
     — works on all distros, no root needed.
   - **Package manager** (only when the user
     explicitly prefers it and root is available):
     run the matching distro script —
     `scripts/install-debian.sh`,
     `scripts/install-rhel.sh`, or
     `scripts/install-suse.sh`.
3. If `bashrc_configured=no`, run
   `scripts/setup-path.sh` as the SSH user.
4. Install the requested language as the SSH user:
   ```
   mise use --global node@lts
   ```
5. Verify over SSH (or locally):
   ```
   ssh user@host "node --version"
   ```
   If this fails, PATH did not load — see
   Troubleshooting.
6. Update `memory/servers/<hostname>/memory.md`
   — add or update the mise line.
7. Log a one-line summary to the system journal
   and mirror to local `changelog.log`.

## Notes

- Always run mise commands as the SSH user, never
  as root. Running `mise use` as root installs
  runtimes for root only.
- `mise use --global` sets the default version.
  Without `--global`, mise creates a local
  `.tool-versions` in the current directory.
- When a system-wide mise is found
  (`mise_type=system`), skip installation but
  still run `scripts/setup-path.sh` if
  `bashrc_configured=no` — the shims directory is
  always per-user.

## Troubleshooting

If `ssh user@host "node --version"` fails after
setup, PATH did not load for non-interactive SSH.
Fallback options:

1. **Explicit PATH prefix:**
   ```
   PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH" node -v
   ```
2. **`mise exec`:**
   ```
   ~/.local/bin/mise exec -- node -v
   ```

## Server Memory Convention

```
- mise: node@24.1.0, ruby@3.3.7
```

Update this line whenever languages are added,
removed, or upgraded.
