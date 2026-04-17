# Docker Installation

**Always install from Docker's official repo.**
Distro packages are outdated. Search for the
current stable release before installing.

Official docs: https://docs.docker.com/engine/install/

## Debian / Ubuntu

```bash
# Remove distro packages if present
apt-get remove -y docker.io docker-doc \
  docker-compose docker-compose-v2 \
  podman-docker containerd runc

# Add Docker's GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/\
debian/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add repo (adjust "debian" to "ubuntu" if needed)
echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") \
stable" \
  | tee /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
```

## RHEL / CentOS / Fedora

```bash
# Remove distro packages if present
dnf remove -y docker docker-client \
  docker-client-latest docker-common \
  docker-latest docker-latest-logrotate \
  docker-logrotate docker-engine podman runc

dnf install -y dnf-plugins-core
dnf config-manager --add-repo \
  https://download.docker.com/linux/rhel/docker-ce.repo

dnf install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
```

## SUSE / openSUSE

```bash
zypper addrepo \
  https://download.docker.com/linux/sles/docker-ce.repo
zypper refresh
zypper install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
```

## Enable and Start

```bash
systemctl enable --now docker
```

## Verify

```bash
docker version
docker run --rm hello-world
```

## daemon.json

Path: `/etc/docker/daemon.json`. Back up before
editing. Apply changes with:

```bash
systemctl reload docker
# if reload is insufficient:
systemctl restart docker
```

Useful defaults:

```json
{
  "log-driver": "journald",
  "log-opts": { "max-size": "10m" },
  "default-address-pools": [
    { "base": "172.16.0.0/12", "size": 24 }
  ]
}
```

- `log-driver: journald` — integrates with
  `journalctl` instead of writing separate files.
- `default-address-pools` — avoids conflicts with
  existing RFC 1918 ranges on the host network.
