#!/usr/bin/env bash
# dual-boot-setup — inspect current disk and partition state
# Run before planning any partition changes.

# ── Linux ──────────────────────────────────────────
if command -v lsblk >/dev/null 2>&1; then
    echo "=== BLOCK_DEVICES ==="
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT \
        2>/dev/null || echo "lsblk_failed"

    echo "=== PARTITION_TABLE ==="
    # Try fdisk for partition type info
    for disk in $(lsblk -dn -o NAME 2>/dev/null); do
        fdisk -l "/dev/$disk" 2>/dev/null || true
    done
fi

# ── FreeBSD ────────────────────────────────────────
if command -v gpart >/dev/null 2>&1; then
    echo "=== GPART ==="
    gpart show 2>/dev/null || echo "gpart_failed"
fi

# ── macOS ──────────────────────────────────────────
if command -v diskutil >/dev/null 2>&1; then
    echo "=== DISKUTIL ==="
    diskutil list 2>/dev/null || echo "diskutil_failed"
fi

# ── Current mounts (all platforms) ────────────────
echo "=== MOUNTS ==="
mount 2>/dev/null || echo "mount_failed"

# ── Free space summary ─────────────────────────────
echo "=== DISK_FREE ==="
df -h 2>/dev/null || echo "df_failed"
