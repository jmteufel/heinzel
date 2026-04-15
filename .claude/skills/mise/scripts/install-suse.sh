#!/usr/bin/env bash
# mise — openSUSE/SLES package install
# Needs root. Only use when the user explicitly
# prefers the package manager over the standalone
# installer. Ask the user before adding the repo.

set -e

zypper addrepo \
    https://mise.jdx.dev/rpm/mise.repo mise
zypper refresh
zypper install -y mise

echo "mise_path=$(command -v mise)"
mise --version && echo "install_ok=yes" || echo "install_ok=no"
