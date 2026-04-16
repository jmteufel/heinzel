# Partition Planning

## Shared EFI Partition

Both OSes share the same EFI System Partition
(typically p1, FAT32, 260 MB+). Do not create a
second ESP.

## Separate Root Partitions

Each OS gets its own root partition. Never install
two OSes on the same partition.

## Swap

Linux and FreeBSD swap formats are incompatible.
Options:
- Each OS gets its own swap partition
- Skip swap on one or both OSes (acceptable for
  VMs with enough RAM)
- Use a swap file instead of a partition (Linux
  only)

A swap partition can also be temporarily repurposed
as a staging filesystem during setup: format as
ext2, use for data transfer, then reformat as swap
when done.

## Sizing Guidelines

| Partition | Minimum | Recommended |
|-----------|---------|-------------|
| EFI (p1)  | 100 MB  | 260 MB      |
| OS root   | 8 GB    | 20+ GB      |
| Swap      | 0       | 1–2× RAM    |

## ZFS Root Repartitioning

When the existing OS uses ZFS on the entire disk
(common with FreeBSD), the ZFS pool must be shrunk
to make room. ZFS does not support shrinking, so a
migration is required.

### The Problem

- `gpart resize` on a mounted ZFS partition fails
  with "Device busy".
- ZFS pools cannot be shrunk — the partition must
  be destroyed and recreated smaller.

### Migration Workflow

1. Create a temporary small partition in free space
   (or shrink an unused partition).
2. Create a temporary ZFS pool on it.
3. Migrate data:
   ```
   zfs send -R pool@snap | zfs recv temppool
   ```
4. Reboot into the temporary pool.
5. Destroy the original pool and repartition.
6. Create the new (smaller) pool.
7. Migrate back:
   ```
   zfs send -R temppool@snap | zfs recv newpool
   ```
8. Reboot into the new pool.
9. Destroy the temporary pool and use its partition
   for the second OS.

### Pitfalls

- **Duplicate pool names:** The temp pool and
  original pool may share a name. Import by GUID:
  ```
  zpool import -d /dev <guid> <name>
  ```
- **Stale `zpool.cache`:** After migration the
  cache may reference the old pool. Clear it:
  ```
  rm /boot/zfs/zpool.cache
  zpool set cachefile=/boot/zfs/zpool.cache <pool>
  ```
- **`loader.conf` on both pools:** Update
  `vfs.root.mountfrom` in `/boot/loader.conf` on
  the pool you're booting into.
- **Boot environment:** After `zfs recv`, activate
  the correct environment:
  ```
  bectl activate <be>
  ```

Check `memory/servers/<hostname>/` for any
documented command sequences from previous
repartitioning sessions on this machine.
