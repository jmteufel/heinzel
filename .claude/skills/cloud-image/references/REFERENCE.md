# cloud-image Skill — Reference Index

## scripts/inject-ssh-keys.sh

Injects SSH authorized_keys and creates the
`sshd` system user in a mounted nocloud rootfs.
Accepts `ROOTFS` and `PUBKEY` (or `PUBKEY_FILE`)
env vars. Prints remaining manual steps on
completion.

## references/arm64-qemu.md

ARM64-specific issues: GRUB failure on QEMU/UTM
(replace with systemd-boot before first boot) and
using `debugfs` to inject files into an ext4
rootfs from a non-Linux OS (FreeBSD).

## references/image-conversion.md

Image format conversion with `qemu-img`
(qcow2 ↔ raw) and `dd` to write to disk. Note
on writing to a partition vs. a full disk.
