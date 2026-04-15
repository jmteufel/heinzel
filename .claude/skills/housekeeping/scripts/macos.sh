#!/usr/bin/env bash
# heinzel housekeeping — macOS baseline data collection
#
# Usage: bash .claude/skills/housekeeping/scripts/macos.sh
# (macOS targets are always local; no SSH needed)
#
# Output: === SECTION === markers; Claude interprets
# against thresholds in rules/housekeeping.md.

# ── Disk usage ─────────────────────────────────────
echo "=== DISK ==="
df -h /

# ── Memory ─────────────────────────────────────────
echo "=== MEMORY ==="
vm_stat
sysctl -n hw.memsize

# ── System load ────────────────────────────────────
echo "=== LOAD ==="
uptime
sysctl -n hw.ncpu

# ── Pending software updates ───────────────────────
echo "=== UPDATES ==="
softwareupdate -l 2>&1

# ── Critical auto-updates ──────────────────────────
echo "=== AUTO_UPDATES ==="
defaults read \
    /Library/Preferences/com.apple.SoftwareUpdate \
    CriticalUpdateInstall 2>/dev/null \
    || echo "not configured"
defaults read \
    /Library/Preferences/com.apple.SoftwareUpdate \
    AutomaticCheckEnabled 2>/dev/null \
    || echo "not configured"

# ── Homebrew ───────────────────────────────────────
echo "=== HOMEBREW ==="
if command -v brew >/dev/null 2>&1; then
    brew outdated 2>/dev/null \
        || echo "brew outdated failed"
else
    echo "homebrew_not_installed"
fi

# ── Application firewall ───────────────────────────
echo "=== FIREWALL ==="
/usr/libexec/ApplicationFirewall/socketfilterfw \
    --getglobalstate 2>/dev/null \
    || echo "socketfilterfw not found"

# ── SMART disk status ──────────────────────────────
echo "=== SMART ==="
diskutil info disk0 2>/dev/null \
    | grep "SMART Status" \
    || echo "SMART: unavailable"

# ── Time sync ──────────────────────────────────────
echo "=== TIME_SYNC ==="
sntp -t 1 time.apple.com 2>&1 \
    || echo "sntp failed"
