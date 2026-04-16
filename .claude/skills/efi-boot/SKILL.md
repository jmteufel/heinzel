---
name: efi-boot
description: >
  Use for any EFI/UEFI topic: boot entries, boot
  order, boot loader install or config (systemd-boot,
  GRUB, FreeBSD loader), dual-boot setup, boot
  troubleshooting, or QEMU EFI caveats. Invoke
  automatically whenever EFI is mentioned or relevant.
---

## EFI Boot Fields

- `BootCurrent` — entry that booted this session
- `BootOrder` — persistent boot priority list
- `BootNext` — one-shot override, cleared after
  use; reverts to normal BootOrder after one boot

## Safety

- **Prefer BootNext** over BootOrder changes when
  testing — if the new entry fails, the next
  reboot returns to the working OS automatically.
- **Never delete boot entries** without asking the
  user first.
- **Verify before changing** — always show current
  state before modifying.
- **Keep the current default** until the new OS is
  confirmed working. A wrong BootOrder can make
  the system unbootable (fixable via EFI shell or
  rescue, but disruptive).

## Steps

1. Run `scripts/inspect.sh` to capture current EFI
   state (boot entries, BootOrder, BootCurrent,
   ESP mounts).
2. Show the current state to the user and confirm
   what needs to change.
3. Follow the appropriate reference:
   - Boot loader install/config →
     [boot-loaders](references/boot-loaders.md)
   - ESP layout / dual-boot →
     [esp-layout](references/esp-layout.md)
   - QEMU installation caveats →
     [qemu-notes](references/qemu-notes.md)
4. Use BootNext for the first boot into any new
   entry.
5. Only update BootOrder after BootNext confirms
   the entry works.
6. Delete old boot entries only after the new OS
   is confirmed working.
7. Update `memory/servers/<hostname>/memory.md`
   with the new boot configuration.

## Common Operations

### One-shot boot test (BootNext)

```
efibootmgr -n XXXX     # XXXX = entry number
```

### Change persistent boot order

```
efibootmgr -o XXXX,YYYY,ZZZZ
```

### Add a new EFI boot entry

```
efibootmgr -c -d /dev/sda -p 1 \
  -l '\EFI\freebsd\loader.efi' \
  -L "FreeBSD"
```

### Delete a boot entry

Ask the user first. Then:

```
efibootmgr -b XXXX -B
```

## Memory Convention

```
- Boot: EFI (systemd-boot)
- Boot: EFI (FreeBSD loader)
- Boot: EFI dual-boot (systemd-boot + FreeBSD)
```
