#!/usr/bin/env bash
# mise — Debian/Ubuntu package install
# Needs root. Only use when the user explicitly
# prefers the package manager over the standalone
# installer. Ask the user before adding the repo.

set -e

apt-get update && apt-get install -y gpg sudo wget curl
wget -qO - https://mise.jdx.dev/gpg-key.pub \
    | gpg --dearmor \
    | tee /etc/apt/keyrings/mise-archive-keyring.gpg \
    > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] \
https://mise.jdx.dev/deb stable main" \
    | tee /etc/apt/sources.list.d/mise.list
apt-get update && apt-get install -y mise

echo "mise_path=$(command -v mise)"
mise --version && echo "install_ok=yes" || echo "install_ok=no"
