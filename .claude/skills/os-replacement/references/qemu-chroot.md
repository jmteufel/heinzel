# QEMU as a Cross-OS Chroot Alternative

When the old and new OS are entirely different
(e.g. FreeBSD → Linux), `chroot` into the new
rootfs does not work — the running kernel cannot
execute binaries built for a different OS.

**Install QEMU on the old OS** and use it to boot
the new rootfs in a lightweight VM:

1. Install QEMU (`pkg install qemu` on FreeBSD,
   `apt-get install qemu-system-aarch64` on
   Debian, etc.).
2. Boot the new rootfs partition or image directly
   in QEMU, passing the real disk/partition as a
   block device.
3. Inside the QEMU VM, the new OS runs its own
   kernel — `dpkg`, `apt`, `chroot`, `useradd`,
   and all postinst scripts work normally.
4. Install and configure packages, generate SSH
   host keys, enable services, set up users.
5. Shut down the VM. The rootfs on the partition
   is now fully configured and ready to boot
   natively.

**Prefer manual shell installation over
interactive installers.** Dialog-based installers
(FreeBSD's bsdinstall, Debian's d-i) use escape
sequences that break through serial pipes.
Instead: boot the ISO to a live shell, then
partition, extract, and configure manually. For
FreeBSD: exit to "Live System" at the boot menu,
then use `gpart`, `newfs`, `tar`.

## When to Prefer QEMU over Manual Extraction

- The new OS needs many packages installed or
  configured (manual extraction does not scale).
- Package postinst scripts are complex (e.g.
  `initramfs-tools`, kernel hooks, `dbus`
  machine-id generation).
- Same architecture but different OS kernel
  (e.g. FreeBSD aarch64 → Linux aarch64). QEMU
  uses KVM/HVF when available (near-native speed)
  or TCG software emulation.

## When Manual Extraction Is Still Fine

- Only a few packages are needed (e.g. just
  `openssh-server`).
- The rootfs comes from a cloud image that already
  has most packages pre-installed.
- QEMU is not available or cannot be installed on
  the old OS.

## QEMU Serial Console for Headless Use

When running QEMU over SSH, the guest OS console
must be routed to a serial port.

**Required QEMU flags:**

```
qemu-system-x86_64 \
  -nographic \
  -monitor tcp:127.0.0.1:4445,server,nowait \
  -cpu max \
  ...
```

- `-nographic` removes the VGA adapter and
  redirects the BIOS, boot loader, and serial
  console to stdio. **Without this, the boot
  loader and kernel output go to an invisible
  virtual VGA and the serial port stays empty.**
- `-monitor tcp:...` puts the QEMU monitor on a
  separate TCP port so `sendkey` commands can be
  sent without interfering with stdio.
- Do **not** use `-vga none -display none` with
  a separate `-serial chardev:socket` — the boot
  loader still uses VGA BIOS calls (INT 10h) and
  its output will go nowhere.

**Keeping stdin writable (for interactive
guests):**

When QEMU reads from stdin via `-nographic`, it
must have a writable file descriptor. If stdin is
`/dev/null`, the guest receives EOF.

Use a named pipe with a persistent writer:

```
mkfifo /tmp/qemu_in
sleep 86400 > /tmp/qemu_in &
qemu-system-x86_64 ... -nographic \
  < /tmp/qemu_in > /tmp/qemu_out.log 2>&1 &
```

Send input: `printf "command\n" > /tmp/qemu_in`

Read output: `tail /tmp/qemu_out.log`

**Sending keystrokes via the QEMU monitor:**

```
exec 3<>/dev/tcp/127.0.0.1/4445
echo "sendkey 3" >&3   # press "3"
echo "sendkey ret" >&3  # press Enter
exec 3>&-
```

Note: after the guest switches console to serial
(e.g. FreeBSD `set console="comconsole"`), the
boot loader reads from serial, not keyboard.
Further input must go through the FIFO, not
`sendkey`.

## FreeBSD Console Setup

The FreeBSD boot loader defaults to `vidconsole`
(VGA). To get output on serial:

1. At the boot menu, press `3` (Escape to loader
   prompt) — send via `sendkey` since the menu
   reads from keyboard.
2. Type `set console="comconsole"` — send via
   `sendkey` (still on keyboard). Each character
   must be sent individually:
   ```
   for key in s e t spc c o n s o l e \
     equal shift-apostrophe c o m c o n \
     s o l e shift-apostrophe; do
     echo "sendkey $key" >&3
     sleep 0.15
   done
   echo "sendkey ret" >&3
   ```
3. Type `boot` — send via the FIFO (the loader
   now reads from serial after the console
   switch).

**Timing is critical.** The boot menu has a
10-second default timeout. Send `sendkey 3`
within 5 seconds of QEMU starting the ISO boot.

**If you miss the boot menu:** the installer
still outputs to serial as secondary console.
Accept the terminal type prompt (press Enter via
FIFO for vt100 default), then use Tab + Enter
to navigate to "Shell" in the installer menu.

Or pre-configure `console="comconsole"` in
`/boot/loader.conf` for subsequent boots.

## TCG (Software Emulation) Performance

Without KVM/HVF, QEMU uses TCG. Expect:

- FreeBSD kernel boot: 3–8 minutes
- base.txz extraction (~170 MB): 5–10 minutes
- RSA 4096-bit key generation: 1–3 minutes

Budget at least 20 minutes for a full FreeBSD
installation under TCG.

## QEMU Device Name Mapping (CRITICAL)

**Device names inside QEMU do not match the real
hardware.** The QEMU virtual disk uses virtio
(`vtbd0` in FreeBSD, `vda` in Linux), but the
real server's disk controller determines the
native device name.

| Controller    | Linux      | FreeBSD   |
|---------------|------------|-----------|
| SATA / AHCI   | `sda`      | `ada0`    |
| virtio-blk    | `vda`      | `vtbd0`   |
| virtio-scsi   | `sda`      | `da0`     |
| NVMe          | `nvme0n1`  | `nvd0`    |
| IDE           | `sda`      | `ada0`    |

**Before launching QEMU, record the real device
names** from the running OS:

```
# Linux — check block device name and transport
lsblk -o NAME,TRAN
# TRAN column shows: sata, nvme, virtio, usb
```

If Linux shows `sda` with transport `sata`, the
FreeBSD device name will be `ada0`. If it shows
`vda` with transport `virtio`, it's `vtbd0`.

**After QEMU installation, fix all device
references** before rebooting:

- `/etc/fstab` (FreeBSD) — replace `vtbd0` with
  the real device name (e.g. `ada0`)
- `/etc/fstab` (Linux) — replace `vda` with the
  real name (e.g. `sda`)
- `/boot/loader.conf` `vfs.root.mountfrom` — set
  explicitly with the real device name

**Always set `vfs.root.mountfrom` in
`/boot/loader.conf`** with the real device name:

```
# In /boot/loader.conf (using real device name):
vfs.root.mountfrom="ufs:/dev/ada0p3"
# Console — see /freebsd skill §Console:
console="vidconsole"  # x86_64 UTM/QEMU or VGA
# console="efi"       # ARM64 UTM/QEMU only
```

**Console must match the target platform, not
QEMU.** When installing FreeBSD via QEMU for a
target that boots natively, the console in
loader.conf must match the real hardware.

**The FreeBSD boot loader auto-detects `currdev`**
from the EFI boot path, so the kernel mounts root
correctly even with wrong fstab. But `fsck` and
`mount -a` during multi-user boot will fail if
fstab has the wrong device names, potentially
dropping to single-user mode.

## Post-Extraction Verification (MANDATORY)

After extracting the new OS (base.txz, kernel.txz,
debootstrap, cloud image, etc.), **always verify
critical files exist** before proceeding:

**FreeBSD:**

```
ls /mnt/boot/kernel/kernel    # kernel binary
ls /mnt/boot/lua/loader.lua   # boot loader
                               # scripts (14.x+)
ls /mnt/boot/loader.conf      # loader config
ls /mnt/etc/passwd             # user database
ls /mnt/etc/rc.conf            # service config
ls /mnt/usr/sbin/sshd          # SSH server
```

**Linux (Debian):**

```
ls /mnt/boot/vmlinuz-*         # kernel
ls /mnt/boot/initrd.img-*      # initramfs
ls /mnt/etc/fstab              # mount table
ls /mnt/usr/sbin/sshd          # SSH server
```

If any critical file is missing, **stop and
re-extract.** Do not reboot. A common cause is
tar truncation errors — re-download and
re-extract the archive.

**FreeBSD 14.x+:** The boot loader uses Lua
scripts in `/boot/lua/`. If
`/boot/lua/loader.lua` is missing, the loader
drops to an `OK` prompt instead of booting the
kernel. Re-extract `base.txz`.
