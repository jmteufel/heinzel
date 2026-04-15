#!/usr/bin/env bash
# mise — RHEL/Fedora/CentOS package install
# Needs root. Only use when the user explicitly
# prefers the package manager over the standalone
# installer. Ask the user before adding the repo.
# Uses dnf; falls back to yum on RHEL 7/CentOS 7.

set -e

if command -v dnf >/dev/null 2>&1; then
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo \
        https://mise.jdx.dev/rpm/mise.repo
    dnf install -y mise
else
    yum install -y yum-utils
    yum-config-manager --add-repo \
        https://mise.jdx.dev/rpm/mise.repo
    yum install -y mise
fi

echo "mise_path=$(command -v mise)"
mise --version && echo "install_ok=yes" || echo "install_ok=no"
