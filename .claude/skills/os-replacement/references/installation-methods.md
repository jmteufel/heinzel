# OS Replacement Installation Methods

**Prefer debootstrap** (or the target distro's
bootstrap tool) over cloud images. Fall back to
a cloud image only when debootstrap is not
feasible: no network access from the server,
target distro has no bootstrap tool, or the user
explicitly requests one.

## Console / IPMI / KVM

Boot from ISO and run the standard OS installer.
Most reliable method — full access, no constraints.

## Cloud Provider

Use the provider's reinstall feature or deploy a
new image through the provider's control panel.

## VM (UTM / QEMU / VMware)

Boot from ISO, or use debootstrap via a rescue
chroot.

Cloud images are a fallback — see
the `/cloud-image` skill.

**ARM64 QEMU/UTM:** cloud images use GRUB, which
fails silently on these platforms. Replace GRUB
with systemd-boot before the first boot. See the
`/efi-boot` skill and the `/cloud-image` skill.

## SSH-Only (Same OS Family)

Use debootstrap (or the target distro's bootstrap
tool) running from a tmpfs rescue environment. The
rescue keeps SSH alive while the disk is
overwritten.

See [tmpfs-rescue](tmpfs-rescue.md) for the full
procedure: safety rules, rescue root build,
streaming the image, post-dd EFI modification.

If the storage pool is large enough, hot-migration
is safer because the old OS remains bootable as
a fallback throughout. See
[hot-migration](hot-migration.md).

## SSH-Only (Cross-OS, e.g. Linux → FreeBSD)

Use **mfsBSD** — a FreeBSD system that runs
entirely from RAM. dd an mfsBSD image to the disk,
reboot; the disk is completely free because the
running OS is in RAM. SSH in and install the new
OS.

**Never use the regular FreeBSD memstick/disc1
installer for same-disk SSH-only replacement.**
The installer mounts root from the disk — any
attempt to partition that disk from rc.local or
installerconfig destroys the running system.

See [mfsbsd](mfsbsd.md) for the full workflow and
AutoBSD for repeatable deployments.

## PXE Network Install

If a PXE server is available in the datacenter,
boot from the network and run the installer.
Datacenter-specific — check with the provider.

## Rescue Mode

Some providers offer a rescue environment — boot
into it, partition, and install via debootstrap
or equivalent. Check the provider's rescue mode
documentation.

---

## Freeing Partitions for Staging

When the disk is full and a staging area is
needed, two key techniques:

1. **Reclaim swap** — `swapoff` frees the swap
   partition for staging (images, backups,
   debootstrap). Always check RAM first: free
   RAM after absorbing used swap must be ≥ 512 MB.

2. **Hot-migration** — on ZFS, LVM, or btrfs,
   add the freed swap partition to the pool,
   migrate data off the original partition, then
   remove it. The original partition is now free
   for the new OS while the old OS keeps running.

See `rules/partition-staging.md` for the full
strategy and commands.

---

## Why dd-to-Live-Disk Fails

**Never dd a full disk image over the running
system's own disk.** This approach fails
catastrophically:

- The running OS crashes when its root filesystem
  is overwritten mid-write. Buffers, metadata,
  and open files become inconsistent instantly.
- If dd does not complete (crash, I/O error,
  power loss), the disk is left inconsistent —
  partially old OS, partially new image. The
  server is bricked with no recovery path.
- Even if the entire image is cached in RAM, the
  reboot command may not execute after the
  filesystem corruption dd causes. The kernel
  panics or hangs instead of rebooting.
- On ZFS or other CoW filesystems, overwriting
  the underlying device corrupts pool metadata
  first, causing an immediate pool fault before
  dd finishes.

**Exception:** dd to the live disk IS safe when
a fully self-contained tmpfs rescue environment
is running. The rescue sshd and all its binaries
live in RAM — the disk overwrite does not affect
running processes. The old OS is lost, so a
backup is mandatory.
