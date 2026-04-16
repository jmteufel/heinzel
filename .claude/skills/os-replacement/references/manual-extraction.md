# Manual Package Extraction into Offline Rootfs

When installing packages into a rootfs that
cannot be booted yet (e.g. cross-OS replacement
via SSH, where you mount the new root from the
old OS), `dpkg`/`apt`/`pkg` cannot run because
the target architecture or OS doesn't match the
running host.

The workaround: download `.deb` (or equivalent)
packages, extract their file contents, and place
them into the target rootfs manually.

**This bypasses all package manager scripts.** The
following critical steps are skipped and must be
handled manually.

## 1. System Users and Groups

Many services require dedicated system users
(e.g. `sshd` needs the `sshd` user). These are
normally created by the package's postinst script.

**Check the package's postinst for
`adduser`/`useradd` calls** and create the
required users manually:

```
# Common service users:
useradd -r -d /run/sshd -s /usr/sbin/nologin sshd
useradd -r -d /var/lib/ntp -s /usr/sbin/nologin ntp
```

If `chroot` is not possible (different
architecture or OS), write `useradd` commands
directly into the target rootfs's `/etc/passwd`,
`/etc/shadow`, and `/etc/group`. Use the next
available UID in the system range (100–999).

## 2. Configuration Files

Package postinst scripts often generate config
files from templates or run `ucf` to manage them.
Copy the default config from the package's
`/usr/share/` directory:

```
# Example: openssh-server
cp <rootfs>/usr/share/openssh/sshd_config \
   <rootfs>/etc/ssh/sshd_config
```

## 3. Systemd Service Enablement

Extracting a `.deb` places unit files in
`/lib/systemd/system/`, but does **not** create
the symlinks in `/etc/systemd/system/*.wants/`
that enable the service. Create them manually:

```
ln -sf /lib/systemd/system/ssh.service \
  <rootfs>/etc/systemd/system/\
multi-user.target.wants/ssh.service
```

## 4. State Directories and Permissions

Some services need specific directories with
specific ownership:

```
mkdir -p <rootfs>/run/sshd
```

## Summary Checklist

Before rebooting into a rootfs with manually
extracted packages:

- [ ] All required system users/groups created
- [ ] Config files copied from defaults and
      customized
- [ ] Systemd services enabled via symlinks
- [ ] State/runtime directories created
- [ ] File ownership correct (especially for
      service users)

## Inspecting postinst Scripts

When in doubt, inspect the package's postinst
script. On Debian:

```
ar x <package>.deb
tar xf control.tar.*
cat postinst
```
