# dual-boot-setup Skill — Reference Index

## scripts/inspect.sh

Captures current disk and partition state before
any changes. Run as root for full output.

| Section tag | Contents |
|---|---|
| `=== BLOCK_DEVICES ===` | `lsblk` output — names, sizes, types, filesystems, mounts (Linux) |
| `=== PARTITION_TABLE ===` | `fdisk -l` per disk — partition types and boundaries (Linux) |
| `=== GPART ===` | `gpart show` — GPT layout (FreeBSD) |
| `=== DISKUTIL ===` | `diskutil list` — disk and partition list (macOS) |
| `=== MOUNTS ===` | Currently mounted filesystems |
| `=== DISK_FREE ===` | `df -h` — used and free space per filesystem |

## references/partitioning.md

- Shared ESP rule, separate root partitions, swap
  options
- Sizing table (EFI, root, swap)
- ZFS root repartitioning: the problem, migration
  workflow, and pitfalls (duplicate pool names,
  stale cache, loader.conf, boot environment)

## references/filesystems.md

Filesystem choice for the second OS partition:
ext2 (FreeBSD-compatible), ext4 (Linux-optimised),
ZFS (both, but separate pools). Includes ext2→ext4
conversion command.

## references/installation-methods.md

Three methods with trade-offs:
- Cloud image — quickest, no cross-OS filesystem
  access needed
- debootstrap in QEMU — cleanest, best when
  existing OS can't mount target filesystem
- Network install — interactive, standard installer
