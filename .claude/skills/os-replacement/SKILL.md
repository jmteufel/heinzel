---
name: os-replacement
disable-model-invocation: true
description: >
  Use when replacing one OS with another on the
  same server — any combination of Linux and
  FreeBSD. Covers wipe-and-reinstall, distro
  migration (e.g. CentOS → Debian, FreeBSD →
  Linux), and full OS reload from scratch.
---

## Also Load

- `/efi-boot` skill — always; manages boot entries
  and BootNext for safe first-boot testing.
- `/cloud-image` skill — if installing via cloud
  image (VM, ARM64, or user preference).
- `rules/<family>.md` — for the new OS family
  (e.g. `debian.md`, `freebsd.md`).
- `rules/partition-staging.md` — when freeing
  partitions for staging via hot-migration or
  swap reclaim.

## Prerequisites

Before starting:

1. **Confirm with the user.** This is destructive
   and irreversible. The old OS will be wiped.
2. **Backup.** Verify the user has a full backup
   or snapshot. For VMs, suggest a VM-level
   snapshot before starting.
3. **Inventory the current system.** Run
   `scripts/inventory.sh` (as root) and save
   output to
   `memory/servers/<hostname>/pre-replacement.md`.

## Pre-Replacement Inventory

Capture from the running system before it is
wiped. At minimum:

- OS, version, architecture; partition layout
  (`lsblk`, `gpart show`, `zpool status`);
  filesystem types, mount points, bootloader type
- Network: IP addresses, gateway, DNS, interface
  names, bonding/VLAN config, firewall rules
  (full ruleset export), `/etc/hosts`, WireGuard
  or VPN configs
- Enabled services and their config files, data
  directories, listening ports; database dumps;
  web server configs; cron jobs
- User accounts: login shells, SSH authorized
  keys, sudo/doas config
- Packages: explicitly installed (`apt-mark
  showmanual`, `pkg info -o`,
  `dnf history userinstalled`); custom repos
- SSL/TLS certs and keys; SSH host keys (save
  to avoid host key change warnings after
  replacement)
- Config file backups per `rules/backups.md`:
  `/etc/`, firewall config, web/database/app
  configs

## Boot Configuration Safety (CRITICAL)

**Never modify the bootloader or EFI fallback
path until the new root filesystem is confirmed
written to disk.**

Violating this rule can brick the server: if
the root filesystem write fails but the
bootloader already points to it, the system
reboots into a bootloader that references a
non-existent root. With SSH-only access and no
console, the server becomes unrecoverable.

### Mandatory order of operations

1. **Write the new root filesystem first.**
   Confirm the write completed (check exit
   code, verify bytes written).
2. **Verify the new root filesystem.** Mount or
   probe it to confirm it is valid.
3. **Only then modify boot configuration.**
   Install the bootloader, update EFI entries,
   change BootOrder/BootNext.
4. **Keep the old bootloader intact as
   fallback** until the new OS is confirmed
   bootable. Use BootNext (one-shot) for the
   first boot. See `/efi-boot`.

### Never do before root FS is verified

- Replace `/efi/boot/bootaa64.efi` (or
  `bootx64.efi`) with a new bootloader.
- Change BootOrder to prioritize the new OS.
- Remove old boot entries.

If the root filesystem write fails (dd error,
permission denied, I/O error): **stop
immediately**. Do not reboot. The old OS is
still intact and bootable — keep it that way.

## Installation

Choose method based on available access. See
[installation methods](references/installation-methods.md)
for full details and per-method instructions.

| Access type             | Preferred method         |
|-------------------------|--------------------------|
| Console/IPMI/KVM        | Boot ISO, run installer  |
| Cloud provider          | Provider reinstall       |
| VM (UTM/QEMU)           | debootstrap or ISO       |
| SSH-only, same family   | tmpfs rescue + debootstrap |
| SSH-only, cross-OS      | mfsBSD (runs from RAM)   |
| PXE available           | Network install          |
| Rescue mode available   | debootstrap or equivalent|

**Prefer debootstrap** over cloud images whenever
possible. Cloud images carry cloud-init baggage,
may lack `openssh-server` in nocloud variants,
and use GRUB which fails on ARM64 QEMU/UTM.

### Partition Planning

- Reuse the existing partition layout if it was
  working well.
- Keep the EFI partition (reformat only if
  necessary).
- Match or exceed previous partition sizes for
  services that will be restored.
- To free a partition for staging while the old
  OS keeps running, see
  `rules/partition-staging.md`.

### Static IP

Configure the same IP address as the old OS.
DNS records and firewall rules on other servers
depend on this IP staying the same.

## Post-Replacement Checklist

After the new OS is installed and accessible:

1. [ ] SSH access works
2. [ ] OS detected and server memory updated
3. [ ] Hostname set correctly
4. [ ] Network configured (same IP as before)
5. [ ] Firewall installed and configured
6. [ ] Automatic security updates enabled
7. [ ] SSH host keys restored (optional — avoids
       host key warnings for other users/scripts)
8. [ ] User accounts and SSH keys restored
9. [ ] Services reinstalled and configured
10. [ ] Data restored (databases, web content,
        etc.)
11. [ ] SSL certificates restored or renewed
12. [ ] Cron jobs restored
13. [ ] Firewall rules match pre-replacement
        config
14. [ ] All services tested and running
15. [ ] GPT partition types match the new OS —
        see [gpt-types](references/gpt-types.md)
16. [ ] `pre-replacement.md` reviewed — nothing
        missed
17. [ ] Changelog entry logged
18. [ ] `pre-replacement.md` deleted after
        everything is confirmed working

## Cross-Family Considerations

When switching OS families (e.g. RHEL → Debian,
FreeBSD → Linux):

- **Package names differ.** `httpd` (RHEL) vs
  `apache2` (Debian) vs `apache24` (FreeBSD).
- **Config paths differ.** `/etc/nginx/` (Linux)
  vs `/usr/local/etc/nginx/` (FreeBSD).
- **Service managers differ.** systemd (Linux)
  vs rc.d (FreeBSD).
- **Firewall tools differ.** ufw/firewalld
  (Linux) vs pf (FreeBSD).
- **Config syntax may differ** between versions
  of the same software on different distros.
  Review and adapt — do not blindly copy configs.

Read the rule file for the new OS family before
restoring services.

## Memory Updates

After replacement:

- Update `memory.md` with the new OS, services,
  and configuration.
- Add a changelog entry for the OS replacement.
- Delete `pre-replacement.md` once everything is
  confirmed working.
