#!/bin/sh
# Pre-replacement inventory
# Run as root before replacing the OS.
# Output: stdout — redirect to
#   memory/servers/<hostname>/pre-replacement.md

set -e

H=$(hostname)
echo "# Pre-Replacement Inventory — $H"
echo "# $(date)"
echo ""

# --- System facts -------------------------------------------
echo "## System"
uname -a
if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo "OS: ${PRETTY_NAME:-$NAME $VERSION}"
fi
command -v freebsd-version >/dev/null 2>&1 \
  && freebsd-version || true
echo ""

# --- Partition layout ----------------------------------------
echo "## Partitions"
if command -v lsblk >/dev/null 2>&1; then
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
fi
if command -v gpart >/dev/null 2>&1; then
  gpart show 2>/dev/null || true
fi
if command -v zpool >/dev/null 2>&1; then
  echo ""
  echo "### ZFS Pools"
  zpool status 2>/dev/null || true
fi
echo ""

# --- Network -------------------------------------------------
echo "## Network"
if command -v ip >/dev/null 2>&1; then
  ip addr show
  echo ""
  ip route show
elif command -v ifconfig >/dev/null 2>&1; then
  ifconfig
  echo ""
  netstat -rn 2>/dev/null \
    || route -n show 2>/dev/null || true
fi
echo ""

echo "### DNS"
cat /etc/resolv.conf 2>/dev/null || true
echo ""

echo "### /etc/hosts (non-comment)"
grep -v '^[[:space:]]*#' /etc/hosts 2>/dev/null \
  | grep -v '^[[:space:]]*$' || true
echo ""

# --- Services ------------------------------------------------
echo "## Enabled Services"
if command -v systemctl >/dev/null 2>&1; then
  systemctl list-unit-files --state=enabled \
    --no-legend 2>/dev/null || true
elif command -v sysrc >/dev/null 2>&1; then
  sysrc -a 2>/dev/null | grep '_enable=YES' || true
fi
echo ""

echo "## Listening Ports"
if command -v ss >/dev/null 2>&1; then
  ss -tlnp
elif command -v netstat >/dev/null 2>&1; then
  netstat -tlnp 2>/dev/null \
    || netstat -an 2>/dev/null || true
fi
echo ""

# --- Users ---------------------------------------------------
echo "## User Accounts (login shells)"
grep -v '/nologin\|/false\|/sync\|/halt\|/shutdown' \
  /etc/passwd | cut -d: -f1,3,6,7 || true
echo ""

# --- Cron jobs -----------------------------------------------
echo "## Cron Jobs"
echo "### root crontab"
crontab -l 2>/dev/null || echo "(empty)"
echo ""
if [ -d /etc/cron.d ] && \
   [ "$(ls /etc/cron.d/ 2>/dev/null)" ]; then
  echo "### /etc/cron.d/"
  ls /etc/cron.d/
  echo ""
fi
if [ -d /etc/periodic ]; then
  echo "### /etc/periodic/"
  ls /etc/periodic/
  echo ""
fi

# --- Packages ------------------------------------------------
echo "## Installed Packages (explicit)"
if command -v apt-mark >/dev/null 2>&1; then
  apt-mark showmanual 2>/dev/null || true
elif command -v pkg >/dev/null 2>&1; then
  pkg info -o 2>/dev/null || true
elif command -v dnf >/dev/null 2>&1; then
  dnf history userinstalled 2>/dev/null || true
elif command -v rpm >/dev/null 2>&1; then
  rpm -qa --queryformat '%{NAME}\n' 2>/dev/null || true
fi
echo ""

echo "## Custom Repositories"
if [ -d /etc/apt/sources.list.d ]; then
  ls /etc/apt/sources.list.d/ 2>/dev/null || true
fi
if [ -d /etc/yum.repos.d ]; then
  ls /etc/yum.repos.d/ 2>/dev/null || true
fi
if [ -d /usr/local/etc/pkg/repos ]; then
  ls /usr/local/etc/pkg/repos/ 2>/dev/null || true
fi
echo ""

# --- Firewall ------------------------------------------------
echo "## Firewall Rules"
if command -v ufw >/dev/null 2>&1; then
  ufw status verbose 2>/dev/null || true
elif command -v firewall-cmd >/dev/null 2>&1; then
  firewall-cmd --list-all 2>/dev/null || true
elif command -v pfctl >/dev/null 2>&1; then
  pfctl -sr 2>/dev/null || true
elif command -v iptables >/dev/null 2>&1; then
  iptables -L -n -v 2>/dev/null || true
fi
echo ""

# --- Certificates --------------------------------------------
echo "## SSL/TLS Certificates"
if [ -d /etc/letsencrypt/live ]; then
  echo "### Let's Encrypt"
  ls /etc/letsencrypt/live/ 2>/dev/null || true
fi
if [ -d /usr/local/etc/ssl ]; then
  echo "### /usr/local/etc/ssl"
  find /usr/local/etc/ssl -name '*.crt' \
    2>/dev/null || true
fi
echo ""

echo "## SSH Host Keys (fingerprints)"
for key in /etc/ssh/ssh_host_*.pub \
           /usr/local/etc/ssh/ssh_host_*.pub; do
  [ -f "$key" ] && ssh-keygen -l -f "$key" || true
done
echo ""
