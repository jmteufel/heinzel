# SSH-Only Replacement via Hot-Migration

When no console, IPMI, or rescue mode is
available and the server uses ZFS, LVM, or btrfs,
use hot-migration to free the main partition while
the old OS keeps running.

This is the safest SSH-only replacement method:
the old OS remains bootable as a fallback
throughout the process.

## Overview

1. **Reclaim swap** — `swapoff` frees the swap
   partition.
2. **Add swap to pool** — add the freed partition
   to the filesystem pool (ZFS, LVM, btrfs).
3. **Evacuate main partition** — hot-remove the
   original root partition from the pool. All
   data migrates to the former swap partition.
   The old OS now runs entirely from the swap
   partition.
4. **Delete and repartition** — delete the freed
   main partition. Create new partitions: swap +
   new root for the replacement OS.
5. **Install new OS** — write the new OS to the
   new root partition (debootstrap, cloud image
   extraction, etc.) while the old OS is still
   running.
6. **Set up bootloader** — install systemd-boot
   on the EFI partition. See `/efi-boot`.
7. **BootNext for safe first boot** — use
   `efibootmgr -n` (one-shot) so the system
   tries the new OS once. On failure, it
   automatically falls back to the old OS
   bootloader.
8. **Clean up after confirmation** — once the
   new OS is confirmed working, remove the old
   OS from the swap partition and restore swap.

See `rules/partition-staging.md` for hot-
migration commands. See `/efi-boot` for BootNext
setup.

## When Hot-Migration Fails

Hot-migration requires the staging partition to
hold all data from the evacuated partition.
If the swap partition is too small (e.g. 2 GB
swap, 1.5 GB ZFS data + metadata overhead),
`zpool remove` fails with "out of space."

In that case, fall back to the **tmpfs rescue +
full-disk dd** method in
[tmpfs-rescue](tmpfs-rescue.md).
