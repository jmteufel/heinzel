# SSH-Only Cross-OS via mfsBSD

When replacing one OS with a completely different
one over SSH (e.g. Linux → FreeBSD), use
**mfsBSD** — a FreeBSD system that runs entirely
from RAM.

## Why mfsBSD

mfsBSD loads the entire OS into a memory
filesystem at boot. Once booted, the disk is
completely free — no mounted filesystems, no
page cache dependencies. The installer (or manual
SSH session) can safely partition, format, and
write to the disk without risk of crashing the
running OS.

This solves the fundamental problem of same-disk
replacement: regular installer media (memstick,
disc1 ISO) mount root from the disk. Partitioning
that disk destroys the running system.

## Pre-Built mfsBSD Images

Download from https://mfsbsd.vx.sk/:

- **Standard:** minimal FreeBSD in RAM, sshd
  enabled, root password `mfsroot`.
- **Special Edition (SE):** includes `base.txz`
  and `kernel.txz` — no network download needed
  during installation.
- **Mini:** stripped-down with dropbear SSH.

## Workflow

1. Build tmpfs rescue on the running Linux (sshd
   only — no QEMU needed for this step).
2. Download the mfsBSD SE image.
3. dd the image to `/dev/sda` from the rescue.
4. Reboot.
5. mfsBSD boots into RAM and starts sshd.
6. SSH in (`root` / `mfsroot`) and run the
   install: partition, format, extract
   base+kernel, configure, set up EFI bootloader.
7. Reboot into the installed FreeBSD.

Step 6 can be fully scripted from the local
machine using `sshpass` or SSH with password
authentication.

For the tmpfs rescue used in step 1, see
[tmpfs-rescue](tmpfs-rescue.md).

## AutoBSD (Repeatable Deployments)

For automated, repeatable installations, use
[AutoBSD](https://gitlab.com/btrgk-lab/freebsd/autobsd)
to build custom mfsBSD-based images with
`installerconfig` pre-baked. The built image
auto-installs FreeBSD without any SSH
interaction.

AutoBSD requires a FreeBSD system to build images.
Use it for fleet deployments; use raw mfsBSD +
SSH for one-off replacements.
