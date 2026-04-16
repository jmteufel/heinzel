# QEMU EFI Notes

Applies when using QEMU to install a new OS (see
the `/os-replacement` skill — "QEMU as a Cross-OS
Chroot Alternative"). The VM's EFI is separate from
the real hardware's EFI NVRAM.

## Key Limitation

**QEMU cannot update the real EFI NVRAM.** Boot
entries created inside QEMU only exist in QEMU's
virtual NVRAM and are lost when QEMU shuts down.
The real EFI NVRAM still has the old OS's boot
entries after the QEMU install finishes.

## Pre-Reboot Checklist

Before shutting down QEMU and rebooting into the
new OS:

1. **Install the new boot loader at the fallback
   path** — firmware uses this when no boot entry
   matches:
   ```
   # ARM64
   cp /boot/loader.efi /efi/boot/bootaa64.efi
   # x86_64
   cp /boot/loader.efi /efi/boot/bootx64.efi
   ```

2. **Create a new boot entry** using `efibootmgr`
   from a tmpfs rescue environment or the old OS
   (if still accessible):
   ```
   efibootmgr -c -d /dev/sda -p 1 \
     -l '\EFI\freebsd\loader.efi' \
     -L "FreeBSD"
   efibootmgr -o XXXX   # new entry first
   ```

3. **Use BootNext** for the first boot into the
   new OS (see SKILL.md — Common Operations).

4. **Clean old EFI files from the ESP** — if the
   old OS's EFI directory remains (e.g.
   `EFI/debian/`), firmware may try the old boot
   loader first. If its root partition is gone, some
   firmware will not fall through to the fallback.
   Remove the old directory from within the QEMU
   install shell before shutting down QEMU.

5. **Delete old boot entries** only after the new
   OS is confirmed working.

## When efibootmgr Is Unavailable

If no rescue environment has `efibootmgr`, rely
on the fallback path (`EFI/BOOT/BOOT*.EFI`) and
ensure old EFI directories are cleaned as described
above.
