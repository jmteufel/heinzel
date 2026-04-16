# EFI System Partition Layout

The ESP is typically the first partition, formatted
as FAT32, mounted at `/boot/efi` (Linux) or
`/boot/msdos` (FreeBSD).

## Recommended Dual-Boot Layout

```
/efi/
├── boot/
│   └── bootaa64.efi    # standard fallback (ARM64)
│   └── bootx64.efi     # standard fallback (x86_64)
├── freebsd/
│   └── loader.efi      # FreeBSD loader
├── systemd/
│   └── systemd-bootaa64.efi
├── loader/
│   ├── loader.conf     # systemd-boot config
│   └── entries/
│       ├── debian.conf
│       └── freebsd.conf
├── vmlinuz             # Linux kernel
└── initrd.img          # Linux initramfs
```

Both OSes share the same ESP. Each boot loader gets
its own subdirectory.

## Dual-Boot Setup

- **Shared ESP:** Both OSes use the same EFI
  partition (typically p1). Do not create separate
  ESPs.
- **One boot entry per OS:** Create a separate EFI
  boot entry for each OS using `efibootmgr -c`.
- **Default OS:** Set via BootOrder only after both
  OSes are confirmed working with BootNext.

## ARM64 VM Display Issues

On ARM64 virtual machines (UTM/QEMU), the boot
loader or early kernel may produce no visible console
output. This does not mean the boot failed.

- systemd-boot menu may not display — it still boots
  the default entry silently.
- FreeBSD loader menu may not display on serial
  console.

To get console output, add `console=ttyAMA0` to the
Linux kernel options, or configure serial console in
`loader.conf` for FreeBSD.
