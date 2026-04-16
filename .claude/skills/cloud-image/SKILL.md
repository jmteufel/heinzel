---
name: cloud-image
disable-model-invocation: true
description: >
  Use when deploying Linux from a pre-built cloud
  image (qcow2, raw, VMDK, genericcloud, nocloud).
  Covers common boot and SSH failures, cloud-init
  disabling, network configuration, nocloud SSH
  preparation, post-deployment checklist, and
  image format conversion.
---

## Also Load

- `/efi-boot` skill — for ARM64 QEMU/UTM
  deployments; GRUB fails silently on ARM64 and
  must be replaced with systemd-boot before the
  first boot.
- `rules/<family>.md` — for the OS family of the
  deployed image.

## Common Issues

Cloud images are built for cloud environments
(AWS, GCP, Azure) and expect cloud-init to
configure them on first boot. When used outside
a cloud provider, several things break.

### 1. Missing SSH Host Keys

Cloud images ship without SSH host keys — they
expect cloud-init to generate them on first boot.
If cloud-init is disabled or broken, `sshd` fails
to start.

```
ssh-keygen -A
systemctl restart sshd
```

### 2. cloud-init Hanging

cloud-init tries to contact a metadata service
(`169.254.169.254`) that doesn't exist outside a
cloud provider. It retries for minutes, blocking
boot.

**Disable permanently:**

```
touch /etc/cloud/cloud-init.disabled
systemctl disable cloud-init.service \
  cloud-init-local.service \
  cloud-config.service \
  cloud-final.service
```

**Or mask all units:**

```
systemctl mask cloud-init.service \
  cloud-init-local.service \
  cloud-config.service \
  cloud-final.service
```

### 3. networkd-wait-online Blocking Boot

`systemd-networkd-wait-online.service` waits for
all interfaces to be fully configured. If the
network isn't set up correctly, this blocks boot
for up to 2 minutes.

```
systemctl mask \
  systemd-networkd-wait-online.service
```

### 4. Wrong or No IP Address

Cloud images expect DHCP from a cloud provider's
network. Check the current state:

```
ip addr show
networkctl status
```

Configure static IP via
`/etc/systemd/network/*.network` or
`/etc/network/interfaces` depending on the distro.

### 5. No Root Password / No SSH Access

Cloud images have no root password and expect SSH
key injection via cloud-init.

**Fix from console or rescue:**

```
passwd root
# or:
mkdir -p /root/.ssh
cat >> /root/.ssh/authorized_keys <<'EOF'
ssh-ed25519 AAAA... user@host
EOF
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
```

### 6. Nocloud Images: No SSH Server

Debian `nocloud` images do **not** include
`openssh-server`. They are designed for console
access with an empty root password. openssh-server
must be installed before the first boot.

When installing into an offline rootfs (mounted
from a different OS), package manager scripts are
skipped — see the `/os-replacement` skill
§"Manual Package Extraction".

**Minimum steps for an SSH-ready nocloud image:**

1. Extract `openssh-server` and dependencies into
   the rootfs.
2. Run `scripts/inject-ssh-keys.sh` — injects
   authorized_keys, creates the `sshd` system
   user, and creates `/run/sshd`.
3. Copy default config:
   `cp usr/share/openssh/sshd_config etc/ssh/`
4. Set `PermitRootLogin yes` in sshd_config.
5. Generate SSH host keys:
   `ssh-keygen -A` (or generate from the host OS
   — key format is compatible across OSes).
6. Enable the service:
   `ln -sf /lib/systemd/system/ssh.service \`
   `  etc/systemd/system/multi-user.target.wants/`
7. Set a root password in `/etc/shadow`.

## Post-Deployment Checklist

1. [ ] `sshd` is installed (nocloud images may
       lack it — see §6 above)
2. [ ] SSH host keys exist
       (`ls /etc/ssh/ssh_host_*`)
3. [ ] `sshd` is running
4. [ ] `sshd` system user exists (`id sshd`)
5. [ ] cloud-init is disabled or masked
6. [ ] `networkd-wait-online` is masked
7. [ ] Network is configured (static IP or DHCP)
8. [ ] Root access works (password or SSH key)
9. [ ] Hostname set (`hostnamectl set-hostname`)
10. [ ] Package manager works
        (`apt-get update` or equivalent)

## Memory Convention

When recording cloud image origin in server
memory:

```
- Origin: cloud image (Debian 13 genericcloud)
```
