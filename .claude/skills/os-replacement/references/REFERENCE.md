# os-replacement Skill — Reference Index

## scripts/inventory.sh

Captures pre-replacement system state. Run as
root before touching anything. Outputs to stdout
— redirect to
`memory/servers/<hostname>/pre-replacement.md`.

Sections: system facts, partition layout, ZFS
pools, network (addresses, routes, DNS, hosts),
enabled services, listening ports, user accounts,
cron jobs, installed packages, custom repos,
firewall rules, SSL certs, SSH host key
fingerprints.

## references/installation-methods.md

All installation methods with selection guidance:
console/IPMI, cloud provider, VM, SSH-only same
family (tmpfs rescue), SSH-only cross-OS (mfsBSD),
PXE, rescue mode. Includes partition freeing
techniques (swap reclaim, hot-migration) and an
explanation of why dd-to-live-disk fails.

## references/tmpfs-rescue.md

Full tmpfs rescue environment: 6 safety rules,
FreeBSD rescue root build commands, Linux/OpenSSH
10.x adjustments (three-binary sshd, nsswitch,
login shell, `/run/sshd`), additional rescue
binaries (efibootmgr, SysRq reboot, QEMU ROM
files), starting and verifying rescue sshd,
streaming the OS image via dd, post-dd EFI
partition modification, SSH key injection for
nocloud images.

## references/hot-migration.md

ZFS/LVM/btrfs hot-migration workflow (8 steps):
swap reclaim, add to pool, evacuate main
partition, repartition, install new OS while old
OS runs, BootNext. When hot-migration fails due to
insufficient swap space.

## references/qemu-chroot.md

QEMU as cross-OS chroot alternative: when to
prefer it over manual extraction, headless serial
console setup (`-nographic`, stdin FIFO, monitor
TCP), FreeBSD console setup via `sendkey`, TCG
performance expectations, CRITICAL device name
mapping table (SATA/virtio/NVMe × Linux/FreeBSD),
fstab and `vfs.root.mountfrom` fixes,
post-extraction file verification checklist
(FreeBSD and Debian).

## references/manual-extraction.md

Manual package extraction into an offline rootfs:
system users and groups, config files from
defaults, systemd service enablement via symlinks,
state directory creation, summary checklist,
how to inspect postinst scripts.

## references/gpt-types.md

GPT partition type codes after cross-OS
replacement: expected codes by OS (Linux vs
FreeBSD), fixing with `sgdisk` (Linux) or
`gpart modify` (FreeBSD), when to fix.

## references/mfsbsd.md

mfsBSD for SSH-only Linux → FreeBSD replacement:
why mfsBSD, pre-built image variants (Standard,
SE, Mini), full workflow (tmpfs rescue → dd →
reboot → mfsBSD → install → reboot), AutoBSD for
repeatable deployments.
