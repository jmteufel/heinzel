# efi-boot Skill — Reference Index

## scripts/inspect.sh

Captures current EFI state. Works on Linux and
FreeBSD (`efibootmgr` has the same interface on
both). Install on FreeBSD: `pkg install efibootmgr`.

| Section tag | Contents |
|---|---|
| `=== EFI_ENTRIES ===` | `efibootmgr -v` output: all boot entries, BootOrder, BootCurrent, BootNext |
| `=== ESP_MOUNTS ===` | Mounted FAT/EFI partitions |

## references/boot-loaders.md

Details for each supported boot loader:

- **systemd-boot** — config paths, install/update
  commands, entry format, kernel update procedure
- **GRUB (EFI)** — x86_64 only; ARM64/QEMU warning
  and symptoms
- **FreeBSD loader** — binary paths, fallback
  install, systemd-boot chain-load entry

## references/esp-layout.md

- Recommended ESP directory layout for dual-boot
- Dual-boot setup rules (shared ESP, one entry per
  OS, BootOrder only after BootNext confirms)
- ARM64 VM display issues and serial console fix

## references/qemu-notes.md

- Why QEMU cannot update real EFI NVRAM
- Pre-reboot checklist: fallback path, new boot
  entry, BootNext, ESP cleanup, old entry deletion
- Fallback procedure when `efibootmgr` is
  unavailable
