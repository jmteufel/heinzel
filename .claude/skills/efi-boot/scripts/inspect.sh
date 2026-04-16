#!/usr/bin/env bash
# efi-boot — inspect current EFI state
#
# Works on Linux and FreeBSD. efibootmgr has the
# same interface on both. Install on FreeBSD with:
#   pkg install efibootmgr

# ── Boot entries and order ─────────────────────────
echo "=== EFI_ENTRIES ==="
efibootmgr -v 2>/dev/null \
    || echo "efibootmgr_unavailable"

# ── EFI System Partition mounts ────────────────────
echo "=== ESP_MOUNTS ==="
# Linux
if command -v findmnt >/dev/null 2>&1; then
    findmnt -n -o TARGET,SOURCE,FSTYPE,OPTIONS \
        -t vfat 2>/dev/null \
        | grep -iE "efi|boot" || true
fi
# Linux/FreeBSD fallback
mount 2>/dev/null \
    | grep -iE "msdos|vfat|fat32|efi" || true
