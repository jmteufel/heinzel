#!/bin/sh
# Inject SSH access into a mounted nocloud rootfs.
#
# Run AFTER extracting openssh-server into the
# rootfs. See the /cloud-image skill §6 for the
# full sequence.
#
# Usage:
#   ROOTFS=/mnt/target PUBKEY="ssh-ed25519 ..." \
#     sh inject-ssh-keys.sh
#
# ROOTFS      — path to the mounted target rootfs
# PUBKEY      — SSH public key to inject
# PUBKEY_FILE — path to a public key file
#               (alternative to PUBKEY)
#
# What this script does:
#   1. Creates /root/.ssh with correct permissions
#   2. Appends the public key to authorized_keys
#   3. Creates the sshd system user if missing
#   4. Creates the sshd privilege separation dir

set -e

: "${ROOTFS:?ROOTFS must be set to the mounted rootfs path}"

[ -d "$ROOTFS" ] || {
  echo "ERROR: ROOTFS '$ROOTFS' is not a directory"
  exit 1
}

if [ -n "${PUBKEY_FILE:-}" ]; then
  PUBKEY=$(cat "$PUBKEY_FILE")
fi
: "${PUBKEY:?PUBKEY or PUBKEY_FILE must be set}"

echo "Target rootfs: $ROOTFS"
echo ""

# --- SSH authorized_keys ---------------------------------
echo "=== Injecting authorized_keys ==="
mkdir -p "$ROOTFS/root/.ssh"
printf '%s\n' "$PUBKEY" >> "$ROOTFS/root/.ssh/authorized_keys"
chmod 700 "$ROOTFS/root/.ssh"
chmod 600 "$ROOTFS/root/.ssh/authorized_keys"
echo "Key injected into $ROOTFS/root/.ssh/authorized_keys"
echo ""

# --- sshd system user ------------------------------------
echo "=== Checking sshd system user ==="
if grep -q '^sshd:' "$ROOTFS/etc/passwd" 2>/dev/null; then
  echo "sshd user already exists — skipping"
else
  echo "Creating sshd system user"
  SSHD_UID=74
  if grep -q ":$SSHD_UID:" "$ROOTFS/etc/passwd" 2>/dev/null; then
    SSHD_UID=$(awk -F: '$3 >= 100 && $3 < 1000 {print $3}' \
      "$ROOTFS/etc/passwd" | sort -n | tail -1)
    SSHD_UID=$((SSHD_UID + 1))
    echo "UID 74 taken — using $SSHD_UID"
  fi
  printf 'sshd:x:%d:%d::/run/sshd:/usr/sbin/nologin\n' \
    "$SSHD_UID" "$SSHD_UID" >> "$ROOTFS/etc/passwd"
  printf 'sshd:!:%d:0:99999:7:::\n' \
    "$(( $(date +%s) / 86400 ))" \
    >> "$ROOTFS/etc/shadow"
  printf 'sshd:x:%d:\n' "$SSHD_UID" \
    >> "$ROOTFS/etc/group"
  echo "sshd user created with UID $SSHD_UID"
fi
echo ""

# --- Privilege separation dir ----------------------------
echo "=== Creating sshd privilege sep directories ==="
mkdir -p "$ROOTFS/run/sshd"
mkdir -p "$ROOTFS/var/run/sshd"
echo "Done"
echo ""

echo "=== inject-ssh-keys.sh complete ==="
echo "Remaining steps (see /cloud-image skill §6):"
echo "  3. Copy default sshd_config from package"
echo "  4. Set PermitRootLogin yes"
echo "  5. Generate host keys: ssh-keygen -A"
echo "  6. Enable sshd service symlink"
echo "  7. Set root password in /etc/shadow"
