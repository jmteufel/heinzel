#!/usr/bin/env bash
# heinzel security audit — Linux data collection
#
# Remote: ssh -o BatchMode=yes -o ConnectTimeout=5 \
#           user@host 'bash -s' \
#           < .claude/skills/security-audit/scripts/linux.sh
# Local:  bash .claude/skills/security-audit/scripts/linux.sh
#
# Output: === SECTION === markers; Claude interprets
# against thresholds in references/thresholds.md.
#
# Note: awk uses positive ~ match + next instead of
# !~ to avoid zsh history expansion mangling over SSH.

IS_ROOT=0
[ "$(id -u)" -eq 0 ] && IS_ROOT=1

# ── SSH password authentication ────────────────────
echo "=== SSH_AUTH ==="
if [ "$IS_ROOT" -eq 1 ]; then
    sshd -T 2>/dev/null \
        | grep -i passwordauthentication \
        || echo "sshd_T_unavailable"
else
    echo "sshd_T=needs_root"
fi
# Always parse config as cross-check (authoritative
# on OpenSSH 8.8+ with drop-in files)
grep -i "^PasswordAuthentication" \
    /etc/ssh/sshd_config \
    /etc/ssh/sshd_config.d/*.conf 2>/dev/null \
    || echo "config=unreadable"

# ── SSH hardening ──────────────────────────────────
echo "=== SSH_HARDENING ==="
if [ "$IS_ROOT" -eq 1 ]; then
    sshd -T 2>/dev/null | grep -iE \
        "^(permitrootlogin|ciphers|macs|kexalgorithms|maxauthtries|x11forwarding) " \
        || echo "sshd_T_unavailable"
fi
grep -iE \
    "^(PermitRootLogin|Ciphers|MACs|KexAlgorithms|MaxAuthTries|X11Forwarding)" \
    /etc/ssh/sshd_config \
    /etc/ssh/sshd_config.d/*.conf 2>/dev/null \
    || echo "config=unreadable"

# ── Firewall ───────────────────────────────────────
echo "=== FIREWALL ==="
if command -v ufw >/dev/null 2>&1; then
    ufw status verbose 2>/dev/null \
        || echo "ufw_failed"
elif command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --state 2>/dev/null
    zone=$(firewall-cmd --get-default-zone 2>/dev/null)
    echo "default_zone=${zone:-unknown}"
    [ -n "$zone" ] && \
        firewall-cmd --zone="$zone" \
        --get-target 2>/dev/null \
        || true
else
    echo "no_firewall_tool"
fi

# ── Empty password accounts ────────────────────────
echo "=== EMPTY_PASSWORDS ==="
if [ "$IS_ROOT" -eq 1 ]; then
    awk -F: '($2 == "") {print $1}' /etc/shadow \
        2>/dev/null || echo "shadow_unreadable"
else
    echo "needs_root"
fi

# ── Multiple UID 0 accounts ────────────────────────
echo "=== UID0 ==="
awk -F: '($3 == 0) {print $1}' /etc/passwd

# ── System accounts with login shells ─────────────
# Positive ~ match + next avoids !~ which zsh
# mangles via history expansion over SSH.
echo "=== SYSTEM_ACCOUNTS ==="
awk -F: '($3 < 1000) && \
  ($7 ~ /(nologin|false|sync|shutdown|halt)$/) \
  {next} ($3 < 1000) {print $1 ":" $7}' \
  /etc/passwd

# ── Listening services ─────────────────────────────
echo "=== LISTENING ==="
if [ "$IS_ROOT" -eq 1 ]; then
    ss -tulnp 2>/dev/null || echo "ss_unavailable"
else
    ss -tuln 2>/dev/null || echo "ss_unavailable"
fi

# ── Kernel / sysctl security ───────────────────────
echo "=== SYSCTL ==="
echo "aslr=$(sysctl -n kernel.randomize_va_space \
    2>/dev/null || echo unknown)"
echo "ip_forward=$(sysctl -n net.ipv4.ip_forward \
    2>/dev/null || echo unknown)"
echo "icmp_redirects=$(sysctl -n \
    net.ipv4.conf.all.accept_redirects \
    2>/dev/null || echo unknown)"
echo "suid_dumpable=$(sysctl -n fs.suid_dumpable \
    2>/dev/null || echo unknown)"

# ── World-writable system files ────────────────────
echo "=== WORLD_WRITABLE ==="
find /etc /usr /bin /sbin -xdev -type f \
    -perm -0002 2>/dev/null

# ── SUID/SGID binaries ─────────────────────────────
echo "=== SUID_SGID ==="
find / -xdev -type f \
    \( -perm -4000 -o -perm -2000 \) 2>/dev/null

# ── /tmp and /dev/shm mount options ───────────────
echo "=== TMP_MOUNTS ==="
findmnt -n -o OPTIONS /tmp 2>/dev/null \
    || mount 2>/dev/null | grep " /tmp "
findmnt -n -o OPTIONS /dev/shm 2>/dev/null \
    || mount 2>/dev/null | grep " /dev/shm "

# ── Cron directory permissions ─────────────────────
echo "=== CRON_PERMS ==="
stat -c '%a %U %G %n' \
    /etc/crontab \
    /etc/cron.d \
    /etc/cron.daily \
    /etc/cron.hourly \
    /etc/cron.weekly \
    /etc/cron.monthly 2>/dev/null

# ── Unowned files ──────────────────────────────────
echo "=== UNOWNED ==="
find /etc /usr /var -xdev \
    \( -nouser -o -nogroup \) 2>/dev/null

# ── fail2ban ───────────────────────────────────────
echo "=== FAIL2BAN ==="
systemctl is-active fail2ban 2>/dev/null \
    || echo "inactive_or_not_installed"
if systemctl is-active fail2ban >/dev/null 2>&1; then
    fail2ban-client status 2>/dev/null || true
fi
