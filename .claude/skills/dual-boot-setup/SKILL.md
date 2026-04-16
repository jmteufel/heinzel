---
name: dual-boot-setup
disable-model-invocation: true
description: >
  Use when installing a second OS alongside an
  existing one on the same machine — any combination
  of Linux, FreeBSD, and macOS. Covers partition
  planning, ZFS migration, filesystem choice,
  installation methods, boot setup, and safe testing.
---

## Also Load

- `/efi-boot` skill — always; dual-boot requires
  EFI and boot entry management.
- `/cloud-image` skill — if the user wants to
  install via cloud image.
- The family skill for each OS being installed
  (`/debian`, `/freebsd`, etc.) — auto-loads on
  OS detection; invoke manually if needed.

## Prerequisites

Before touching any partitions:

1. **Backup or snapshot.** Confirm the user has a
   backup. If ZFS, suggest `zfs snapshot` of the
   root dataset.
2. **Inspect the current layout.** Run
   `scripts/inspect.sh` and review with the user.
3. **EFI required.** Dual-boot requires an EFI
   System Partition. Legacy BIOS dual-boot is not
   covered.
4. **Plan the layout** with the user before making
   any changes.

## Steps

1. Run `scripts/inspect.sh` — current partition
   layout, disk sizes, free space.
2. Plan the partition layout with the user →
   [partitioning](references/partitioning.md).
3. If the existing OS uses ZFS on the whole disk,
   follow the ZFS migration workflow in
   [partitioning](references/partitioning.md)
   before repartitioning.
4. Choose a filesystem for the new OS partition →
   [filesystems](references/filesystems.md).
5. Choose an installation method →
   [installation-methods](references/installation-methods.md).
6. Install the boot loader and create EFI boot
   entries — follow the `/efi-boot` skill.
   Boot loader choice for dual-boot:
   - **Linux on ARM64:** systemd-boot only — GRUB
     does not work on ARM64 VMs.
   - **Linux on x86_64:** systemd-boot or GRUB
     both work.
   - **FreeBSD:** native FreeBSD loader.
   - Both entries go on the shared EFI partition.
   - systemd-boot can chain-load FreeBSD's loader.
7. Test safely before committing — see
   Testing Safely below.
8. After confirmed working: remove watchdog params,
   set BootOrder, take a new backup or snapshot.
9. Update `memory/servers/<hostname>/memory.md`
   with the new dual-boot configuration.

## Testing Safely

### BootNext (One-Shot)

Always use BootNext for the first boot into the
new OS. If it fails, the next reboot returns to
the original OS automatically.

```
efibootmgr -n XXXX    # boot entry for new OS
reboot
```

### Kernel Watchdog

Add to the Linux kernel command line for the first
test boot. If the system hangs, it reboots
automatically:

```
panic=30 hung_task_panic=1 softlockup_panic=1
```

### systemd Watchdog

In `/etc/systemd/system.conf`:

```
RuntimeWatchdog=60s
```

If systemd hangs for 60 seconds, the system reboots.

### After Successful Test

Only after the new OS has booted and SSH access
is confirmed:

1. Remove watchdog parameters from kernel cmdline.
2. Change BootOrder to set the desired default.

## Static IP

Both OSes should use the same IP address (only one
runs at a time). DHCP may assign different IPs per
OS because the DHCP client ID differs. Configure a
static IP on both OSes to avoid confusion.

## SSH Host Key Changes

When switching between OSes, the SSH host keys
change (each OS has its own). The SSH client will
warn about a changed key for the same IP.

Options:
- Accept the new key when prompted.
- Use `ssh -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null` for quick
  switches (less secure; acceptable on local VMs).
- Maintain separate `known_hosts` entries per OS
  (impractical with a shared IP).

This is expected behavior when you initiated the
OS switch — not a security issue.

## Checklist

1. [ ] Backup or snapshot before starting
2. [ ] Partition layout planned and approved by user
3. [ ] Repartitioning complete, original OS boots
4. [ ] Second OS installed on target partition
5. [ ] Boot files on EFI partition
6. [ ] EFI boot entry created
7. [ ] SSH host keys present
8. [ ] cloud-init disabled (if cloud image)
9. [ ] Network configured (static IP)
10. [ ] BootNext test successful
11. [ ] Backup or snapshot of working dual-boot
