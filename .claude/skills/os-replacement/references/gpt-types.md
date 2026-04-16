# GPT Partition Type Codes

When replacing one OS with another, the GPT
partition table retains the old OS's type codes.
For example, replacing FreeBSD with Linux leaves
partitions marked as `freebsd-swap` and
`freebsd-zfs` even though they now contain Linux
swap and ext4.

**Always fix partition type codes after a
cross-OS replacement.** Wrong type codes can
confuse tools, installers, and rescue systems
that rely on them to identify partition contents.

## Expected Type Codes by OS

| Partition   | Linux      | FreeBSD               |
|-------------|------------|-----------------------|
| Root / data | `8300`     | `516e7cb5-...` (zfs)  |
| Swap        | `8200`     | `516e7cb5-...` (swap) |
| EFI         | `ef00`     | `ef00`                |

## How to Fix

**From Linux** (after replacement):

```
# sgdisk: -t PARTNUM:TYPECODE
sgdisk -t 2:8200 -t 3:8300 /dev/vda
partprobe /dev/vda
```

**From FreeBSD** (after replacement):

```
# gpart modify: -t TYPE -i PARTNUM DEVICE
gpart modify -t freebsd-swap -i 2 vtbd0
gpart modify -t freebsd-zfs -i 3 vtbd0
```

## When to Fix

Fix partition types as a post-replacement step,
after the new OS is booted and confirmed working.

Verify with `fdisk -l` or `gpart show` — look for
type names that belong to the old OS.
