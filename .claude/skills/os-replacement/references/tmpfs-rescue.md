# SSH-Only Replacement via Tmpfs Rescue

When hot-migration is not feasible (swap too
small, no volume manager, cross-OS replacement),
use a tmpfs-based rescue environment to keep SSH
alive while overwriting the entire disk.

## Safety Rules (CRITICAL)

1. **Never overlay system library paths.** Do NOT
   mount tmpfs at `/lib`, `/libexec`, `/bin`, or
   `/sbin` on a live system's chroot. Overlaying
   with an incomplete library set kills the
   ability to fork new processes (including
   sshd-session), permanently locking you out
   with no recovery path.

2. **Build the rescue root from scratch on
   tmpfs.** Create a self-contained root
   filesystem on a tmpfs mount. Every path the
   rescue sshd and its child processes need
   must exist inside the tmpfs root.

3. **Copy libraries using `ldd`, not by copying
   all of `/lib`.** On FreeBSD, `/lib` is ~10 MB
   and can be copied wholesale. On Linux
   (especially with QEMU installed), `/lib` can
   be 700+ MB — too large for tmpfs. Use `ldd`
   on each rescue binary and copy only the
   specific libraries it needs. Missing a library
   causes `sshd-session` to abort — verify every
   binary works in the chroot before proceeding.

4. **Start the rescue sshd on a new port, then
   VERIFY it works before proceeding.** Connect
   from a separate terminal and run a test
   command. Only after confirmation proceed with
   destructive operations.

5. **Never kill the original sshd until the
   rescue sshd is verified.** The original sshd
   is your last lifeline.

6. **Never `umount -l /` (lazy-unmount root).**
   Lazy-unmounting `/` orphans the rescue
   chroot's mountpoint path. New SSH connections
   fail because `sshd-session` cannot be forked
   into the chroot — both the rescue and original
   sshd die. The server stays pingable but is
   permanently locked out.

   **Instead: leave `/` mounted.** The rescue
   sshd runs from tmpfs; it does not need `/`
   to be unmounted. QEMU (or dd) writes to
   `/dev/sda` as a raw block device — this works
   even while the old filesystem is still mounted.
   Unmount only `/boot/efi` (for EFI partition
   changes) and `swapoff` (to free swap).

## Building the Tmpfs Rescue Root (FreeBSD)

```
T=/mnt/tmpfs_rescue
mkdir -p $T
mount -t tmpfs -o size=200m tmpfs $T

mkdir -p $T/{bin,sbin,lib,libexec,dev,tmp,mnt,etc}
mkdir -p $T/etc/ssh $T/root/.ssh $T/var/run/sshd
mkdir -p $T/var/empty $T/var/log
mkdir -p $T/usr/{bin,sbin,lib,libexec}

# Copy ALL of /lib (FreeBSD ~10 MB — safe)
cp -a /lib/* $T/lib/

# Dynamic linker
cp /libexec/ld-elf.so.1 $T/libexec/

# Binaries
cp /bin/{sh,dd,mkdir,cp,cat,chmod,ls,rm,mv,ln,df} \
   $T/bin/
cp /sbin/{mount,umount,mdconfig,reboot,sysctl} \
   $T/sbin/
cp /sbin/{mount_msdosfs,newfs_msdos,gpart} \
   $T/sbin/
cp /usr/bin/fetch $T/usr/bin/
cp /usr/sbin/sshd $T/usr/sbin/
cp /usr/libexec/sftp-server $T/usr/libexec/

# Copy /usr/lib dependencies not in /lib
ldd $T/usr/sbin/sshd $T/usr/bin/fetch \
  2>/dev/null | grep '/usr/lib/' | \
  awk '{print $3}' | sort -u | \
  xargs -I{} cp -n {} $T/usr/lib/

# Auth databases and config
cp /etc/passwd /etc/master.passwd \
   /etc/pwd.db /etc/spwd.db /etc/group \
   $T/etc/
cp /etc/ssh/ssh_host_* $T/etc/ssh/
cp /root/.ssh/authorized_keys \
   $T/root/.ssh/
chmod 700 $T/root/.ssh
chmod 600 $T/root/.ssh/authorized_keys

# Devfs
mount -t devfs devfs $T/dev

# sshd config on a new port
cat > $T/etc/ssh/sshd_config_rescue <<EOF
Port 2223
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_rsa_key
PermitRootLogin yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
UseDNS no
Subsystem sftp /usr/libexec/sftp-server
EOF
```

## Linux (Debian 13+ / OpenSSH 10.x) Adjustments

OpenSSH 10.x splits sshd into three binaries.
Copy all three into the chroot:

```
cp /usr/sbin/sshd $T/usr/sbin/
cp /usr/lib/openssh/sshd-session \
   $T/usr/lib/openssh/
cp /usr/lib/openssh/sshd-auth \
   $T/usr/lib/openssh/
cp /usr/lib/openssh/sftp-server \
   $T/usr/lib/openssh/
```

**Critical sshd_config settings for chroot:**

```
UsePAM no     # PAM libraries not in chroot
UseDNS no     # no resolver in chroot
```

Without `UsePAM no`, sshd-auth fails silently
and all logins are rejected.

**nsswitch.conf must use `files` only:**

```
cat > $T/etc/nsswitch.conf << 'EOF'
passwd:         files
group:          files
shadow:         files
hosts:          files
EOF
```

If `nsswitch.conf` references `systemd` (Debian
default), user lookups fail and sshd reports
"invalid user root" even though `/etc/passwd` is
correct.

**The user's login shell must exist in the
chroot.** sshd validates the shell from
`/etc/passwd`. If root's shell is `/bin/bash`:

```
cp /bin/bash $T/bin/
```

Without it, sshd rejects the login with "User
root not allowed because shell /bin/bash does
not exist."

**Privilege separation directory:**

```
mkdir -p $T/run/sshd
```

OpenSSH 10.x looks in `/run/sshd` (not
`/var/run/sshd`).

**Open the rescue port in the firewall** before
starting the rescue sshd:

```
ufw allow 2223/tcp    # Linux
# or: pfctl rule      # FreeBSD
```

## Additional Rescue Binaries (CRITICAL)

Verify each binary is present and functional.
Do not rely on silent `cp ... || true` patterns.

**`efibootmgr` (Linux):**

```
cp /usr/sbin/efibootmgr $T/usr/sbin/
ldd /usr/sbin/efibootmgr 2>/dev/null | \
  grep -oP '/\S+\.so\S*' | while read lib; do
    dir=$(dirname "$lib")
    mkdir -p "$T$dir"
    cp -n "$lib" "$T$lib" 2>/dev/null
  done
# Verify:
chroot $T /usr/sbin/efibootmgr --version
```

Without `efibootmgr`, you cannot set BootNext
and must rely on the EFI fallback path
(`EFI/BOOT/BOOTX64.EFI`), which is less reliable.

**`reboot` (Linux):**

On Linux, `reboot` links against `libsystemd`,
which is large and complex. Alternatives:

1. **SysRq (preferred):**
   ```
   echo 1 > /proc/sys/kernel/sysrq
   echo s > /proc/sysrq-trigger   # sync
   sleep 1
   echo u > /proc/sysrq-trigger   # remount ro
   sleep 1
   echo b > /proc/sysrq-trigger   # reboot
   ```
2. Copy a static `reboot` (e.g. from busybox).
3. Use `kill -TERM 1` (may not work from chroot).

**Warning:** On VMs (UTM/QEMU), SysRq `b` may
power off the VM instead of rebooting. The
hypervisor decides whether to restart the guest.
If the VM does not come back, the user must start
it from the hypervisor console.

**QEMU ROM files (when QEMU is in rescue):**

```
mkdir -p $T/usr/share/qemu
cp /usr/share/seabios/vgabios-stdvga.bin \
   $T/usr/share/qemu/
cp /usr/share/seabios/vgabios.bin \
   $T/usr/share/qemu/
cp /usr/share/seabios/bios-256k.bin \
   $T/usr/share/qemu/
cp /usr/share/qemu/efi-virtio.rom \
   $T/usr/share/qemu/
cp /usr/share/qemu/kvmvapic.bin \
   $T/usr/share/qemu/
```

Without these, QEMU fails with "failed to find
romfile" errors.

## Starting and Verifying the Rescue sshd

```
chroot $T /usr/sbin/sshd \
  -f /etc/ssh/sshd_config_rescue

# === STOP. Verify from a second terminal: ===
# ssh -p 2223 root@hostname "id && echo OK"
# Only proceed after "OK" is confirmed.
```

## Streaming the New OS Image

After rescue sshd is verified, connect via the
rescue port and stream the cloud image to disk:

```
# FreeBSD only:
sysctl kern.geom.debugflags=0x10

fetch -o - "https://url/to/image.raw" | \
  dd of=/dev/vtbd0 bs=1M
```

All processes run from tmpfs — the disk overwrite
does not affect them.

## Post-dd EFI Partition Modification

After dd, GEOM still caches the old partition
table. To modify the new EFI partition from
tmpfs:

```
# Copy EFI partition to memory-backed device
mdconfig -a -t swap -s 130m -u 1
dd if=/dev/vtbd0 bs=512 skip=EFI_START \
   count=EFI_SECTORS of=/dev/md1
mount -t msdosfs /dev/md1 /mnt/efi

# Modify GRUB config, add systemd-boot, etc.

umount /mnt/efi
dd if=/dev/md1 of=/dev/vtbd0 bs=512 \
   seek=EFI_START count=EFI_SECTORS
mdconfig -d -u 1
```

Replace `EFI_START` and `EFI_SECTORS` with
values from the cloud image's partition table
(inspect before dd).

## SSH Access for Cloud Images (nocloud)

Cloud images (nocloud variant) boot with root
console login but no SSH key. To inject SSH
access when the rootfs is ext4 (unmountable from
FreeBSD), use QEMU to configure the image before
writing it to disk. See
[qemu-chroot](qemu-chroot.md).

If QEMU is not available, try
`mount -t ext2fs` from FreeBSD. Modern ext4
features often prevent this, but some images
work — if it mounts, inject
`/root/.ssh/authorized_keys` directly.
