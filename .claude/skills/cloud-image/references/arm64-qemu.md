# ARM64 / QEMU Considerations

## GRUB Failure on ARM64

Debian ARM64 cloud images use GRUB as the default
bootloader. GRUB fails silently on ARM64 QEMU/UTM
VMs — the VM hangs at boot with no error output.

**After deploying an ARM64 cloud image on
QEMU/UTM, replace GRUB with systemd-boot before
the first boot.** This applies to both
genericcloud and nocloud images.

See the `/efi-boot` skill for the replacement
procedure.

## Modifying the Image from a Non-Linux OS

When preparing the rootfs from a different OS
(e.g. FreeBSD), standard Linux mount tools are
unavailable. Use `debugfs` (from the `e2fsprogs`
package) to inject files into an ext4 rootfs
without mounting it:

```
# Write a local file into the image's filesystem
debugfs -w -R \
  "write /tmp/local-file /etc/target-path" \
  /dev/vtbd0p4
```

This is useful for injecting SSH keys, network
configs, and bootloader files into a Debian rootfs
from FreeBSD.

```
pkg install e2fsprogs   # FreeBSD
```
