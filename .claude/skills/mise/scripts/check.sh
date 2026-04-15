#!/usr/bin/env bash
# mise — pre-install check
# Run as the SSH user (not root)
#
# Output keys:
#   mise_path=   full path, or "absent"
#   mise_type=   system | user | other | absent
#   shims_in_path=   yes | no
#   bashrc_configured=   yes | no

if command -v mise >/dev/null 2>&1; then
    mise_path=$(command -v mise)
    echo "mise_path=$mise_path"
    case "$mise_path" in
        /usr/bin/mise|/usr/local/bin/mise)
            echo "mise_type=system"
            ;;
        "$HOME"/.local/bin/mise)
            echo "mise_type=user"
            ;;
        *)
            echo "mise_type=other"
            ;;
    esac
    mise --version 2>/dev/null || true
else
    echo "mise_path=absent"
    echo "mise_type=absent"
fi

if echo "$PATH" | grep -q "mise/shims"; then
    echo "shims_in_path=yes"
else
    echo "shims_in_path=no"
fi

if grep -q "mise/shims" "$HOME/.bashrc" 2>/dev/null; then
    echo "bashrc_configured=yes"
else
    echo "bashrc_configured=no"
fi
