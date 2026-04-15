#!/usr/bin/env bash
# mise — configure PATH for SSH non-interactive shells
# Run as the SSH user (not root).
#
# Inserts ~/.local/bin and ~/.local/share/mise/shims
# at the top of ~/.bashrc (before the interactive
# guard) and creates/updates ~/.bash_profile.
#
# Output keys:
#   bashrc_updated=        yes | no (already configured)
#   bash_profile_updated=  yes | no (already configured)
#   setup_complete=yes

set -e

BASHRC="$HOME/.bashrc"
BASH_PROFILE="$HOME/.bash_profile"

# ── ~/.bashrc: insert before interactive guard ─────
if grep -q "mise/shims" "$BASHRC" 2>/dev/null; then
    echo "bashrc_updated=no (already configured)"
else
    tmpfile=$(mktemp)
    cat > "$tmpfile" << 'BLOCK'
# mise PATH (before interactive guard)
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

BLOCK
    cat "$BASHRC" 2>/dev/null >> "$tmpfile" || true
    mv "$tmpfile" "$BASHRC"
    echo "bashrc_updated=yes"
fi

# ── ~/.bash_profile ────────────────────────────────
if grep -q "mise/shims" "$BASH_PROFILE" 2>/dev/null; then
    echo "bash_profile_updated=no (already configured)"
else
    cat > "$BASH_PROFILE" << 'PROFILE'
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
export XDG_RUNTIME_DIR=/run/user/$(id -u)

# Source .bashrc for interactive login shells
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
PROFILE
    echo "bash_profile_updated=yes"
fi

echo "setup_complete=yes"
