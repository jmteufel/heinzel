#!/usr/bin/env bash
# heinzel security audit — macOS data collection
#
# Usage: bash .claude/skills/security-audit/scripts/macos.sh
# (macOS targets are always local; no SSH needed)
#
# Output: === SECTION === markers; Claude interprets
# against thresholds in references/thresholds.md.

# ── Remote Login (SSH) status ──────────────────────
# If SSH is off, Claude should skip SSH checks and
# report INFO "SSH disabled — checks skipped".
echo "=== SSH_REMOTE_LOGIN ==="
systemsetup -getremotelogin 2>/dev/null \
    || launchctl list com.openssh.sshd 2>/dev/null \
    || echo "check_failed"

# ── SSH password authentication ────────────────────
echo "=== SSH_AUTH ==="
sshd -T 2>/dev/null \
    | grep -i passwordauthentication \
    || true
grep -i "^PasswordAuthentication" \
    /etc/ssh/sshd_config \
    /etc/ssh/sshd_config.d/*.conf 2>/dev/null \
    || echo "config=unreadable"

# ── SSH hardening ──────────────────────────────────
echo "=== SSH_HARDENING ==="
sshd -T 2>/dev/null | grep -iE \
    "^(permitrootlogin|ciphers|macs|kexalgorithms|maxauthtries) " \
    || true
grep -iE \
    "^(PermitRootLogin|Ciphers|MACs|KexAlgorithms|MaxAuthTries)" \
    /etc/ssh/sshd_config \
    /etc/ssh/sshd_config.d/*.conf 2>/dev/null \
    || echo "config=unreadable"

# ── Application Firewall ───────────────────────────
echo "=== FIREWALL ==="
/usr/libexec/ApplicationFirewall/socketfilterfw \
    --getglobalstate 2>/dev/null \
    || echo "socketfilterfw_unavailable"

# ── Listening services ─────────────────────────────
echo "=== LISTENING ==="
lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null \
    || echo "lsof_unavailable"

# ── IP forwarding ──────────────────────────────────
echo "=== IP_FORWARD ==="
echo "ip_forward=$(sysctl -n net.inet.ip.forwarding \
    2>/dev/null || echo unknown)"

# ── SIP (System Integrity Protection) ─────────────
echo "=== SIP ==="
csrutil status 2>/dev/null \
    || echo "csrutil_unavailable"

# ── FileVault (full disk encryption) ──────────────
echo "=== FILEVAULT ==="
fdesetup status 2>/dev/null \
    || echo "fdesetup_unavailable"

# ── Gatekeeper ─────────────────────────────────────
echo "=== GATEKEEPER ==="
spctl --status 2>&1 \
    || echo "spctl_unavailable"
