# Boot Loaders

## systemd-boot

Best choice for Linux on ARM64 and UEFI systems.
Simple, reliable, no BIOS/CSM compatibility baggage.

| Path | Purpose |
|------|---------|
| `/boot/efi/loader/loader.conf` | Main config (or `/efi/loader/loader.conf`) |
| `/boot/efi/loader/entries/*.conf` | Boot entries |

Commands:

```
bootctl install   # install to ESP
bootctl update    # update after package upgrade
bootctl status    # show current state
```

Entry file format:

```
title   Debian 13
linux   /vmlinuz
initrd  /initrd.img
options root=UUID=... rw
```

### Kernel updates

systemd-boot does not auto-detect new kernels. After
a kernel update, copy the new files to the ESP:

```
cp /boot/vmlinuz-*    /boot/efi/debian/vmlinuz
cp /boot/initrd.img-* /boot/efi/debian/initrd.img
```

Update the entry file if it references specific
filenames. Consider an apt/pacman hook to automate
this.

## GRUB (EFI)

Works on x86_64 UEFI systems.

**Does NOT work reliably on ARM64/QEMU/UTM.** GRUB's
ARM64 EFI support fails silently or hangs in virtual
machines. Use systemd-boot instead.

| Path | Purpose |
|------|---------|
| `/boot/grub/grub.cfg` | Generated config |

Commands:

```
update-grub                                    # Debian/Ubuntu
grub2-mkconfig -o /boot/grub2/grub.cfg        # RHEL
grub-install --target=x86_64-efi              # x86_64
```

Do not run `grub-install --target=arm64-efi` on
ARM64 VMs.

### GRUB ARM64/QEMU symptoms

- GRUB installs without errors but fails to boot
- Black screen or immediate reboot after GRUB stage
- EFI shell drops to prompt instead of loading GRUB

## FreeBSD Loader

FreeBSD's native EFI boot loader.

| Path | Purpose |
|------|---------|
| `/boot/loader.efi` | Loader binary |
| `/efi/freebsd/loader.efi` | Installed location |
| `/efi/boot/bootaa64.efi` | ARM64 fallback path |
| `/efi/boot/bootx64.efi` | x86_64 fallback path |
| `/boot/loader.conf` | Loader config |

The loader can also be installed at the standard EFI
fallback path so firmware finds it without a boot
entry:

```
cp /boot/loader.efi /efi/boot/bootaa64.efi   # ARM64
cp /boot/loader.efi /efi/boot/bootx64.efi    # x86_64
```

### systemd-boot chain-load entry for FreeBSD

```
title   FreeBSD
efi     /efi/freebsd/loader.efi
```
