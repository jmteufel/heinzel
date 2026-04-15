#!/usr/bin/env bash
# heinzel housekeeping — Linux baseline data collection
#
# Remote: ssh -o BatchMode=yes -o ConnectTimeout=5 \
#           user@host 'bash -s' \
#           < .claude/skills/housekeeping/scripts/linux.sh
# Local:  bash .claude/skills/housekeeping/scripts/linux.sh
#
# Output: === SECTION === markers; Claude interprets
# against thresholds in references/thresholds.md.

# ── Distro detection ───────────────────────────────
echo "=== DISTRO ==="
if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    echo "ID=${ID:-unknown}"
    echo "VERSION_ID=${VERSION_ID:-unknown}"
    echo "PRETTY_NAME=${PRETTY_NAME:-unknown}"
fi

FAMILY="unknown"
command -v apt-get >/dev/null 2>&1 && FAMILY="debian"
command -v dnf     >/dev/null 2>&1 && FAMILY="rhel"
command -v zypper  >/dev/null 2>&1 && FAMILY="suse"
echo "FAMILY=$FAMILY"

# ── Disk usage ─────────────────────────────────────
echo "=== DISK ==="
df -h --output=target,pcent,size,used,avail \
  -x tmpfs -x devtmpfs -x overlay 2>/dev/null \
  || df -h

# ── Memory and swap ────────────────────────────────
echo "=== MEMORY ==="
free -h

# ── System load ────────────────────────────────────
echo "=== LOAD ==="
uptime
nproc

# ── Uptime and reboots ─────────────────────────────
echo "=== REBOOTS ==="
uptime -s 2>/dev/null || who -b 2>/dev/null || true
last reboot 2>/dev/null | head -5

# ── Failed systemd units ───────────────────────────
echo "=== FAILED_UNITS ==="
systemctl --failed --no-pager --no-legend 2>/dev/null \
  || echo "systemctl not available"

# ── NTP sync ───────────────────────────────────────
echo "=== NTP ==="
timedatectl show --property=NTPSynchronized \
  --value 2>/dev/null \
  || timedatectl status 2>/dev/null \
  || echo "timedatectl not available"

# ── Log anomalies (last 7 days / 24 h) ────────────
echo "=== LOG_ANOMALIES ==="
OOM=$(journalctl --since "7 days ago" -k \
  --grep="Out of memory" --no-pager -q \
  2>/dev/null | wc -l)
IOERR=$(journalctl --since "7 days ago" -k \
  --grep="I/O error" --no-pager -q \
  2>/dev/null | wc -l)
SSH_FAIL=$(journalctl --since "24 hours ago" \
  -u ssh -u sshd \
  --grep="Failed password" --no-pager -q \
  2>/dev/null | wc -l)
echo "oom_kills=$OOM"
echo "io_errors=$IOERR"
echo "ssh_failures=$SSH_FAIL"

# ── SSL/TLS certificate expiry ─────────────────────
echo "=== SSL_CERTS ==="
found=0
if [ -d /etc/letsencrypt/live ]; then
    for cert in /etc/letsencrypt/live/*/cert.pem; do
        [ -f "$cert" ] || continue
        found=1
        domain=$(basename "$(dirname "$cert")")
        expiry=$(openssl x509 -enddate -noout \
            -in "$cert" 2>/dev/null | cut -d= -f2)
        days=$(( ($(date -d "$expiry" +%s) \
            - $(date +%s)) / 86400 ))
        echo "$domain: ${days}d remaining"
    done
fi
if [ "$found" -eq 0 ]; then
    # Fallback: probe port 443 directly
    echo "no_letsencrypt_certs"
    echo | openssl s_client \
        -connect localhost:443 \
        -servername "$(hostname -f)" 2>/dev/null \
        | openssl x509 -enddate -noout 2>/dev/null \
        || true
fi

# ── Root-required checks ───────────────────────────
# Outputs "needs_root" when not root so Claude can
# list these in the Skipped section of the report.

IS_ROOT=0
[ "$(id -u)" -eq 0 ] && IS_ROOT=1

# Pending security updates
echo "=== UPDATES ==="
if [ "$IS_ROOT" -eq 0 ]; then
    echo "needs_root"
else
    case "$FAMILY" in
        debian)
            apt-get update -qq 2>/dev/null
            apt-get --just-print upgrade 2>/dev/null \
                | grep -c "^Inst" || echo 0
            ;;
        rhel)
            dnf check-update --quiet 2>/dev/null \
                | grep -c "^\S" || echo 0
            ;;
        suse)
            zypper --quiet list-updates 2>/dev/null \
                | grep -c "^v" || echo 0
            ;;
        *)
            echo "unknown_package_manager"
            ;;
    esac
fi

# Automatic security updates
echo "=== AUTO_UPDATES ==="
case "$FAMILY" in
    debian)
        systemctl is-active unattended-upgrades \
            2>/dev/null || echo inactive
        dpkg -l unattended-upgrades 2>/dev/null \
            | grep -q "^ii" \
            && echo installed || echo "not installed"
        ;;
    rhel)
        systemctl is-active dnf-automatic.timer \
            2>/dev/null \
            || systemctl is-active yum-cron.service \
               2>/dev/null \
            || echo inactive
        ;;
    suse)
        systemctl is-active zypper-patch.timer \
            2>/dev/null || echo inactive
        ;;
    *)
        echo "unknown"
        ;;
esac

# Firewall status
echo "=== FIREWALL ==="
case "$FAMILY" in
    debian)
        ufw status 2>/dev/null \
            || echo "ufw: not found"
        ;;
    rhel|suse)
        firewall-cmd --state 2>/dev/null \
            || echo "firewalld: not found"
        ;;
    *)
        ufw status 2>/dev/null \
            || firewall-cmd --state 2>/dev/null \
            || echo "no firewall tool found"
        ;;
esac

# Kernel: running vs installed
echo "=== KERNEL ==="
echo "running=$(uname -r)"
case "$FAMILY" in
    debian)
        installed=$(dpkg -l 'linux-image-*' 2>/dev/null \
            | grep "^ii" | awk '{print $2}' \
            | sed 's/linux-image-//' \
            | sort -V | tail -1)
        echo "installed=${installed:-unknown}"
        ;;
    rhel)
        installed=$(rpm -q kernel \
            --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' \
            2>/dev/null | sort -V | tail -1)
        echo "installed=${installed:-unknown}"
        ;;
    *)
        echo "installed=unknown"
        ;;
esac
