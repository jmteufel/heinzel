#!/usr/bin/env bash
# mise — standalone installer (no root needed)
# Works on all distro families.
# Installs to ~/.local/bin/mise.
# Run as the SSH user (not root).

set -e

if curl -fsSL https://mise.run | sh; then
    echo "install_method=curl"
elif wget -qO - https://mise.run | sh; then
    echo "install_method=wget"
else
    echo "install_failed=no_curl_or_wget"
    exit 1
fi

if "$HOME/.local/bin/mise" --version >/dev/null 2>&1; then
    echo "mise_path=$HOME/.local/bin/mise"
    echo "install_ok=yes"
else
    echo "install_ok=no"
fi
