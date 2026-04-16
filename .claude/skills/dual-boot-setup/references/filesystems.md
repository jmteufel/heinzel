# Filesystem Choice

Choosing a filesystem for the second OS partition,
with cross-OS compatibility in mind.

## ext2

FreeBSD can read and write ext2 via its `ext2fs`
driver. Good choice when the existing OS needs to
write to the new partition during setup (e.g. when
using the swap partition as a staging area).

After the second OS boots successfully, ext2 can
be converted to ext4:

```
tune2fs -O has_journal,extents,dir_index /dev/sdXn
```

## ext4

Better for Linux-only partitions: journaling,
better performance, modern features.

FreeBSD's `ext2fs` driver **cannot** handle modern
ext4 features such as `metadata_csum_seed` and
`orphan_file`. Do not use ext4 if FreeBSD needs to
access the partition during installation.

## ZFS

Supported on both FreeBSD and Linux (OpenZFS).
Mixing root pools between OSes is not recommended
— use separate pools per OS.
